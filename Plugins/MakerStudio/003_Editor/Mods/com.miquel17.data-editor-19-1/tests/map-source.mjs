import assert from "node:assert/strict";
import { createMapVisuals } from "../src/world/map_visuals.js";

const fixture = [...Buffer.from("BAhvOg1SUEc6Ok1hcAk6EEB0aWxlc2V0X2lkaQw6C0B3aWR0aGkHOgxAaGVpZ2h0aQc6CkBkYXRhdToKVGFibGUxAwAAAAIAAAACAAAAAwAAAAwAAACAAYEBggGDAQAAAAAAAAAAAQACAAMABAA=", "base64")];
let requestedPath = "";
globalThis.window = {
  __TAURI__: {
    core: {
      invoke: async (command, args) => {
        assert.equal(command, "read_binary_file");
        requestedPath = args.path;
        return fixture;
      },
    },
  },
};

const ctx = {
  editor: { gameRoot: () => "C:/project" },
  projectData: { maps: () => [{ id: 3, name: "JP's house" }] },
  map: { info: () => { throw new Error("Map is not loaded"); }, readTile: () => { throw new Error("Map is not loaded"); } },
  tileset: { mapTilesetId: () => { throw new Error("Map is not loaded"); } },
};
const mapVisuals = createMapVisuals(ctx, {});
await mapVisuals.prepare([3]);
const info = mapVisuals.info(3);

assert.equal(requestedPath, "C:/project/Data/Map003.rxdata");
assert.deepEqual(info, { id: 3, name: "JP's house", width: 2, height: 2, tilesetId: 7 });

console.log("Unloaded project-map source fallback passed.");
