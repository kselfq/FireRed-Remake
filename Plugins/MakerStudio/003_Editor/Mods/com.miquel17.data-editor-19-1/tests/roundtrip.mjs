import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import {
  createEncounterPokemonReferences,
  parseDocument,
  parsePairs,
  parseTypes,
  serializeDocument,
  validateWorkspace,
  verifySerialization,
} from "../src/pbs/pbs19.js";
import { ENUMS, MOVE_FLAGS, POKEMON_ORDER, SCHEMAS, STAT_NAMES } from "../src/pbs/schema.js";
import { hasEnglishTranslation, setLanguage, t } from "../src/ui/i18n.js";
import { NATURES } from "../src/pbs/trainer_team.js";
import {
  createAbility, createForm, createItem, createMove, createPokemon,
  createTrainer, createTrainerType, createTrainerVersion, reassignFormSpecies, removeDocumentEntry, renameTrainerGroup, renameTrainerType,
} from "../src/core/document_ops.js";

const gameRoot = process.argv[2];
if (!gameRoot) throw new Error("Usage: node tests/roundtrip.mjs <game-root>");

assert.deepEqual(parsePairs("1,,3,VINEWHIP"), [["1", ""], ["3", "VINEWHIP"]], "level-up move parsing must preserve an incomplete row without shifting later pairs");

const paths = {
  pokemon: "pokemon.txt",
  forms: "pokemonforms.txt",
  moves: "moves.txt",
  items: "items.txt",
  abilities: "abilities.txt",
  trainerTypes: "trainertypes.txt",
  trainers: "trainers.txt",
};

const documents = {};
const sources = {};
for (const [kind, filename] of Object.entries(paths)) {
  const source = await readFile(path.join(gameRoot, "PBS", filename), "utf8");
  sources[kind] = source;
  const document = parseDocument(kind, source);
  assert.equal(document.parseErrors.length, 0, `${filename} must parse without errors`);
  assert.equal(serializeDocument(document), source, `${filename} must round-trip byte-for-byte when untouched`);
  documents[kind] = document;
}

assert.ok(documents.pokemon.entries.length > 1000, "expected a full species PBS");
assert.ok(documents.forms.entries.length > 100, "expected Pokémon forms");
assert.ok(documents.moves.entries.length > 800, "expected moves");
assert.ok(documents.items.entries.length > 700, "expected items");
assert.ok(documents.abilities.entries.length > 300, "expected abilities");
assert.ok(documents.trainerTypes.entries.length > 20, "expected trainer types");
assert.ok(documents.trainers.entries.length >= 20, "expected trainers");

const encounterPokemon = createEncounterPokemonReferences(documents, (form) => `Forma ${form}`);
const namedForm = documents.forms.entries.find((entry) => String(entry.values.FormName || "").trim());
const namedFormBase = documents.pokemon.entries.find((entry) => entry.values.InternalName === namedForm.species);
const namedFormRecord = encounterPokemon.find((record) => record.id === `${namedForm.species}_${namedForm.form}`);
assert.equal(namedFormRecord.name, `${namedFormBase.values.Name} (${namedForm.values.FormName.trim()})`, "encounter form labels must include the base Pokémon and the form name");
assert.equal(namedFormRecord.species, namedForm.species, "encounter form references must retain their base species");
assert.equal(namedFormRecord.form, namedForm.form, "encounter form references must retain their numeric form");

const typesSource = await readFile(path.join(gameRoot, "PBS", "types.txt"), "utf8");
const types = parseTypes(typesSource);
const baseline = validateWorkspace(documents, types);

{
  const trainer = documents.trainers.entries.find((entry) => entry.pokemon.length);
  const originalLevel = trainer.pokemon[0].Level;
  trainer.pokemon[0].Level = "101";
  const invalid = validateWorkspace(documents, types);
  assert.ok(invalid.errors.some((entry) => entry.kind === "trainers" && entry.message.includes("100")), "trainer parties must reject levels above the Essentials 19.1 maximum");
  trainer.pokemon[0].Level = originalLevel;
}

const edits = [
  ["pokemon", "Happiness", "71"],
  ["forms", "Weight", "155.6"],
  ["moves", "Description", 'Texto de prueba, con "comillas" y coma.'],
  ["items", "Description", 'Objeto de prueba, con "comillas" y coma.'],
  ["abilities", "Description", 'Habilidad de prueba, con "comillas" y coma.'],
  ["trainerTypes", "Name", "Tipo de prueba"],
  ["trainers", "LoseText", 'Texto de derrota, con "comillas" y coma.'],
];

