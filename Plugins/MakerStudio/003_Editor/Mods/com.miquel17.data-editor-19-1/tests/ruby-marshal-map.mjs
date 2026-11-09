import assert from "node:assert/strict";
import { decodeRxdataMap } from "../src/world/ruby_marshal_map.js";

const fixture = Buffer.from("BAhvOg1SUEc6Ok1hcAk6EEB0aWxlc2V0X2lkaQw6C0B3aWR0aGkHOgxAaGVpZ2h0aQc6CkBkYXRhdToKVGFibGUxAwAAAAIAAAACAAAAAwAAAAwAAACAAYEBggGDAQAAAAAAAAAAAQACAAMABAA=", "base64");
const map = decodeRxdataMap(fixture);

assert.equal(map.width, 2);
assert.equal(map.height, 2);
assert.equal(map.depth, 3);
assert.equal(map.tilesetId, 7);
assert.equal(map.readTile(0, 0, 0), 384);
assert.equal(map.readTile(0, 1, 1), 387);
assert.equal(map.readTile(2, 1, 1), 4);
assert.equal(map.readTile(3, 0, 0), 0);

console.log("Ruby Marshal map decoding passed.");
