import { ESSENTIALS_MAX_LEVEL } from "../pbs/schema.js";

const WORLD_PATHS = Object.freeze({
  townMap: "PBS/townmap.txt",
  encounters: "PBS/encounters.txt",
  connections: "PBS/connections.txt",
  metadata: "PBS/metadata.txt",
});

// Compatibility note: extend this registry if the game or a plugin registers,
// removes or changes GameData::EncounterType records.
export const ENCOUNTER_TYPES = Object.freeze([
  ["Land", 21], ["LandDay", 21], ["LandNight", 21], ["LandMorning", 21], ["LandAfternoon", 21], ["LandEvening", 21],
  ["Cave", 5], ["CaveDay", 5], ["CaveNight", 5], ["CaveMorning", 5], ["CaveAfternoon", 5], ["CaveEvening", 5],
  ["Water", 2], ["WaterDay", 2], ["WaterNight", 2], ["WaterMorning", 2], ["WaterAfternoon", 2], ["WaterEvening", 2],
  ["OldRod", null], ["GoodRod", null], ["SuperRod", null], ["RockSmash", 50], ["HeadbuttLow", null], ["HeadbuttHigh", null], ["BugContest", 21],
]);

export const GLOBAL_METADATA_ORDER = Object.freeze([
  "Home", "WildBattleBGM", "TrainerBattleBGM", "WildVictoryME", "TrainerVictoryME", "WildCaptureME", "SurfBGM", "BicycleBGM",
  "PlayerA", "PlayerB", "PlayerC", "PlayerD", "PlayerE", "PlayerF", "PlayerG", "PlayerH",
]);

export const MAP_METADATA_ORDER = Object.freeze([
  "Outdoor", "ShowArea", "Bicycle", "BicycleAlways", "HealingSpot", "Weather", "MapPosition", "DiveMap", "DarkMap", "SafariMap",
  "SnapEdges", "Dungeon", "BattleBack", "WildBattleBGM", "TrainerBattleBGM", "WildVictoryME", "TrainerVictoryME", "WildCaptureME", "MapSize", "Environment",
]);

export const WEATHER_TYPES = Object.freeze(["None", "Rain", "Storm", "Snow", "Blizzard", "Sandstorm", "HeavyRain", "Sun", "Fog"]);
export const ENVIRONMENTS = Object.freeze(["None", "Grass", "TallGrass", "MovingWater", "StillWater", "Puddle", "Underwater", "Cave", "Rock", "Sand", "Forest", "ForestGrass", "Snow", "Ice", "Volcano", "Graveyard", "Sky", "Space", "UltraSpace"]);
export const DIRECTIONS = Object.freeze(["N", "E", "S", "W"]);
export const OPPOSITE_DIRECTION = Object.freeze({ N: "S", E: "W", S: "N", W: "E" });

function sourceInfo(text) {
  const raw = String(text ?? "");
  return {
    text: raw,
    bom: raw.startsWith("\uFEFF"),
    newline: raw.includes("\r\n") ? "\r\n" : "\n",
    trailingNewline: /(?:\r\n|\n)$/.test(raw),
    lines: raw.replace(/^\uFEFF/, "").split(/\r?\n/),
  };
}

function clone(value) { return JSON.parse(JSON.stringify(value)); }
function snapshot(entry, fields) {
  const data = {};
  for (const field of fields) data[field] = clone(entry[field]);
  return data;
}

function finishDocument(document, fields) {
  document.trackedFields = fields;
  for (const entry of document.entries) entry.original = snapshot(entry, fields);
  return document;
}

export function refreshWorldEntry(document, entry) {
  entry.dirty = entry.isNew || JSON.stringify(snapshot(entry, document.trackedFields)) !== JSON.stringify(entry.original);
  document.dirty = document.entries.some((item) => item.dirty) || Boolean(document.deletedEntries?.length);
  return entry.dirty;
}

export function deleteWorldEntry(document, entry) {
  const index = document.entries.indexOf(entry);
  if (index < 0) return false;
  document.entries.splice(index, 1);
  if (!entry.isNew) (document.deletedEntries ||= []).push(entry);
  document.dirty = true;
  return true;
}