for (const [kind, field, value] of edits) {
  const document = documents[kind];
  const entry = document.entries[0];
  const oldValue = entry.values[field];
  entry.values[field] = value;
  entry.dirty = true;
  document.dirty = true;
  const serialized = serializeDocument(document);
  assert.notEqual(serialized, document.originalText, `${kind} edit must alter its output`);
  const reparsed = verifySerialization(document, serialized);
  assert.equal(reparsed.entries.length, document.entries.length, `${kind} entry count must be stable`);
  assert.equal(reparsed.entries[0].values[field], value, `${kind}.${field} must survive write/read`);
  assert.equal((serialized.match(/^\s*#/gm) || []).length, (document.originalText.match(/^\s*#/gm) || []).length, `${kind} comments must be preserved`);
  if (["moves", "items", "abilities", "trainerTypes"].includes(kind)) {
    const before = document.originalText.split(/\r?\n/);
    const after = serialized.split(/\r?\n/);
    assert.equal(before.filter((line, index) => line !== after[index]).length, 1, `${kind} must rewrite only the edited row`);
  }
  entry.values[field] = oldValue;
  entry.dirty = false;
  document.dirty = false;
}

const trainerDocument = parseDocument("trainers", sources.trainers);
const trainer = trainerDocument.entries.find((entry) => entry.pokemon.length >= 2);
assert.ok(trainer, "expected a trainer with a configurable team");
trainer.pokemon[0].Item = "POTION";
trainer.pokemon[0].Moves = "TACKLE,GROWL";
trainer.pokemon[0].IV = "12,13,14,15,16,17";
trainer.pokemon[0].EV = "1,2,3,4,5,6";
trainer.pokemon.push({ Species: "PIKACHU", Level: "25", Gender: "female", Shiny: "yes", AbilityIndex: "0", Nature: "JOLLY", Ball: "POKEBALL" });
trainer.dirty = true; trainerDocument.dirty = true;
const writtenTrainers = serializeDocument(trainerDocument);
const reparsedTrainers = verifySerialization(trainerDocument, writtenTrainers);
const reparsedTrainer = reparsedTrainers.entries.find((entry) => entry.key === trainer.key);
assert.equal(reparsedTrainer.pokemon.length, trainer.pokemon.length, "trainer team size must survive write/read");
assert.equal(reparsedTrainer.pokemon[0].Moves, "TACKLE,GROWL", "trainer moves must survive write/read");
assert.equal(reparsedTrainer.pokemon.at(-1).Shiny, "yes", "trainer flags must survive write/read");
assert.equal((writtenTrainers.match(/^\s*#/gm) || []).length, (trainerDocument.originalText.match(/^\s*#/gm) || []).length, "trainer comments must be preserved");

const creationDocuments = Object.fromEntries(Object.entries(sources).map(([kind, source]) => [kind, parseDocument(kind, source)]));
const newAbility = createAbility(creationDocuments);
newAbility.values.InternalName = "CODEX_POWER";
assert.ok(verifySerialization(creationDocuments.abilities, serializeDocument(creationDocuments.abilities)).entries.some((entry) => entry.values.InternalName === "CODEX_POWER"), "new abilities must survive write/read");
const newMove = createMove(creationDocuments);
newMove.values.InternalName = "CODEX_PULSE";
assert.ok(verifySerialization(creationDocuments.moves, serializeDocument(creationDocuments.moves)).entries.some((entry) => entry.values.InternalName === "CODEX_PULSE"), "new moves must survive write/read");
const newItem = createItem(creationDocuments);
newItem.values.InternalName = "CODEX_NOTE";
assert.ok(verifySerialization(creationDocuments.items, serializeDocument(creationDocuments.items)).entries.some((entry) => entry.values.InternalName === "CODEX_NOTE"), "new items must survive write/read");
const newPokemon = createPokemon(creationDocuments);
newPokemon.values.InternalName = "CODEXMON";
const pokemonCreationRoundtrip = verifySerialization(creationDocuments.pokemon, serializeDocument(creationDocuments.pokemon));
assert.ok(pokemonCreationRoundtrip.entries.some((entry) => entry.values.InternalName === "CODEXMON"), "new Pokémon must survive canonical section write/read");
const newForm = createForm(creationDocuments, "CODEXMON");
const formCreationRoundtrip = verifySerialization(creationDocuments.forms, serializeDocument(creationDocuments.forms));
assert.ok(formCreationRoundtrip.entries.some((entry) => entry.key === newForm.key), "new forms must survive canonical section write/read");
const reassignedFormDocument = parseDocument("forms", sources.forms);
const reassignedForm = reassignedFormDocument.entries[0];
const reassignmentTarget = reassignedFormDocument.entries.find((entry) => entry !== reassignedForm && entry.species !== reassignedForm.species && entry.form === reassignedForm.form);
assert.ok(reassignmentTarget, "expected two species sharing a form number for reassignment coverage");
const previousFormKey = reassignedForm.key;
assert.equal(reassignFormSpecies(reassignedFormDocument, reassignedForm, reassignmentTarget.species), true, "forms must accept a new base species");
assert.notEqual(reassignedForm.key, previousFormKey, "changing the base species must update the form identity");
assert.equal(reassignedForm.values.Species, reassignmentTarget.species, "the synthetic species value must follow the section header");
assert.ok(!reassignedFormDocument.entries.some((entry) => entry !== reassignedForm && entry.key === reassignedForm.key), "a reassigned form must receive an available form number");
reassignedForm.dirty = true;
const reassignedFormText = serializeDocument(reassignedFormDocument);
const reassignedFormRoundtrip = verifySerialization(reassignedFormDocument, reassignedFormText);
assert.ok(reassignedFormRoundtrip.entries.some((entry) => entry.key === reassignedForm.key), "the reassigned [species,form] header must survive write/read");
const newType = createTrainerType(creationDocuments.trainerTypes);
newType.values.InternalName = "CODEX_REVIEWER";
newType.values.Name = "Code Reviewer";
verifySerialization(creationDocuments.trainerTypes, serializeDocument(creationDocuments.trainerTypes));
const newTrainer = createTrainer(creationDocuments, newType.values.InternalName);
newTrainer.values.Name = "Ada";
newTrainer.key = `${newType.values.InternalName},Ada,0`;
const rematch = createTrainerVersion(creationDocuments.trainers, newTrainer);
assert.equal(rematch.values.Version, "1", "a rematch must receive the next PBS version");
renameTrainerGroup(creationDocuments.trainers, newTrainer, "Name", "Ada Lovelace");
assert.equal(newTrainer.values.Name, "Ada Lovelace", "renaming a trainer must update the first battle");
assert.equal(rematch.values.Name, "Ada Lovelace", "renaming a trainer must update every rematch");
const createdTrainerText = serializeDocument(creationDocuments.trainers);
const createdTrainerRoundtrip = verifySerialization(creationDocuments.trainers, createdTrainerText);
assert.ok(createdTrainerRoundtrip.entries.some((entry) => entry.values.Name === "Ada Lovelace" && entry.values.Version === "1"), "new rematches must survive write/read");
renameTrainerType(creationDocuments, newType, "CODEX_ARCHITECT");
assert.equal(newTrainer.values.TrainerType, "CODEX_ARCHITECT", "renaming a trainer type must update trainer references");
const createdTypeRoundtrip = verifySerialization(creationDocuments.trainerTypes, serializeDocument(creationDocuments.trainerTypes));
assert.ok(createdTypeRoundtrip.entries.some((entry) => entry.values.InternalName === "CODEX_ARCHITECT"), "new trainer types must survive rename and write/read");
const renamedTrainerRoundtrip = verifySerialization(creationDocuments.trainers, serializeDocument(creationDocuments.trainers));
assert.ok(renamedTrainerRoundtrip.entries.some((entry) => entry.values.TrainerType === "CODEX_ARCHITECT" && entry.values.Name === "Ada Lovelace"), "renamed trainer identities must survive write/read");
assert.equal(validateWorkspace(creationDocuments, types).errors.length, 0, "new records must start with a valid Essentials 19.1 schema");

for (const kind of Object.keys(paths)) {
  const deletionDocument = parseDocument(kind, sources[kind]);
  const removed = deletionDocument.entries[Math.min(1, deletionDocument.entries.length - 1)];
  const originalCount = deletionDocument.entries.length;
  assert.equal(removeDocumentEntry(deletionDocument, removed), true, `${kind} must accept deletion`);
  const deletedText = serializeDocument(deletionDocument);
  const deletedRoundtrip = verifySerialization(deletionDocument, deletedText);
  assert.equal(deletedRoundtrip.entries.length, originalCount - 1, `${kind} deletion must remove exactly one record`);
  assert.equal((deletedText.match(/^\s*#/gm) || []).length, (sources[kind].match(/^\s*#/gm) || []).length, `${kind} deletion must preserve comments`);
}

const pokemonOrderDoc = parseDocument("pokemon", sources.pokemon);
pokemonOrderDoc.entries[0].values.Happiness = "71";
pokemonOrderDoc.entries[0].dirty = true;
pokemonOrderDoc.dirty = true;
const orderedPokemon = serializeDocument(pokemonOrderDoc);
const firstBlock = orderedPokemon.match(/^\[1\][\s\S]*?(?=^#-+\s*$)/m)?.[0] || "";
const writtenKeys = [...firstBlock.matchAll(/^([A-Za-z][A-Za-z0-9_]*)\s*=/gm)].map((match) => match[1]);
const expectedKeys = POKEMON_ORDER.filter((key) => normalize(pokemonOrderDoc.entries[0].values[key]));
assert.deepEqual(writtenKeys, expectedKeys, "edited Pokémon fields must use the PE19.1 canonical order");

const malformedMoves = parseDocument("moves", sources.moves);
assert.equal(malformedMoves.parseWarnings.length, 1, "the known NIGHTSHADE quote issue must be reported");
const nightShade = malformedMoves.entries.find((entry) => entry.idNumber === 245);
assert.ok(nightShade, "NIGHTSHADE must not be dropped by the tolerant parser");
nightShade.values.Description = "Descripción reparada de forma segura.";
nightShade.dirty = true;
malformedMoves.dirty = true;
const repairedMoves = verifySerialization(malformedMoves, serializeDocument(malformedMoves));
assert.equal(repairedMoves.parseWarnings.length, 0, "editing NIGHTSHADE must repair its malformed CSV quoting");

const untouchedPokemonName = documents.pokemon.entries[0].values.Name;
setLanguage("en");
assert.equal(t("Movimientos"), "Moves", "English must be the default UI vocabulary");
assert.equal(t("Línea 255: contiene comillas sin cerrar; se ha recuperado sin modificar el archivo."), "Line 255: contains an unclosed quote; it was recovered without modifying the file.", "dynamic validation messages must translate to English");
setLanguage("es");
assert.equal(t("Movimientos"), "Movimientos", "Spanish must preserve the source UI vocabulary");
assert.equal(documents.pokemon.entries[0].values.Name, untouchedPokemonName, "changing UI language must not alter PBS values");
setLanguage("en");
assert.deepEqual(types.filter((type) => !hasEnglishTranslation(type.name)).map((type) => type.name), [], "every project type badge must have an explicit English label");
const schemaUiStrings = [
  ...STAT_NAMES,
  ...Object.values(ENUMS).flatMap((options) => options.filter(Array.isArray).map(([, label]) => label)),
  ...MOVE_FLAGS.map(([, label]) => label), ...NATURES.map(([, label]) => label),
  ...Object.values(SCHEMAS).flatMap((schema) => [schema.label, ...schema.sections.flatMap((section) => [section.label, ...section.fields.map((field) => field.label)])]),
];
assert.deepEqual([...new Set(schemaUiStrings.filter((value) => !hasEnglishTranslation(value)))], [], "every schema-facing label must have an explicit English translation");
const localizedSourceFiles = ["src/app/editor.js", "src/ebdx/ebdx_positioner.js", "src/pbs/trainer_team.js", "src/ui/visual_badges.js", "index.js"];
const untranslatedKeys = [];
for (const sourceFile of localizedSourceFiles) {
  const source = await readFile(new URL(`../${sourceFile}`, import.meta.url), "utf8");
  for (const match of source.matchAll(/\bt\((['"`])([^$\\]*?)\1\)/g)) {
    if (!hasEnglishTranslation(match[2])) untranslatedKeys.push(`${sourceFile}: ${match[2]}`);
  }
}
assert.deepEqual(untranslatedKeys, [], "every literal passed to t() must have an explicit English translation");

console.log(JSON.stringify({
  counts: Object.fromEntries(Object.entries(documents).map(([kind, document]) => [kind, document.entries.length])),
  types: types.length,
  baselineErrors: baseline.errors.length,
  baselineWarnings: baseline.warnings.length,
  roundtrip: "ok",
}, null, 2));

function normalize(value) { return String(value ?? "").trim(); }
