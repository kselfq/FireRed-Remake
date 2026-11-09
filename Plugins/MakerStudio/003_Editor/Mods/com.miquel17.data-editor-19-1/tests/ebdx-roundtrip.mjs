import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import {
  buildEbdxWorkspace,
  parseEbdxMetrics,
  serializeEbdxWorkspace,
  setEbdxValue,
  verifyEbdxSerialization,
} from "../src/ebdx/ebdx_data.js";
import { parseDocument } from "../src/pbs/pbs19.js";

const gameRoot = process.argv[2];
if (!gameRoot) throw new Error("Usage: node tests/ebdx-roundtrip.mjs <game-root>");

const pokemonSource = await readFile(path.join(gameRoot, "PBS", "pokemon.txt"), "utf8");
const formsSource = await readFile(path.join(gameRoot, "PBS", "pokemonforms.txt"), "utf8");
const metricsSource = await readFile(path.join(gameRoot, "PBS", "EBDX", "pokemon.txt"), "utf8");
const documents = {
  pokemon: parseDocument("pokemon", pokemonSource),
  forms: parseDocument("forms", formsSource),
};

const workspace = buildEbdxWorkspace(metricsSource, documents);
assert.equal(workspace.parsed.issues.length, 0, "the current EBDX metrics must parse without errors");
assert.equal(serializeEbdxWorkspace(workspace), metricsSource, "untouched EBDX metrics must round-trip byte-for-byte");
assert.ok(workspace.entries.length > documents.pokemon.entries.length, "the EBDX catalog must include Pokémon forms");

const bulbasaur = workspace.entries.find((entry) => entry.species === "BULBASAUR" && entry.form === 0);
assert.ok(bulbasaur, "expected BULBASAUR in the EBDX catalog");
const previousX = bulbasaur.values.BattlerEnemyX;
setEbdxValue(workspace, bulbasaur, "BattlerEnemyX", previousX + 7);
const output = serializeEbdxWorkspace(workspace);
verifyEbdxSerialization(workspace, output);
const beforeLines = metricsSource.split(/\r?\n/);
const afterLines = output.split(/\r?\n/);
const changedLines = beforeLines.flatMap((line, index) => line === afterLines[index] ? [] : [index]);
assert.equal(changedLines.length, 1, "editing one existing EBDX metric must rewrite exactly one line");
assert.match(afterLines[changedLines[0]], new RegExp(`BattlerEnemyX\\s*=\\s*${previousX + 7}`), "the changed line must contain the requested EBDX value");
assert.equal(pokemonSource, await readFile(path.join(gameRoot, "PBS", "pokemon.txt"), "utf8"), "the regular Pokémon PBS must remain untouched");
assert.equal(formsSource, await readFile(path.join(gameRoot, "PBS", "pokemonforms.txt"), "utf8"), "the regular forms PBS must remain untouched");

const fixture = [
  "# custom preface",
  "[BULBASAUR]",
  "BattleBGM               = Custom Theme",
  "BattlerEnemyX           = 2 # keep this note",
  "BATTLESCRIPT",
  "  turnStart             = Keep,This,Exactly",
  "",
].join("\r\n");
const fixtureDocuments = {
  pokemon: { entries: [{ idNumber: 1, values: { InternalName: "BULBASAUR", Name: "Bulbasaur" } }] },
  forms: { entries: [{ species: "BULBASAUR", form: 1, values: { FormName: "Test form" } }] },
};
const fixtureWorkspace = buildEbdxWorkspace(fixture, fixtureDocuments);
const base = fixtureWorkspace.entries.find((entry) => entry.form === 0);
const form = fixtureWorkspace.entries.find((entry) => entry.form === 1);
setEbdxValue(fixtureWorkspace, base, "BattlerEnemyY", 11);
setEbdxValue(fixtureWorkspace, form, "BattlerPlayerY", 9);
const fixtureOutput = serializeEbdxWorkspace(fixtureWorkspace);
verifyEbdxSerialization(fixtureWorkspace, fixtureOutput);
assert.ok(fixtureOutput.includes("BattleBGM               = Custom Theme"), "unrelated root EBDX values must be preserved literally");
assert.ok(fixtureOutput.includes("BattlerEnemyX           = 2 # keep this note"), "unedited metrics and inline comments must be preserved literally");
assert.ok(fixtureOutput.includes("  turnStart             = Keep,This,Exactly"), "EBDX subsections must be preserved literally");
assert.ok(fixtureOutput.includes("[BULBASAUR,1]"), "a missing form must be appended using the EBDX form header format");
assert.equal(parseEbdxMetrics(fixtureOutput).byIdentity.get("BULBASAUR,1").values.BattlerPlayerY, 9, "new form metrics must survive read-back");

console.log(JSON.stringify({
  ebdxEntries: workspace.entries.length,
  sourceRecords: workspace.parsed.records.length,
  exactChangedLines: changedLines.length,
  preservation: "ok",
  regularPbsUntouched: true,
}, null, 2));