export function restoreWorldDocument(document) {
  for (const entry of document.entries) {
    if (entry.isNew) continue;
    Object.assign(entry, clone(entry.original));
    entry.dirty = false;
  }
  document.entries = document.entries.filter((entry) => !entry.isNew);
  for (const entry of document.deletedEntries ?? []) {
    Object.assign(entry, clone(entry.original));
    entry.dirty = false;
    document.entries.push(entry);
  }
  document.deletedEntries = [];
  document.entries.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
  document.dirty = false;
}

function splitCsv(value) {
  const result = [];
  let current = "";
  let quoted = false;
  for (let index = 0; index < String(value ?? "").length; index += 1) {
    const character = String(value)[index];
    if (character === '"') {
      if (quoted && String(value)[index + 1] === '"') { current += '"'; index += 1; }
      else quoted = !quoted;
    } else if (character === "," && !quoted) { result.push(current.trim()); current = ""; }
    else current += character;
  }
  result.push(current.trim());
  return result;
}

function csv(value) {
  const text = String(value ?? "");
  return /[",\r\n]|^\s|\s$/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function joinOutput(info, lines) {
  const body = lines.join(info.newline);
  return `${info.bom ? "\uFEFF" : ""}${body}${info.trailingNewline && !body.endsWith(info.newline) ? info.newline : ""}`;
}

function sectionRanges(lines, pattern) {
  const starts = [];
  lines.forEach((line, index) => { if (pattern.test(line.trim())) starts.push(index); });
  return starts.map((start, index) => ({ start, end: starts[index + 1] ?? lines.length }));
}

export function parseMetadata(text) {
  const info = sourceInfo(text);
  const ranges = sectionRanges(info.lines, /^\[\s*\d+\s*\]$/);
  const entries = ranges.map((range, order) => {
    const header = info.lines[range.start].trim();
    const mapId = Number(header.match(/\d+/)?.[0] ?? 0);
    const values = {};
    const comments = [];
    for (const line of info.lines.slice(range.start + 1, range.end)) {
      const assignment = line.match(/^\s*(\w+)\s*=\s*(.*)$/);
      if (assignment) values[assignment[1]] = assignment[2].trim();
      else if (/^\s*#(?!-)/.test(line)) comments.push(line);
    }
    return { key: String(mapId), mapId, values, comments, order, range, dirty: false, isNew: false };
  });
  return finishDocument({ kind: "metadata", path: WORLD_PATHS.metadata, info, entries, deletedEntries: [], preambleEnd: ranges[0]?.start ?? info.lines.length, dirty: false }, ["mapId", "values"]);
}

function canonicalMetadata(entry, mapName = "") {
  const lines = [`[${String(entry.mapId).padStart(3, "0")}]`];
  const comments = (entry.comments ?? []).filter((line) => /^\s*#(?!-)/.test(line));
  if (comments.length) lines.push(...comments);
  else if (mapName && entry.mapId !== 0) lines.push(`# ${mapName}`);
  const order = entry.mapId === 0 ? GLOBAL_METADATA_ORDER : MAP_METADATA_ORDER;
  for (const key of order) if (String(entry.values[key] ?? "").trim() !== "") lines.push(`${key} = ${entry.values[key]}`);
  for (const key of Object.keys(entry.values)) if (!order.includes(key) && String(entry.values[key] ?? "").trim() !== "") lines.push(`${key} = ${entry.values[key]}`);
  return lines;
}

export function serializeMetadata(document, mapNames = new Map()) {
  const out = document.info.lines.slice(0, document.preambleEnd);
  while (out.length && out.at(-1) === "") out.pop();
  for (const entry of document.entries.sort((a, b) => a.order - b.order)) {
    if (!/^\s*#-+\s*$/.test(out.at(-1) || "")) out.push("#-------------------------------");
    if (!entry.dirty && !entry.isNew && entry.range) out.push(...document.info.lines.slice(entry.range.start, entry.range.end));
    else out.push(...canonicalMetadata(entry, mapNames.get(entry.mapId) || ""));
  }
  while (out.length && out.at(-1) === "") out.pop();
  return joinOutput(document.info, out);
}

export function createMetadataEntry(document, mapId) {
  const entry = { key: String(mapId), mapId, values: {}, comments: [], order: Math.max(-1, ...document.entries.map((item) => item.order)) + 1, range: null, dirty: true, isNew: true };
  entry.original = snapshot(entry, document.trackedFields);
  document.entries.push(entry); document.dirty = true;
  return entry;
}

export function parseEncounters(text) {
  const info = sourceInfo(text);
  const ranges = sectionRanges(info.lines, /^\[\s*\d+(?:\s*,\s*\d+)?\s*\](?:\s*#.*)?$/);
  const known = new Set(ENCOUNTER_TYPES.map(([id]) => id));
  const entries = ranges.map((range, order) => {
    const match = info.lines[range.start].match(/^\s*\[\s*(\d+)(?:\s*,\s*(\d+))?\s*\](?:\s*#\s*(.*))?$/);
    const mapId = Number(match?.[1] ?? 0), version = Number(match?.[2] ?? 0), mapName = match?.[3]?.trim() || "";
    const groups = [];
    const comments = [];
    let current = null;
    for (const line of info.lines.slice(range.start + 1, range.end)) {
      const trimmed = line.trim();
      if (!trimmed) continue;
      if (trimmed.startsWith("#")) {
        if (!/^#-+\s*$/.test(trimmed)) comments.push(line);
        continue;
      }
      const values = splitCsv(trimmed);
      if (known.has(values[0])) {
        current = { type: values[0], chance: values[1] ?? "", slots: [] };
        groups.push(current);
      } else if (current && /^\d+$/.test(values[0] || "") && values.length >= 3) {
        current.slots.push({ weight: values[0], species: values[1], minLevel: values[2], maxLevel: values[3] || values[2] });
      }
    }
    return { key: `${mapId},${version}`, mapId, version, mapName, groups, comments, order, range, dirty: false, isNew: false };
  });
  return finishDocument({ kind: "encounters", path: WORLD_PATHS.encounters, info, entries, deletedEntries: [], preambleEnd: ranges[0]?.start ?? info.lines.length, dirty: false }, ["mapId", "version", "mapName", "groups"]);
}

function canonicalEncounter(entry, mapName = "") {
  const header = entry.version > 0 ? `[${String(entry.mapId).padStart(3, "0")},${entry.version}]` : `[${String(entry.mapId).padStart(3, "0")}]`;
  const lines = [`${header}${mapName || entry.mapName ? ` # ${mapName || entry.mapName}` : ""}`];
  lines.push(...(entry.comments ?? []).filter((line) => /^\s*#(?!-)/.test(line)));
  for (const group of entry.groups) {
    lines.push(`${group.type}${String(group.chance ?? "").trim() === "" ? "" : `,${group.chance}`}`);
    for (const slot of group.slots) {
      const maximum = String(slot.maxLevel ?? slot.minLevel);
      lines.push(`    ${slot.weight},${slot.species},${slot.minLevel}${maximum === String(slot.minLevel) ? "" : `,${maximum}`}`);
    }
  }
  return lines;
}

export function serializeEncounters(document, mapNames = new Map()) {
  const out = document.info.lines.slice(0, document.preambleEnd);
  while (out.length && out.at(-1) === "") out.pop();
  for (const entry of document.entries.sort((a, b) => a.order - b.order)) {
    if (!/^\s*#-+\s*$/.test(out.at(-1) || "")) out.push("#-------------------------------");
    if (!entry.dirty && !entry.isNew && entry.range) out.push(...document.info.lines.slice(entry.range.start, entry.range.end));
    else out.push(...canonicalEncounter(entry, mapNames.get(entry.mapId) || ""));
  }
  while (out.length && out.at(-1) === "") out.pop();
  return joinOutput(document.info, out);
}

export function createEncounterEntry(document, mapId, mapName = "") {
  const versions = new Set(document.entries.filter((item) => item.mapId === mapId).map((item) => item.version));
  let version = 0; while (versions.has(version)) version += 1;
  const entry = { key: `${mapId},${version}`, mapId, version, mapName, groups: [{ type: "Land", chance: "21", slots: [{ weight: "100", species: "BULBASAUR", minLevel: "5", maxLevel: "5" }] }], order: Math.max(-1, ...document.entries.map((item) => item.order)) + 1, range: null, dirty: true, isNew: true };
  entry.original = snapshot(entry, document.trackedFields); document.entries.push(entry); document.dirty = true; return entry;
}

export function parseConnections(text) {
  const info = sourceInfo(text);
  const entries = [];
  let pendingStart = 0;
  info.lines.forEach((line, index) => {
    const values = splitCsv(line.trim());
    if (values.length !== 6 || !/^\d+$/.test(values[0]) || !/^\d+$/.test(values[3])) return;
    const directionValue = (value) => /^-?\d+$/.test(value) ? Number(value) : value;
    const entry = { key: `connection-${entries.length}`, mapA: Number(values[0]), directionA: directionValue(values[1]), offsetA: Number(values[2]), mapB: Number(values[3]), directionB: directionValue(values[4]), offsetB: Number(values[5]), prefixLines: info.lines.slice(pendingStart, index), order: entries.length, range: { start: pendingStart, end: index + 1 }, dirty: false, isNew: false };
    entries.push(entry); pendingStart = index + 1;
  });
  return finishDocument({ kind: "connections", path: WORLD_PATHS.connections, info, entries, deletedEntries: [], trailingStart: pendingStart, dirty: false }, ["mapA", "directionA", "offsetA", "mapB", "directionB", "offsetB"]);
}

function connectionComment(entry, mapNames) {
  const first = mapNames.get(entry.mapA) || `Map ${entry.mapA}`;
  const second = mapNames.get(entry.mapB) || `Map ${entry.mapB}`;
  return `# ${first} (${entry.mapA}) - ${second} (${entry.mapB})`;
}

export function serializeConnections(document, mapNames = new Map()) {
  const out = [];
  for (const entry of document.entries.sort((a, b) => a.order - b.order)) {
    if (!entry.dirty && !entry.isNew && entry.range) out.push(...document.info.lines.slice(entry.range.start, entry.range.end));
    else {
      const prefix = entry.isNew ? [connectionComment(entry, mapNames)] : (entry.prefixLines ?? []);
      out.push(...prefix, `${entry.mapA},${entry.directionA},${entry.offsetA},${entry.mapB},${entry.directionB},${entry.offsetB}`);
    }
  }
  if (document.trailingStart < document.info.lines.length) out.push(...document.info.lines.slice(document.trailingStart));
  while (out.length && out.at(-1) === "") out.pop();
  return joinOutput(document.info, out);
}

export function createConnectionEntry(document, mapA, mapB) {
  const entry = { key: `connection-new-${Date.now()}-${Math.random()}`, mapA, directionA: "N", offsetA: 0, mapB, directionB: "S", offsetB: 0, order: Math.max(-1, ...document.entries.map((item) => item.order)) + 1, range: null, dirty: true, isNew: true };
  entry.original = snapshot(entry, document.trackedFields); document.entries.push(entry); document.dirty = true; return entry;
}

export function parseTownMap(text) {
  const info = sourceInfo(text);
  const ranges = sectionRanges(info.lines, /^\[\s*\d+\s*\]$/);
  const entries = ranges.map((range, order) => {
    const regionId = Number(info.lines[range.start].match(/\d+/)?.[0] ?? 0);
    let name = "", filename = "";
    const points = [];
    const comments = [];
    for (const line of info.lines.slice(range.start + 1, range.end)) {
      const match = line.match(/^\s*(\w+)\s*=\s*(.*)$/);
      if (!match) {
        if (/^\s*#(?!-)/.test(line)) comments.push(line);
        continue;
      }
      const values = splitCsv(match[2]);
      if (match[1] === "Name") name = values[0] || "";
      else if (match[1] === "Filename") filename = values[0] || "";
      else if (match[1] === "Point") points.push({ x: Number(values[0]) || 0, y: Number(values[1]) || 0, name: values[2] || "", poi: values[3] || "", healingMap: values[4] || "", healingX: values[5] || "", healingY: values[6] || "", switchId: values[7] || "" });
    }
    return { key: String(regionId), regionId, name, filename, points, comments, order, range, dirty: false, isNew: false };
  });
  return finishDocument({ kind: "townMap", path: WORLD_PATHS.townMap, info, entries, deletedEntries: [], preambleEnd: ranges[0]?.start ?? info.lines.length, dirty: false }, ["regionId", "name", "filename", "points"]);
}

function canonicalTownMap(entry) {
  const lines = [`[${entry.regionId}]`, ...(entry.comments ?? []).filter((line) => /^\s*#(?!-)/.test(line)), `Name = ${csv(entry.name)}`, `Filename = ${csv(entry.filename)}`];
  for (const point of entry.points) lines.push(`Point = ${[point.x, point.y, point.name, point.poi, point.healingMap, point.healingX, point.healingY, point.switchId].map(csv).join(",")}`);
  return lines;
}

export function serializeTownMap(document) {
  const out = document.info.lines.slice(0, document.preambleEnd);
  while (out.length && out.at(-1) === "") out.pop();
  for (const entry of document.entries.sort((a, b) => a.order - b.order)) {
    if (!/^\s*#-+\s*$/.test(out.at(-1) || "")) out.push("#-------------------------------");
    if (!entry.dirty && !entry.isNew && entry.range) out.push(...document.info.lines.slice(entry.range.start, entry.range.end));
    else out.push(...canonicalTownMap(entry));
  }
  while (out.length && out.at(-1) === "") out.pop();
  return joinOutput(document.info, out);
}

export function createTownMapRegion(document) {
  const used = new Set(document.entries.map((entry) => entry.regionId)); let regionId = 0; while (used.has(regionId)) regionId += 1;
  const entry = { key: String(regionId), regionId, name: "New region", filename: "", points: [], order: Math.max(-1, ...document.entries.map((item) => item.order)) + 1, range: null, dirty: true, isNew: true };
  entry.original = snapshot(entry, document.trackedFields); document.entries.push(entry); document.dirty = true; return entry;
}

export function validateWorldDocument(document, context = {}) {
  const issues = [];
  const error = (entry, field, message) => issues.push({ level: "error", kind: document.kind, key: entry?.key || "file", field, message });
  const speciesExists = (id) => context.species?.has(id);
  if (document.kind === "encounters") {
    const keys = new Set();
    for (const entry of document.entries) {
      const key = `${entry.mapId},${entry.version}`;
      if (!Number.isInteger(entry.mapId) || entry.mapId <= 0 || !Number.isInteger(entry.version) || entry.version < 0) error(entry, "mapId", "El mapa y la versión deben ser números enteros válidos.");
      if (keys.has(key)) error(entry, "mapId", "Este mapa y versión de encuentros están definidos más de una vez.");
      keys.add(key);
      if (!context.mapIds?.has(entry.mapId)) error(entry, "mapId", "El mapa seleccionado no existe en el proyecto.");
      if (!entry.groups.length) error(entry, "groups", "Añade al menos un método de encuentro.");
      for (const group of entry.groups) {
        if (!ENCOUNTER_TYPES.some(([id]) => id === group.type)) error(entry, "groups", `Método de encuentro desconocido: ${group.type}.`);
        if (!group.slots.length) error(entry, "groups", `${group.type} no tiene encuentros.`);
        const chance = String(group.chance ?? "").trim();
        if (chance !== "" && (!/^\d+$/.test(chance) || Number(chance) > 100)) error(entry, "groups", `La probabilidad de activación de ${group.type} debe estar entre 0 y 100.`);
        const total = group.slots.reduce((sum, slot) => sum + (Number(slot.weight) || 0), 0);
        if (total !== 100) error(entry, "groups", `Las probabilidades de ${group.type} suman ${total} %, no 100 %.`);
        for (const slot of group.slots) {
          if (!Number.isInteger(Number(slot.weight)) || Number(slot.weight) <= 0) error(entry, "groups", `El peso de ${slot.species} debe ser un entero mayor que 0.`);
          if (!speciesExists(slot.species)) error(entry, "groups", `Especie desconocida: ${slot.species}.`);
          const minimum = Number(slot.minLevel), maximum = Number(slot.maxLevel);
          if (!Number.isInteger(minimum) || !Number.isInteger(maximum) || minimum < 1 || maximum > ESSENTIALS_MAX_LEVEL || minimum > maximum) error(entry, "groups", `Rango de nivel no válido para ${slot.species}; debe estar entre 1 y ${ESSENTIALS_MAX_LEVEL}.`);
        }
      }
    }
  } else if (document.kind === "connections") {
    const signatures = new Set();
    for (const entry of document.entries) {
      if (!context.mapIds?.has(entry.mapA) || !context.mapIds?.has(entry.mapB)) error(entry, "maps", "Uno de los mapas conectados no existe.");
      if (entry.mapA === entry.mapB) error(entry, "maps", "Un mapa no puede conectarse consigo mismo.");
      const edgeMode = DIRECTIONS.includes(String(entry.directionA)) || DIRECTIONS.includes(String(entry.directionB));
      if (edgeMode && OPPOSITE_DIRECTION[entry.directionA] !== entry.directionB) error(entry, "directions", "Los lados conectados deben estar enfrentados.");
      if (!edgeMode && (!Number.isInteger(Number(entry.directionA)) || !Number.isInteger(Number(entry.directionB)))) error(entry, "directions", "Las coordenadas de conexión deben ser números enteros.");
      if (!Number.isInteger(Number(entry.offsetA)) || !Number.isInteger(Number(entry.offsetB))) error(entry, "offsets", "Los desplazamientos deben ser números enteros.");
      const direct = `${entry.mapA},${entry.directionA},${entry.offsetA},${entry.mapB},${entry.directionB},${entry.offsetB}`;
      const reverse = `${entry.mapB},${entry.directionB},${entry.offsetB},${entry.mapA},${entry.directionA},${entry.offsetA}`;
      if (signatures.has(direct) || signatures.has(reverse)) error(entry, "maps", "Esta conexión ya está definida.");
      signatures.add(direct);
    }
  } else if (document.kind === "metadata") {
    const ids = new Set();
    for (const entry of document.entries) {
      if (ids.has(entry.mapId)) error(entry, "mapId", "Los metadatos de este mapa están definidos más de una vez.");
      ids.add(entry.mapId);
      if (!Number.isInteger(entry.mapId) || entry.mapId < 0) error(entry, "mapId", "El ID del mapa debe ser un número entero válido.");
      if (entry.mapId !== 0 && !context.mapIds?.has(entry.mapId)) error(entry, "mapId", "El mapa seleccionado no existe en el proyecto.");
      if (entry.values.Weather) {
        const [weather, chance] = splitCsv(entry.values.Weather);
        const chanceText = String(chance ?? "").trim();
        if (!WEATHER_TYPES.includes(weather) || !/^\d+$/.test(chanceText) || Number(chanceText) > 100) error(entry, "Weather", "El clima debe usar un tipo válido y una probabilidad entre 0 y 100.");
      }
      if (entry.values.Environment && !ENVIRONMENTS.includes(entry.values.Environment)) error(entry, "Environment", "El entorno de combate no es válido.");
      if (entry.values.BattleBack && context.battlebacks?.size && !context.battlebacks.has(entry.values.BattleBack.toLowerCase())) error(entry, "BattleBack", "No existe un fondo de combate con ese nombre.");
      if (entry.values.MapPosition) {
        const [region, x, y] = splitCsv(entry.values.MapPosition).map(Number);
        if ((context.regionIds && !context.regionIds.has(region)) || !Number.isInteger(x) || x < 0 || !Number.isInteger(y) || y < 0) error(entry, "MapPosition", "La posición del mapa regional no es válida.");
      }
    }
    if (!document.entries.some((entry) => entry.mapId === 0)) error(null, "mapId", "Falta la sección global [000] de metadata.txt.");
  } else if (document.kind === "townMap") {
    const ids = new Set();
    for (const entry of document.entries) {
      if (ids.has(entry.regionId)) error(entry, "regionId", "Este ID de región ya está en uso.");
      ids.add(entry.regionId);
      if (!Number.isInteger(entry.regionId) || entry.regionId < 0) error(entry, "regionId", "El ID de región debe ser un número entero válido.");
      if (!entry.name.trim()) error(entry, "name", "El nombre de la región es obligatorio.");
      if (!entry.filename.trim()) error(entry, "filename", "Elige una imagen para el mapa regional.");
      const picture = entry.filename.replace(/\.[^.]+$/, "").toLowerCase();
      if (picture && context.pictures?.size && !context.pictures.has(picture)) error(entry, "filename", "La imagen del mapa regional no existe en Graphics/Pictures.");
      const coordinates = new Set();
      for (const point of entry.points) {
        if (!Number.isInteger(point.x) || point.x < 0 || !Number.isInteger(point.y) || point.y < 0) error(entry, "points", "Las coordenadas de los puntos deben ser enteros positivos o cero.");
        const coordinate = `${point.x},${point.y}`;
        if (coordinates.has(coordinate)) error(entry, "points", `Hay más de un punto en ${coordinate}.`);
        coordinates.add(coordinate);
        const fly = [point.healingMap, point.healingX, point.healingY].filter((value) => String(value).trim() !== "");
        if (fly.length !== 0 && fly.length !== 3) error(entry, "points", `El destino de vuelo de ${point.name || `${point.x},${point.y}`} está incompleto.`);
        if (fly.length === 3 && fly.some((value) => !/^\d+$/.test(String(value)))) error(entry, "points", `El destino de vuelo de ${point.name || coordinate} debe ser numérico.`);
        if (String(point.switchId).trim() && !/^\d+$/.test(String(point.switchId))) error(entry, "points", `El interruptor de ${point.name || coordinate} debe ser numérico.`);
      }
    }
  }
  return issues;
}

export async function loadWorldDocuments(ctx) {
  const [townMap, encounters, connections, metadata] = await Promise.all([
    ctx.fs.readProjectFile(WORLD_PATHS.townMap).then(parseTownMap),
    ctx.fs.readProjectFile(WORLD_PATHS.encounters).then(parseEncounters),
    ctx.fs.readProjectFile(WORLD_PATHS.connections).then(parseConnections),
    ctx.fs.readProjectFile(WORLD_PATHS.metadata).then(parseMetadata),
  ]);
  return { townMap, encounters, connections, metadata };
}

export function worldBackupPath(path) { return path.replace(/\.txt$/i, ".maker-studio.bak"); }

export function serializeWorldDocument(document, mapNames = new Map()) {
  if (document.kind === "townMap") return serializeTownMap(document);
  if (document.kind === "encounters") return serializeEncounters(document, mapNames);
  if (document.kind === "connections") return serializeConnections(document, mapNames);
  if (document.kind === "metadata") return serializeMetadata(document, mapNames);
  throw new Error(`Unsupported world document: ${document.kind}`);
}

export function verifyWorldSerialization(document, output, context = {}) {
  const parsers = { townMap: parseTownMap, encounters: parseEncounters, connections: parseConnections, metadata: parseMetadata };
  const parsed = parsers[document.kind](output);
  const issues = validateWorldDocument(parsed, context);
  if (issues.length) throw new Error(issues[0].message);
  const comparable = (entry, fields) => {
    const value = snapshot(entry, fields);
    if (value.values) {
      const normalizedValues = {};
      for (const key of Object.keys(value.values).sort()) {
        if (String(value.values[key] ?? "") !== "") normalizedValues[key] = value.values[key];
      }
      value.values = normalizedValues;
    }
    return value;
  };
  const expected = document.entries.map((entry) => comparable(entry, document.trackedFields));
  const actual = parsed.entries.map((entry) => comparable(entry, parsed.trackedFields));
  if (JSON.stringify(expected) !== JSON.stringify(actual)) throw new Error(`${document.path} no superó la comprobación de relectura.`);
  return parsed;
}

export { WORLD_PATHS, splitCsv };
