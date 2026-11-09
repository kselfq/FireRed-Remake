import { decodeRxdataMap } from "./ruby_marshal_map.js";

const AUTOTILE_QUARTERS = Object.freeze([
  [27,28,33,34],[5,28,33,34],[27,6,33,34],[5,6,33,34],
  [27,28,33,12],[5,28,33,12],[27,6,33,12],[5,6,33,12],
  [27,28,11,34],[5,28,11,34],[27,6,11,34],[5,6,11,34],
  [27,28,11,12],[5,28,11,12],[27,6,11,12],[5,6,11,12],
  [25,26,31,32],[25,6,31,32],[25,26,31,12],[25,6,31,12],
  [15,16,21,22],[15,16,21,12],[15,16,11,22],[15,16,11,12],
  [29,30,35,36],[29,30,11,36],[5,30,35,36],[5,30,11,36],
  [39,40,45,46],[5,40,45,46],[39,6,45,46],[5,6,45,46],
  [25,30,31,36],[15,16,45,46],[13,14,19,20],[13,14,19,12],
  [17,18,23,24],[17,18,11,24],[41,42,47,48],[5,42,47,48],
  [37,38,43,44],[37,6,43,44],[13,18,19,24],[13,14,43,44],
  [37,42,43,48],[17,18,47,48],[13,18,43,48],[1,2,7,8],
]);

function imageFromUrl(url) {
  if (!url) return Promise.resolve(null);
  return new Promise((resolve) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = () => resolve(null);
    image.src = url;
  });
}

