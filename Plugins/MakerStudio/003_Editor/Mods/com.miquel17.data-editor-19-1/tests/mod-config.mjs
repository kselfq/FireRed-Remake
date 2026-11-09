import assert from "node:assert/strict";
import fs from "node:fs";
import { MOD_ID, MOD_PROJECT_ROOT } from "../src/core/mod_config.js";

const manifest = JSON.parse(fs.readFileSync(new URL("../manifest.json", import.meta.url), "utf8"));
assert.equal(MOD_ID, manifest.id, "the centralized mod path must use the manifest ID");
assert.ok(MOD_PROJECT_ROOT.endsWith(`/${manifest.id}`));

console.log("Centralized mod path configuration passed.");
