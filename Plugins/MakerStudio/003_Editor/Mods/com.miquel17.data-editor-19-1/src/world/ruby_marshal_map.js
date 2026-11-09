function toBytes(input) {
  if (input instanceof Uint8Array) return input;
  if (ArrayBuffer.isView(input)) return new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
  if (input instanceof ArrayBuffer) return new Uint8Array(input);
  if (Array.isArray(input)) return Uint8Array.from(input);
  throw new Error("The map file did not contain binary data.");
}

class MarshalReader {
  constructor(input) {
    this.bytes = toBytes(input);
    this.offset = 0;
    this.symbols = [];
    this.decoder = new TextDecoder("utf-8");
  }

  byte() {
    if (this.offset >= this.bytes.length) throw new Error("Unexpected end of Ruby Marshal data.");
    return this.bytes[this.offset++];
  }

  signedByte() {
    const value = this.byte();
    return value > 127 ? value - 256 : value;
  }

  integer() {
    const size = this.signedByte();
    if (size === 0) return 0;
    if (size >= 5) return size - 5;
    if (size <= -5) return size + 5;
    const length = Math.abs(size);
    let value = size < 0 ? -1 : 0;
    for (let index = 0; index < length; index += 1) {
      const shift = index * 8;
      value = size < 0
        ? (value & ~(0xff << shift)) | (this.byte() << shift)
        : value | (this.byte() << shift);
    }
    return value;
  }

  rawString() {
    const length = this.integer();
    if (length < 0 || this.offset + length > this.bytes.length) throw new Error("Invalid Ruby Marshal string length.");
    const value = this.bytes.slice(this.offset, this.offset + length);
    this.offset += length;
    return value;
  }

  text(raw) {
    return this.decoder.decode(raw);
  }

  symbol(tag = this.byte()) {
    if (tag === 0x3a) {
      const value = this.text(this.rawString());
      this.symbols.push(value);
      return value;
    }
    if (tag === 0x3b) {
      const value = this.symbols[this.integer()];
      if (value == null) throw new Error("Invalid Ruby Marshal symbol link.");
      return value;
    }
    if (tag === 0x49) {
      const value = this.symbol();
      const count = this.integer();
      for (let index = 0; index < count; index += 1) {
        this.symbol();
        this.value();
      }
      return value;
    }
    throw new Error(`Expected a Ruby symbol at byte ${this.offset - 1}.`);
  }

  pairs(count, target = {}) {
    for (let index = 0; index < count; index += 1) {
      const key = this.symbol();
      target[key] = this.value();
    }
    return target;
  }

  value(tag = this.byte()) {
    switch (tag) {
      case 0x30: return null;
      case 0x54: return true;
      case 0x46: return false;
      case 0x69: return this.integer();
      case 0x3a:
      case 0x3b: return this.symbol(tag);
      case 0x22: return this.rawString();
      case 0x5b: {
        const length = this.integer();
        const result = [];
        for (let index = 0; index < length; index += 1) result.push(this.value());
        return result;
      }
      case 0x7b: {
        const length = this.integer();
        const result = [];
        for (let index = 0; index < length; index += 1) result.push([this.value(), this.value()]);
        return result;
      }
      case 0x7d: {
        const length = this.integer();
        for (let index = 0; index < length; index += 1) { this.value(); this.value(); }
        this.value();
        return null;
      }
      case 0x6f: {
        const className = this.symbol();
        const values = this.pairs(this.integer());
        return { __class: className, ...values };
      }
      case 0x53: {
        const className = this.symbol();
        const count = this.integer();
        const values = {};
        for (let index = 0; index < count; index += 1) values[this.symbol()] = this.value();
        return { __class: className, ...values };
      }
      case 0x75: return { __class: this.symbol(), __raw: this.rawString() };
      case 0x55: return { __class: this.symbol(), __value: this.value() };
      case 0x49: {
        const value = this.value();
        const count = this.integer();
        for (let index = 0; index < count; index += 1) { this.symbol(); this.value(); }
        return value;
      }
      case 0x65:
      case 0x43: this.symbol(); return this.value();
      case 0x40: this.integer(); return null;
      case 0x66: return this.text(this.rawString());
      case 0x2f: {
        const pattern = this.rawString();
        this.byte();
        return pattern;
      }
      case 0x63:
      case 0x6d:
      case 0x4d: return this.text(this.rawString());
      case 0x6c: {
        const sign = this.byte();
        const words = this.integer();
        let value = 0n;
        for (let index = 0; index < words; index += 1) value |= BigInt(this.byte() | (this.byte() << 8)) << BigInt(index * 16);
        return sign === 0x2d ? -value : value;
      }
      case 0x64: this.symbol(); return this.value();
      default: throw new Error(`Unsupported Ruby Marshal tag 0x${tag.toString(16)} at byte ${this.offset - 1}.`);
    }
  }
}

function readTable(raw) {
  const bytes = toBytes(raw);
  if (bytes.byteLength < 20) throw new Error("The map tile table is incomplete.");
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const dimensions = view.getInt32(0, true);
  const width = view.getInt32(4, true);
  const height = view.getInt32(8, true);
  const depth = view.getInt32(12, true);
  const count = view.getInt32(16, true);
  if (dimensions !== 3 || width <= 0 || height <= 0 || depth <= 0 || count !== width * height * depth || bytes.byteLength < 20 + count * 2) {
    throw new Error("The map tile table has invalid dimensions.");
  }
  const tiles = new Uint16Array(count);
  for (let index = 0; index < count; index += 1) tiles[index] = view.getUint16(20 + index * 2, true);
  return { width, height, depth, tiles };
}

export function decodeRxdataMap(input) {
  const reader = new MarshalReader(input);
  if (reader.byte() !== 4 || reader.byte() !== 8) throw new Error("Unsupported Ruby Marshal version.");
  const map = reader.value();
  if (map?.__class !== "RPG::Map") throw new Error("The file is not an RPG Maker XP map.");
  const table = readTable(map["@data"]?.__raw);
  const width = Number(map["@width"] || table.width);
  const height = Number(map["@height"] || table.height);
  if (width !== table.width || height !== table.height) throw new Error("The map dimensions do not match its tile table.");
  return {
    width,
    height,
    depth: table.depth,
    tilesetId: Number(map["@tileset_id"] || 0),
    readTile(layer, x, y) {
      const px = Number(x), py = Number(y), pz = Number(layer);
      if (px < 0 || py < 0 || pz < 0 || px >= width || py >= height || pz >= table.depth) return 0;
      return table.tiles[px + width * (py + height * pz)] || 0;
    },
  };
}