function number(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeMapInfo(ctx, mapId) {
  const id = Number(mapId);
  let raw = {};
  let maps = [];
  let fallbackTilesetId = 0;
  try { raw = ctx.map?.info?.(id) || {}; } catch { /* Unloaded maps are resolved from MapXXX.rxdata. */ }
  try { maps = ctx.projectData?.maps?.() || []; } catch { /* The map name is cosmetic. */ }
  try { fallbackTilesetId = ctx.tileset?.mapTilesetId?.(id); } catch { /* Unloaded maps have no host tileset binding. */ }
  const width = number(raw.width ?? raw.xsize ?? raw.mapWidth);
  const height = number(raw.height ?? raw.ysize ?? raw.mapHeight);
  const tilesetId = number(raw.tilesetId ?? raw.tileset_id ?? fallbackTilesetId);
  return {
    id,
    name: raw.name || maps.find((map) => Number(map.id) === id)?.name || ("Map " + String(id).padStart(3, "0")),
    width,
    height,
    tilesetId,
  };
}

function drawAutotile(context, image, tileId, dx, dy, tileSize) {
  if (!image) return;
  if (image.height <= 32) {
    context.drawImage(image, 0, 0, Math.min(32, image.width), Math.min(32, image.height), dx, dy, tileSize, tileSize);
    return;
  }
  const pattern = AUTOTILE_QUARTERS[tileId % 48] || AUTOTILE_QUARTERS[0];
  const half = tileSize / 2;
  pattern.forEach((quarter, index) => {
    const source = quarter - 1;
    const sx = (source % 6) * 16;
    const sy = Math.floor(source / 6) * 16;
    context.drawImage(image, sx, sy, 16, 16, dx + (index % 2) * half, dy + Math.floor(index / 2) * half, half, half);
  });
}

function drawTile(context, tileId, x, y, tileSize, tileset, autotiles) {
  if (!tileId) return;
  const dx = x * tileSize;
  const dy = y * tileSize;
  if (tileId < 384) {
    const autotileIndex = Math.floor(tileId / 48) - 1;
    if (autotileIndex >= 0) drawAutotile(context, autotiles[autotileIndex], tileId, dx, dy, tileSize);
    return;
  }
  if (!tileset) return;
  const source = tileId - 384;
  const sx = (source % 8) * 32;
  const sy = Math.floor(source / 8) * 32;
  if (sy < tileset.height) context.drawImage(tileset, sx, sy, 32, 32, dx, dy, tileSize, tileSize);
}

export function relativeMapPlacement(connection, infoA, infoB) {
  const aX = connection.directionA;
  const aY = number(connection.offsetA);
  const bX = connection.directionB;
  const bY = number(connection.offsetB);
  if (typeof aX === "number" || /^-?\d+$/.test(String(aX))) {
    return { x: number(aX) - number(bX), y: aY - bY };
  }
  const direction = String(aX).toUpperCase();
  if (direction === "N") return { x: aY - bY, y: -infoB.height };
  if (direction === "S") return { x: aY - bY, y: infoA.height };
  if (direction === "W") return { x: -infoB.width, y: aY - bY };
  return { x: infoA.width, y: aY - bY };
}

function componentBounds(nodes, positions, infos) {
  const xs = nodes.map((id) => positions.get(id).x);
  const ys = nodes.map((id) => positions.get(id).y);
  const rights = nodes.map((id) => positions.get(id).x + infos.get(id).width);
  const bottoms = nodes.map((id) => positions.get(id).y + infos.get(id).height);
  const minX = Math.min(...xs), minY = Math.min(...ys);
  return { minX, minY, maxX: Math.max(...rights), maxY: Math.max(...bottoms), width: Math.max(...rights) - minX, height: Math.max(...bottoms) - minY };
}

export function layoutConnectionWorld(connections, mapInfo) {
  const infos = new Map();
  const adjacency = new Map();
  const addEdge = (from, to, connection, reverse) => {
    if (!adjacency.has(from)) adjacency.set(from, []);
    adjacency.get(from).push({ to, connection, reverse });
  };
  for (const connection of connections) {
    const a = Number(connection.mapA), b = Number(connection.mapB);
    infos.set(a, mapInfo(a)); infos.set(b, mapInfo(b));
    addEdge(a, b, connection, false);
    addEdge(b, a, connection, true);
  }
  const positions = new Map();
  const components = [];
  for (const start of adjacency.keys()) {
    if (positions.has(start)) continue;
    positions.set(start, { x: 0, y: 0 });
    const nodes = [], queue = [start];
    while (queue.length) {
      const current = queue.shift();
      nodes.push(current);
      for (const edge of adjacency.get(current) || []) {
        if (positions.has(edge.to)) continue;
        const currentInfo = infos.get(current), targetInfo = infos.get(edge.to);
        let delta;
        if (!edge.reverse) delta = relativeMapPlacement(edge.connection, currentInfo, targetInfo);
        else {
          const forward = relativeMapPlacement(edge.connection, targetInfo, currentInfo);
          delta = { x: -forward.x, y: -forward.y };
        }
        const origin = positions.get(current);
        positions.set(edge.to, { x: origin.x + delta.x, y: origin.y + delta.y });
        queue.push(edge.to);
      }
    }
    components.push({ nodes, bounds: componentBounds(nodes, positions, infos) });
  }
  components.sort((a, b) => (b.bounds.width * b.bounds.height) - (a.bounds.width * a.bounds.height));
  const totalArea = components.reduce((sum, item) => sum + (item.bounds.width + 12) * (item.bounds.height + 12), 0);
  const targetWidth = Math.max(80, Math.ceil(Math.sqrt(totalArea * 1.5)));
  let cursorX = 0, cursorY = 0, rowHeight = 0;
  for (const component of components) {
    const packedWidth = component.bounds.width + 12;
    if (cursorX && cursorX + packedWidth > targetWidth) {
      cursorX = 0;
      cursorY += rowHeight;
      rowHeight = 0;
    }
    const shiftX = cursorX - component.bounds.minX + 6;
    const shiftY = cursorY - component.bounds.minY + 6;
    component.nodes.forEach((id) => {
      const point = positions.get(id);
      positions.set(id, { x: point.x + shiftX, y: point.y + shiftY });
    });
    cursorX += packedWidth;
    rowHeight = Math.max(rowHeight, component.bounds.height + 12);
  }
  const allNodes = [...positions.keys()];
  const bounds = allNodes.length ? componentBounds(allNodes, positions, infos) : { minX: 0, minY: 0, maxX: 1, maxY: 1, width: 1, height: 1 };
  return { positions, infos, components, width: bounds.maxX + 6, height: bounds.maxY + 6 };
}

export function createMapVisuals(ctx, assets) {
  const renderCache = new Map();
  const sourceCache = new Map();
  const infoCache = new Map();

  function info(mapId) {
    return infoCache.get(Number(mapId)) || normalizeMapInfo(ctx, mapId);
  }

  async function loadMapSource(mapId) {
    const id = Number(mapId);
    if (sourceCache.has(id)) return sourceCache.get(id);
    const pending = (async () => {
      const liveInfo = normalizeMapInfo(ctx, id);
      if (liveInfo.width && liveInfo.height && liveInfo.tilesetId && typeof ctx.map?.readTile === "function") {
        try {
          const probe = ctx.map.readTile(id, 0, 0, 0);
          if (Number.isFinite(Number(probe))) {
            const source = { ...liveInfo, depth: 3, readTile: (layer, x, y) => ctx.map.readTile(id, layer, x, y) };
            infoCache.set(id, liveInfo);
            return source;
          }
        } catch { /* Unloaded maps are read directly from their project file below. */ }
      }

      const root = ctx.editor?.gameRoot?.()?.replace(/[\\/]$/, "");
      const invoke = window.__TAURI__?.core?.invoke;
      if (!root || !invoke) throw new Error("Maker Studio did not provide access to the active project map files.");
      const filename = "Map" + String(id).padStart(3, "0") + ".rxdata";
      let bytes;
      try {
        bytes = await invoke("read_binary_file", { path: root + "/Data/" + filename });
      } catch (error) {
        throw new Error(`Could not read Data/${filename}: ${error?.message || error}`);
      }
      let decoded;
      try {
        decoded = decodeRxdataMap(bytes);
      } catch (error) {
        throw new Error(`Could not decode Data/${filename}: ${error?.message || error}`);
      }
      const loadedInfo = { id, name: liveInfo.name, width: decoded.width, height: decoded.height, tilesetId: decoded.tilesetId };
      infoCache.set(id, loadedInfo);
      return { ...loadedInfo, depth: decoded.depth, readTile: decoded.readTile };
    })();
    sourceCache.set(id, pending);
    try {
      return await pending;
    } catch (error) {
      sourceCache.delete(id);
      throw error;
    }
  }

  async function prepare(mapIds) {
    await Promise.all([...new Set((mapIds || []).map(Number).filter(Number.isFinite))].map(loadMapSource));
  }

  async function render(mapId, tileSize = 8) {
    const size = Math.max(1, number(tileSize, 8));
    const key = Number(mapId) + ":" + size;
    if (renderCache.has(key)) return renderCache.get(key);
    const pending = (async () => {
      const mapInfo = await loadMapSource(mapId);
      if (!mapInfo.width || !mapInfo.height || !mapInfo.tilesetId) {
        throw new Error("Map " + mapId + " is not available in the active Maker Studio project.");
      }
      let tilesetInfo = {};
      try { tilesetInfo = ctx.tileset?.info?.(mapInfo.tilesetId) || {}; } catch { /* A tile-less preview is still more useful than aborting. */ }
      let tilesetUrl = null;
      try { tilesetUrl = await ctx.tileset?.getImageBlobUrl?.(mapInfo.tilesetId); } catch { /* Project image fallback below. */ }
      const tilesetName = tilesetInfo.tilesetName || tilesetInfo.tileset_name || "";
      if (!tilesetUrl && tilesetName) tilesetUrl = await assets.loadPersistent(["Graphics/Tilesets/" + tilesetName + ".png", "Graphics/Tilesets/" + tilesetName]);
      const autotileNames = tilesetInfo.autotileNames || tilesetInfo.autotile_names || [];
      const [tileset, ...autotiles] = await Promise.all([
        imageFromUrl(tilesetUrl),
        ...Array.from({ length: 7 }, (_, index) => {
          const name = autotileNames[index];
          return name ? assets.loadPersistent(["Graphics/Autotiles/" + name + ".png", "Graphics/Autotiles/" + name]).then(imageFromUrl) : null;
        }),
      ]);
      const canvas = document.createElement("canvas");
      canvas.width = mapInfo.width * size;
      canvas.height = mapInfo.height * size;
      canvas.className = "pepbs-map-raster";
      const context = canvas.getContext("2d", { alpha: true });
      context.imageSmoothingEnabled = false;
      for (let layer = 0; layer < Math.min(3, mapInfo.depth || 3); layer += 1) {
        for (let y = 0; y < mapInfo.height; y += 1) {
          for (let x = 0; x < mapInfo.width; x += 1) {
            const tileId = number(mapInfo.readTile(layer, x, y));
            drawTile(context, tileId, x, y, size, tileset, autotiles);
          }
        }
      }
      return { canvas, ...mapInfo, tileSize: size };
    })();
    renderCache.set(key, pending);
    try {
      return await pending;
    } catch (error) {
      renderCache.delete(key);
      ctx.log?.error?.(`Data Editor map ${mapId} preview failed: ${error?.stack || error?.message || error}`);
      throw error;
    }
  }

  return {
    info,
    prepare,
    render,
    clear: () => { renderCache.clear(); sourceCache.clear(); infoCache.clear(); },
  };
}
