import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import { createProjectAssets } from "../src/infrastructure/project_assets.js";

const root = path.resolve(process.argv[2] || "C:/Users/mibas/Desktop/aaa");
globalThis.window = { __TAURI__: { core: { invoke: async () => { throw new Error("Use the public filesystem fallback"); } } } };
const ctx = {
  editor: { gameRoot: () => root },
  fs: {
    listProjectDir: async (relative) => {
      const entries = await fs.readdir(path.join(root, relative), { withFileTypes: true });
      return entries.map((entry) => ({ name: entry.name, isFile: entry.isFile(), isDirectory: entry.isDirectory() }));
    },
  },
  log: { warn: () => {} },
};
const assets = createProjectAssets(ctx);
const result = await assets.initialize();
assert.ok(result.audio.bgm.length > 10, "BGM must be populated through ctx.fs.listProjectDir");
assert.ok(result.audio.me.length > 5, "ME must be populated through ctx.fs.listProjectDir");
assert.ok(result.graphics.battlebacks.includes("cave1"), "battleback groups must be derived from *_bg files");
assert.ok(result.graphics.pictures.length > 0, "town map pictures must be listed");
assert.ok(result.graphics.characters.length > 0, "character graphics must be listed");
assets.dispose();
console.log(JSON.stringify({
  bgm: result.audio.bgm.length,
  me: result.audio.me.length,
  battlebacks: result.graphics.battlebacks.length,
  pictures: result.graphics.pictures.length,
  characters: result.graphics.characters.length,
}, null, 2));
