import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import {
  createConnectionEntry,
  createEncounterEntry,
  createMetadataEntry,
  createTownMapRegion,
  parseConnections,
  parseEncounters,
  parseMetadata,
  parseTownMap,
  refreshWorldEntry,
  serializeConnections,
  serializeEncounters,
  serializeMetadata,
  serializeTownMap,
  validateWorldDocument,
  verifyWorldSerialization,
} from "../src/world/world_data.js";
import { findTownMapPointMapId } from "../src/world/world_editors.js";

const root = path.resolve(process.argv[2] || "C:/Users/mibas/Desktop/aaa");
const read = (name) => fs.readFileSync(path.join(root, "PBS", `${name}.txt`), "utf8");
const cases = [
  ["townmap", parseTownMap, serializeTownMap],
  ["encounters", parseEncounters, serializeEncounters],
  ["connections", parseConnections, serializeConnections],
  ["metadata", parseMetadata, serializeMetadata],
];

for (const [name, parse, serialize] of cases) {
  const source = read(name);
  assert.equal(serialize(parse(source)), source, `${name}.txt no-op serialization must be byte-for-byte identical`);
}

const mapIds = new Set(parseMetadata(read("metadata")).entries.map((entry) => entry.mapId));
for (const entry of parseConnections(read("connections")).entries) { mapIds.add(entry.mapA); mapIds.add(entry.mapB); }
const species = new Set([...read("pokemon").matchAll(/^InternalName\s*=\s*([^\r\n#]+)/gm)].map((match) => match[1].trim()));
for (const match of read("pokemonforms").matchAll(/^\[\s*([^,\]\s]+)\s*,\s*(\d+)\s*\]/gm)) species.add(`${match[1]}_${Number(match[2])}`);
const context = { mapIds, species };

{
  const metadata = [
    { mapId: 11, values: { MapPosition: "0,12,12", Outdoor: "" } },
    { mapId: 12, values: { MapPosition: "0,12,12", Outdoor: "true" } },
    { mapId: 13, values: { MapPosition: "0,12,12", Outdoor: "true" } },
  ];
  const maps = [{ id: 11, name: "Safari Zone gate" }, { id: 12, name: "Safari Zone" }, { id: 13, name: "Safari Area 2" }];
  assert.equal(findTownMapPointMapId(0, { x: 12, y: 12, name: "Safari Zone" }, metadata, maps), 12, "a town map point must prefer the matching map name at its regional coordinates");
  assert.equal(findTownMapPointMapId(0, { x: 12, y: 12, name: "Unknown" }, metadata, maps), 12, "a town map point must fall back to an outdoor map at its regional coordinates");
  assert.equal(findTownMapPointMapId(0, { x: 4, y: 4, name: "Missing" }, metadata, maps), 11, "a town map point without metadata must fall back safely to the first project map");
}

function untouchedBlock(document, entry) { return document.info.lines.slice(entry.range.start, entry.range.end).join(document.info.newline); }

{
  const document = parseEncounters(read("encounters"));
  const untouched = untouchedBlock(document, document.entries[1]);
  document.entries[0].groups[0].slots[0].minLevel = "15";
  document.entries[0].groups[0].slots[0].maxLevel = "20";
  refreshWorldEntry(document, document.entries[0]);
  const output = serializeEncounters(document);
  assert.ok(output.includes(untouched), "editing encounters must preserve untouched sections literally");
  assert.equal(verifyWorldSerialization(document, output, context).kind, "encounters");
}

{
  const document = parseEncounters(read("encounters"));
  const form = [...species].find((id) => /_\d+$/.test(id));
  assert.ok(form, "the project must expose at least one encounter-selectable Pokémon form");
  document.entries[0].groups[0].slots[0].species = form;
  refreshWorldEntry(document, document.entries[0]);
  assert.equal(validateWorldDocument(document, context).some((issue) => issue.message.includes(form)), false, "a defined Pokémon form must be valid in encounters");
  document.entries[0].groups[0].slots[0].species = `${form.replace(/_\d+$/, "")}_9999`;
  refreshWorldEntry(document, document.entries[0]);
  assert.equal(validateWorldDocument(document, context).some((issue) => issue.message.includes("Especie desconocida")), true, "an undefined Pokémon form must be rejected like the Essentials compiler rejects it");
}

{
  const document = parseMetadata(read("metadata"));
  const entry = document.entries.find((item) => item.mapId !== 0);
  entry.values.ShowArea = "";
  refreshWorldEntry(document, entry);
  assert.equal(verifyWorldSerialization(document, serializeMetadata(document), context).kind, "metadata");
}

{
  const document = parseConnections(read("connections"));
  document.entries[0].offsetA += 1;
  refreshWorldEntry(document, document.entries[0]);
  assert.equal(verifyWorldSerialization(document, serializeConnections(document), context).kind, "connections");
  document.entries[0].directionA = 4;
  document.entries[0].offsetA = 8;
  document.entries[0].directionB = 0;
  document.entries[0].offsetB = 2;
  refreshWorldEntry(document, document.entries[0]);
  assert.equal(verifyWorldSerialization(document, serializeConnections(document), context).kind, "connections", "coordinate-based connections must remain supported");
}

{
  const document = parseTownMap(read("townmap"));
  document.entries[0].points[0].name += " QA";
  refreshWorldEntry(document, document.entries[0]);
  assert.equal(verifyWorldSerialization(document, serializeTownMap(document), context).kind, "townMap");
}

{
  const metadata = parseMetadata("[000]\n# first metadata comment\n# second metadata comment\nHome = 1,1,1,1\n\n[001]\n# map comment one\n# map comment two\nOutdoor = true\n");
  metadata.entries[1].values.ShowArea = "true";
  refreshWorldEntry(metadata, metadata.entries[1]);
  const output = serializeMetadata(metadata);
  assert.ok(output.includes("# map comment one\n# map comment two"), "editing metadata must preserve every section comment");

  const encounters = parseEncounters("[001] # Test\n# encounter comment one\n# encounter comment two\nLand,21\n100,BULBASAUR,5\n");
  encounters.entries[0].groups[0].slots[0].minLevel = "6";
  encounters.entries[0].groups[0].slots[0].maxLevel = "6";
  refreshWorldEntry(encounters, encounters.entries[0]);
  assert.ok(serializeEncounters(encounters).includes("# encounter comment one\n# encounter comment two"), "editing encounters must preserve every section comment");

  const townMap = parseTownMap("[0]\n# town comment one\n# town comment two\nName = Test\nFilename = mapRegion0\nPoint = 1,1,Test\n");
  townMap.entries[0].name = "Edited";
  refreshWorldEntry(townMap, townMap.entries[0]);
  assert.ok(serializeTownMap(townMap).includes("# town comment one\n# town comment two"), "editing town map data must preserve every section comment");

  const connections = parseConnections("# connection comment one\n# connection comment two\n1,N,0,2,S,0\n");
  connections.entries[0].offsetA = 1;
  refreshWorldEntry(connections, connections.entries[0]);
  assert.ok(serializeConnections(connections).startsWith("# connection comment one\n# connection comment two\n"), "editing a connection must preserve its original comments");
}

{
  const invalidWeather = parseMetadata("[000]\nHome = 1,1,1,1\n\n[001]\nWeather = Rain\n");
  assert.ok(validateWorldDocument(invalidWeather, { ...context, mapIds: new Set([...context.mapIds, 1]) }).some((issue) => issue.field === "Weather"), "weather requires a numeric probability");
  invalidWeather.entries[1].values.Weather = "Rain,abc";
  assert.ok(validateWorldDocument(invalidWeather, { ...context, mapIds: new Set([...context.mapIds, 1]) }).some((issue) => issue.field === "Weather"), "weather rejects a non-numeric probability");

  const invalidLevel = parseEncounters("[001]\nLand,21\n100,BULBASAUR,101,101\n");
  assert.ok(validateWorldDocument(invalidLevel, { ...context, mapIds: new Set([...context.mapIds, 1]) }).some((issue) => issue.field === "groups"), "encounters reject levels above the Essentials 19.1 maximum");
}

{
  const town = parseTownMap(read("townmap"));
  const region = createTownMapRegion(town); region.name = "QA"; region.filename = town.entries[0].filename;
  assert.equal(parseTownMap(serializeTownMap(town)).entries.length, town.entries.length);

  const encounters = parseEncounters(read("encounters"));
  const encounter = createEncounterEntry(encounters, [...mapIds][0], "QA");
  encounter.groups[0].slots[0].species = species.has("BULBASAUR") ? "BULBASAUR" : [...species][0];
  assert.equal(parseEncounters(serializeEncounters(encounters)).entries.length, encounters.entries.length);

  const metadata = parseMetadata(read("metadata"));
  const unusedMap = [...mapIds].find((id) => !metadata.entries.some((entry) => entry.mapId === id));
  if (unusedMap != null) assert.equal(parseMetadata(serializeMetadata(metadata)).entries.length + 1, createMetadataEntry(metadata, unusedMap) && metadata.entries.length);

  const connections = parseConnections(read("connections"));
  createConnectionEntry(connections, [...mapIds][0], [...mapIds][1]);
  assert.equal(parseConnections(serializeConnections(connections)).entries.length, connections.entries.length);
}

console.log("World data round-trip, mutation, creation and literal-preservation tests passed.");
