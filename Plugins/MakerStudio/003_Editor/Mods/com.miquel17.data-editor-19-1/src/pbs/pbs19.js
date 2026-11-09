import {
  ENUMS,
  ESSENTIALS_MAX_LEVEL,
  EVOLUTION_METHODS,
  EVOLUTION_PARAMETER,
  FORM_ORDER,
  MOVE_FLAGS,
  PATHS,
  POKEMON_ORDER,
  SCHEMAS,
  fieldsFor,
} from "./schema.js";

const CSV_COLUMNS = {
  abilities: ["IdNumber", "InternalName", "Name", "Description"],
  moves: ["IdNumber", "InternalName", "Name", "FunctionCode", "Power", "Type", "Category", "Accuracy", "TotalPP", "EffectChance", "Target", "Priority", "Flags", "Description"],
  items: ["IdNumber", "InternalName", "Name", "NamePlural", "Pocket", "Price", "Description", "FieldUse", "BattleUse", "ItemType", "Move"],
  trainerTypes: ["IdNumber", "InternalName", "Name", "BaseMoney", "BattleBGM", "VictoryME", "IntroME", "Gender", "SkillLevel", "SkillCode"],
};

const CSV_KINDS = new Set(Object.keys(CSV_COLUMNS));
const ID_PATTERN = /^[A-Za-z][A-Za-z0-9_]*$/;
const INTEGER_EVOLUTIONS = new Set([
  "Level", "LevelMale", "LevelFemale", "LevelDay", "LevelNight", "LevelMorning", "LevelAfternoon", "LevelEvening", "LevelNoWeather",
  "LevelSun", "LevelRain", "LevelSnow", "LevelSandstorm", "LevelCycling", "LevelSurfing", "LevelDiving", "LevelDarkness", "LevelDarkInParty",
  "AttackGreater", "AtkDefEqual", "DefenseGreater", "Silcoon", "Cascoon", "Ninjask", "Shedinja", "Beauty", "Location", "Region",
]);

function splitText(text) {
  const source = String(text ?? "");
  const bom = source.startsWith("\uFEFF");
  const body = bom ? source.slice(1) : source;
  const newline = body.includes("\r\n") ? "\r\n" : "\n";
  const finalNewline = body.endsWith("\n");
  const lines = body.split(/\r?\n/);
  if (finalNewline) lines.pop();
  return { bom, newline, finalNewline, lines };
}

function joinText(document, lines) {
  const body = lines.join(document.newline) + (document.finalNewline ? document.newline : "");
  return `${document.bom ? "\uFEFF" : ""}${body}`;
}

export function parseCsvLine(line, allowUnclosedQuote = false) {
  const fields = [];
  let value = "";
  let quoted = false;
  let wasQuoted = false;
  for (let index = 0; index < line.length; index += 1) {
    const char = line[index];
    if (char === '"') {
      if (quoted && line[index + 1] === '"') {
        value += '"';
        index += 1;
      } else {
        quoted = !quoted;
        wasQuoted = true;
      }
    } else if (char === "," && !quoted) {
      fields.push(wasQuoted ? value : value.trim());
      value = "";
      wasQuoted = false;
    } else {
      value += char;
    }
  }
  if (quoted && !allowUnclosedQuote) throw new Error("Comillas sin cerrar en una línea CSV.");
  fields.push(wasQuoted ? value : value.trim());
  return fields;
}

export function csvCell(value, forceQuote = false) {
  const text = String(value ?? "");
  if (!forceQuote && !/[",\r\n]|^\s|\s$/.test(text)) return text;
  return `"${text.replace(/"/g, '""')}"`;
}

function entryKey(kind, entry) {
  if (kind === "forms") return `${entry.species},${entry.form}`;
  if (kind === "trainers") return entry.key;
  return String(entry.idNumber);
}

function parseCsvDocument(kind, text) {
  const base = splitText(text);
  const columns = CSV_COLUMNS[kind];
  const entries = [];
  const parseErrors = [];
  const parseWarnings = [];
  base.lines.forEach((rawLine, lineIndex) => {
    const trimmed = rawLine.trim();
    if (!trimmed || trimmed.startsWith("#")) return;
    try {
      const cells = parseCsvLine(rawLine);
      if (cells.length < columns.length - (kind === "items" ? 1 : 0)) {
        parseErrors.push(`Línea ${lineIndex + 1}: se esperaban ${columns.length} columnas y se encontraron ${cells.length}.`);
        return;
      }
      const values = {};
      columns.forEach((column, index) => { values[column] = cells[index] ?? ""; });
      const idNumber = Number.parseInt(values.IdNumber, 10);
      const entry = {
        kind,
        idNumber,
        key: String(idNumber),
        values,
        lineIndex,
        dirty: false,
      };
      entries.push(entry);
    } catch (error) {
      if (error.message.includes("Comillas sin cerrar")) {
        try {
          const cells = parseCsvLine(rawLine, true);
          const values = {};
          columns.forEach((column, index) => { values[column] = cells[index] ?? ""; });
          const idNumber = Number.parseInt(values.IdNumber, 10);
          entries.push({ kind, idNumber, key: String(idNumber), values, lineIndex, dirty: false });
          parseWarnings.push({ key: String(idNumber), message: `Línea ${lineIndex + 1}: contiene comillas sin cerrar; se ha recuperado sin modificar el archivo.` });
        } catch (recoveryError) {
          parseErrors.push(`Línea ${lineIndex + 1}: ${recoveryError.message}`);
        }
      } else parseErrors.push(`Línea ${lineIndex + 1}: ${error.message}`);
    }
  });
  return {
    ...base,
    kind,
    path: PATHS[kind],
    format: "csv",
    originalText: String(text ?? ""),
    entries,
    parseErrors,
    parseWarnings,
    dirty: false,
  };
}

const TRAINER_POKEMON_FIELDS = ["Name", "Form", "Gender", "Shiny", "Shadow", "Moves", "Ability", "AbilityIndex", "Item", "Nature", "IV", "EV", "Happiness", "Ball"];

function firstCsvValue(raw) {
  return parseCsvLine(raw, true)[0] ?? "";
}

function parseTrainerDocument(text) {
  const base = splitText(text);
  const entries = [];
  const parseErrors = [];
  const parseWarnings = [];
  let current = null;
  let currentPokemon = null;
  base.lines.forEach((rawLine, lineIndex) => {
    const header = rawLine.trim().match(/^\[(.*)\]$/);
    if (header) {
      try {
        const cells = parseCsvLine(header[1]);
        if (cells.length < 2 || cells.length > 3) throw new Error("la cabecera debe contener tipo, nombre y versión opcional");
        const trainerType = cells[0].trim();
        const name = cells[1];
        const version = cells[2]?.trim() || "0";
        current = {
          kind: "trainers", key: `${trainerType},${name},${version}`, headerIndex: lineIndex,
          values: { TrainerType: trainerType, Name: name, Version: version, Items: "", LoseText: "" },
          pokemon: [], dirty: false,
        };
        currentPokemon = null;
        entries.push(current);
      } catch (error) {
        parseErrors.push(`Línea ${lineIndex + 1}: ${error.message}.`);
        current = null;
      }
      return;
    }
    if (!current) return;
    const assignment = rawLine.match(/^\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (!assignment) return;
    const [, property, rawValue] = assignment;
    if (property === "Pokemon") {
      const cells = parseCsvLine(rawValue, true);
      currentPokemon = { Species: cells[0]?.trim() || "", Level: cells[1]?.trim() || "" };
      current.pokemon.push(currentPokemon);
    } else if (property === "Items") current.values.Items = parseCsvLine(rawValue, true).map((value) => value.trim()).filter(Boolean).join(",");
    else if (property === "LoseText") current.values.LoseText = firstCsvValue(rawValue);
    else if (TRAINER_POKEMON_FIELDS.includes(property)) {
      if (!currentPokemon) parseErrors.push(`Línea ${lineIndex + 1}: ${property} aparece antes de definir un Pokémon.`);
      else if (["Moves", "IV", "EV"].includes(property)) currentPokemon[property] = parseCsvLine(rawValue, true).map((value) => value.trim()).join(",");
      else currentPokemon[property] = firstCsvValue(rawValue).trim();
    }
  });
  for (const entry of entries) {
    if (!entry.pokemon.length) parseErrors.push(`Entrenador [${entry.values.TrainerType},${entry.values.Name}]: debe tener al menos un Pokémon.`);
  }
  return { ...base, kind: "trainers", path: PATHS.trainers, format: "trainers", originalText: String(text ?? ""), entries, parseErrors, parseWarnings, dirty: false };
}

function isSectionHeader(line, kind) {
  const trimmed = line.trim();
  if (kind === "pokemon") return trimmed.match(/^\[(\d+)\]$/);
  return trimmed.match(/^\[\s*([A-Z0-9_]+)\s*,\s*(\d+)\s*\]$/i);
}

function parseSectionDocument(kind, text) {
  const base = splitText(text);
  const entries = [];
  const parseErrors = [];
  const parseWarnings = [];
  let current = null;
  base.lines.forEach((rawLine, lineIndex) => {
    const header = isSectionHeader(rawLine, kind);
    if (header) {
      if (kind === "pokemon") {
        current = {
          kind,
          idNumber: Number.parseInt(header[1], 10),
          key: header[1],
          headerIndex: lineIndex,
          values: {},
          dirty: false,
        };
      } else {
        current = {
          kind,
          species: header[1].toUpperCase(),
          form: Number.parseInt(header[2], 10),
          key: `${header[1].toUpperCase()},${Number.parseInt(header[2], 10)}`,
          headerIndex: lineIndex,
          values: {},
          dirty: false,
        };
      }
      entries.push(current);
      return;
    }
    if (!current) return;
    const assignment = rawLine.match(/^\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (!assignment) return;
    current.values[assignment[1]] = assignment[2].trim();
  });
  for (const entry of entries) {
    if (kind === "pokemon") {
      entry.values.IdNumber = String(entry.idNumber);
      if (!entry.values.InternalName) parseErrors.push(`Sección [${entry.idNumber}]: falta InternalName.`);
    } else {
      entry.values.Species = entry.species;
      entry.values.Form = String(entry.form);
    }
  }
  return {
    ...base,
    kind,
    path: PATHS[kind],
    format: "section",
    originalText: String(text ?? ""),
    entries,
    parseErrors,
    parseWarnings,
    dirty: false,
  };
}

export function parseDocument(kind, text) {
  if (CSV_KINDS.has(kind)) return parseCsvDocument(kind, text);
  if (kind === "pokemon" || kind === "forms") return parseSectionDocument(kind, text);
  if (kind === "trainers") return parseTrainerDocument(text);
  throw new Error(`Tipo PBS no soportado: ${kind}`);
}

function serializeCsvEntry(kind, entry) {
  const columns = CSV_COLUMNS[kind];
  return columns.map((column) => {
    const forceQuote = column === "Description";
    return csvCell(entry.values[column] ?? "", forceQuote);
  }).join(",");
}

function serializeCsvDocument(document) {
  const byLine = new Map(document.entries.map((entry) => [entry.lineIndex, entry]));
  const deletedLines = new Set((document.deletedEntries ?? []).map((entry) => entry.lineIndex).filter((index) => index != null));
  const lines = document.lines.flatMap((line, lineIndex) => {
    if (deletedLines.has(lineIndex)) return [];
    const entry = byLine.get(lineIndex);
    return [entry?.dirty ? serializeCsvEntry(document.kind, entry) : line];
  });
  for (const entry of document.entries.filter((item) => item.lineIndex == null)) lines.push(serializeCsvEntry(document.kind, entry));
  return joinText(document, lines);
}

function sectionEntryLines(kind, entry, order, required) {
  const header = kind === "pokemon" ? `[${entry.idNumber}]` : `[${entry.species},${entry.form}]`;
  const lines = [header];
  for (const key of order) {
    const value = String(entry.values[key] ?? "").trim();
    if (!value && !required.includes(key)) continue;
    lines.push(`${key} = ${value}`);
  }
  return lines;
}

function serializeSectionDocument(document) {
  const schema = SCHEMAS[document.kind];
  const order = document.kind === "pokemon" ? POKEMON_ORDER : FORM_ORDER;
  const knownKeys = new Set(order);
  const dirtyHeaders = new Map(document.entries.filter((entry) => entry.dirty).map((entry) => [entry.headerIndex, entry]));
  const deletedHeaders = new Set((document.deletedEntries ?? []).map((entry) => entry.headerIndex).filter((index) => index != null));
  const lines = [];
  let currentDirty = null;
  let currentDeleted = false;

  document.lines.forEach((rawLine, lineIndex) => {
    const header = isSectionHeader(rawLine, document.kind);
    if (header) {
      currentDeleted = deletedHeaders.has(lineIndex);
      currentDirty = dirtyHeaders.get(lineIndex) ?? null;
      if (currentDeleted) return;
      const changedFormIdentity = document.kind === "forms" && currentDirty
        && (String(header[1]).toUpperCase() !== currentDirty.species || Number(header[2]) !== Number(currentDirty.form));
      lines.push(changedFormIdentity ? `[${currentDirty.species},${currentDirty.form}]` : rawLine);
      if (currentDirty) {
        for (const key of order) {
          const value = String(currentDirty.values[key] ?? "").trim();
          if (!value && !schema.required.includes(key)) continue;
          lines.push(`${key} = ${value}`);
        }
      }
      return;
    }
    if (currentDeleted) {
      if (!rawLine.trim() || /^\s*#/.test(rawLine)) lines.push(rawLine);
      return;
    }
    if (currentDirty) {
      const assignment = rawLine.match(/^\s*([A-Za-z][A-Za-z0-9_]*)\s*=/);
      if (assignment && knownKeys.has(assignment[1])) return;
    }
    lines.push(rawLine);
  });
  for (const entry of document.entries.filter((item) => item.headerIndex == null)) {
    lines.push("#-------------------------------", ...sectionEntryLines(document.kind, entry, order, schema.required));
  }
  return joinText(document, lines);
}

function trainerSectionLines(entry) {
  const { TrainerType, Name, Version, Items, LoseText } = entry.values;
  const header = Number(Version) > 0 ? `[${TrainerType},${csvCell(Name)},${Version}]` : `[${TrainerType},${csvCell(Name)}]`;
  const lines = [header];
  if (splitList(Items).length) lines.push(`Items = ${splitList(Items).join(",")}`);
  if (String(LoseText ?? "").length) lines.push(`LoseText = ${csvCell(LoseText, true)}`);
  for (const pokemon of entry.pokemon) {
    lines.push(`Pokemon = ${pokemon.Species},${pokemon.Level}`);
    for (const field of TRAINER_POKEMON_FIELDS) {
      let value = String(pokemon[field] ?? "").trim();
      if (!value) continue;
      if (["Shiny", "Shadow"].includes(field)) {
        if (!/^(yes|true|1)$/i.test(value)) continue;
        value = "yes";
      }
      lines.push(`    ${field} = ${value}`);
    }
  }
  return lines;
}

function serializeTrainerDocument(document) {
  const dirtyHeaders = new Map(document.entries.filter((entry) => entry.dirty).map((entry) => [entry.headerIndex, entry]));
  const deletedHeaders = new Set((document.deletedEntries ?? []).map((entry) => entry.headerIndex).filter((index) => index != null));
  const known = new Set(["Items", "LoseText", "Pokemon", ...TRAINER_POKEMON_FIELDS]);
  const lines = [];
  let currentDirty = false;
  let currentDeleted = false;
  document.lines.forEach((rawLine, lineIndex) => {
    if (/^\s*\[.*\]\s*$/.test(rawLine)) {
      currentDeleted = deletedHeaders.has(lineIndex);
      const dirty = dirtyHeaders.get(lineIndex);
      currentDirty = Boolean(dirty);
      if (currentDeleted) return;
      if (dirty) lines.push(...trainerSectionLines(dirty)); else lines.push(rawLine);
      return;
    }
    if (currentDeleted) {
      if (!rawLine.trim() || /^\s*#/.test(rawLine)) lines.push(rawLine);
      return;
    }
    if (currentDirty) {
      const assignment = rawLine.match(/^\s*([A-Za-z][A-Za-z0-9_]*)\s*=/);
      if (assignment && known.has(assignment[1])) return;
    }
    lines.push(rawLine);
  });
  for (const entry of document.entries.filter((item) => item.headerIndex == null)) {
    lines.push("#-------------------------------", ...trainerSectionLines(entry));
  }
  return joinText(document, lines);
}

export function serializeDocument(document) {
  if (!document.dirty && !document.entries.some((entry) => entry.dirty)) return document.originalText;
  if (document.format === "csv") return serializeCsvDocument(document);
  if (document.format === "trainers") return serializeTrainerDocument(document);
  return serializeSectionDocument(document);
}

export function parseTypes(text) {
  const values = [];
  let current = null;
  for (const rawLine of splitText(text).lines) {
    if (/^\s*\[\d+\]\s*$/.test(rawLine)) {
      if (current?.id) values.push(current);
      current = { id: "", name: "" };
      continue;
    }
    if (!current) continue;
    const assignment = rawLine.match(/^\s*(Name|InternalName)\s*=\s*(.*)$/);
    if (!assignment) continue;
    if (assignment[1] === "Name") current.name = assignment[2].trim();
    else current.id = assignment[2].trim();
  }
  if (current?.id) values.push(current);
  return values;
}

export function createReferences(documents, types = []) {
  const records = (kind) => (documents[kind]?.entries ?? []).map((entry) => ({
    id: kind === "pokemon" ? entry.values.InternalName : entry.values.InternalName,
    name: entry.values.Name || entry.values.FormName || entry.values.InternalName,
    entry,
  })).filter((record) => record.id);
  const refs = {
    pokemon: records("pokemon"),
    moves: records("moves"),
    items: records("items"),
    abilities: records("abilities"),
    types: types.map((type) => ({ id: type.id, name: type.name || type.id })),
    trainerTypes: records("trainerTypes"),
  };
  refs.balls = refs.items.filter((record) => record.entry.values.ItemType === "4");
  refs.functionCodes = [...new Set((documents.moves?.entries ?? []).map((entry) => entry.values.FunctionCode).filter(Boolean))]
    .sort().map((id) => ({ id, name: id }));
  return refs;
}

export function createEncounterPokemonReferences(documents, formLabel = (form) => `Form ${form}`) {
  const pokemon = documents.pokemon?.entries ?? [];
  const forms = documents.forms?.entries ?? [];
  const formsBySpecies = new Map();
  for (const entry of forms) {
    const species = String(entry.species || "").trim();
    const form = Number(entry.form);
    if (!species || !Number.isInteger(form) || form <= 0) continue;
    if (!formsBySpecies.has(species)) formsBySpecies.set(species, []);
    formsBySpecies.get(species).push(entry);
  }
  for (const entries of formsBySpecies.values()) entries.sort((a, b) => Number(a.form) - Number(b.form));
  const records = [];
  const includedSpecies = new Set();
  const appendSpecies = (species, baseEntry) => {
    if (!species || includedSpecies.has(species)) return;
    includedSpecies.add(species);
    const baseName = String(baseEntry?.values?.Name || species).trim() || species;
    if (baseEntry) records.push({ id: species, name: baseName, species, form: 0, entry: baseEntry, searchText: `${species} ${baseName}` });
    for (const entry of formsBySpecies.get(species) ?? []) {
      const form = Number(entry.form);
      const formName = String(entry.values.FormName || "").trim() || formLabel(form);
      const id = `${species}_${form}`;
      records.push({ id, name: `${baseName} (${formName})`, species, form, entry, searchText: `${id} ${species} ${baseName} ${formName} ${form}` });
    }
  };
  for (const entry of pokemon) appendSpecies(String(entry.values.InternalName || "").trim(), entry);
  for (const species of formsBySpecies.keys()) appendSpecies(species, null);
  return records;
}

export function splitList(value) {
  return String(value ?? "").split(",").map((item) => item.trim()).filter((item) => item !== "");
}

export function parsePairs(value) {
  const raw = String(value ?? "");
  const values = raw ? raw.split(",").map((item) => item.trim()) : [];
  const result = [];
  for (let index = 0; index < values.length; index += 2) result.push([values[index] ?? "", values[index + 1] ?? ""]);
  return result;
}

export function parseTriplets(value) {
  const raw = String(value ?? "");
  const values = raw ? raw.split(",").map((item) => item.trim()) : [];
  const result = [];
  for (let index = 0; index < values.length; index += 3) result.push([values[index] ?? "", values[index + 1] ?? "", values[index + 2] ?? ""]);
  return result;
}

function issue(level, kind, entry, field, message) {
  return { level, kind, key: entry.key, field, message };
}

function numberIssue(issues, kind, entry, field, options = {}) {
  const raw = String(entry.values[field] ?? "").trim();
  if (!raw && options.optional) return;
  const value = Number(raw);
  if (!Number.isFinite(value) || (!options.decimal && !Number.isInteger(value))) {
    issues.push(issue("error", kind, entry, field, `${field} debe ser ${options.decimal ? "un número" : "un entero"}.`));
    return;
  }
  if (options.min != null && value < options.min) issues.push(issue("error", kind, entry, field, `${field} no puede ser menor que ${options.min}.`));
  if (options.max != null && value > options.max) issues.push(issue("error", kind, entry, field, `${field} no puede ser mayor que ${options.max}.`));
}

function refSet(references, kind) {
  return new Set((references[kind] ?? []).map((record) => record.id));
}

function enumHas(options, value) {
  return options.some((option) => (Array.isArray(option) ? option[0] : option) === value);
}

function validateReference(issues, kind, entry, field, target, references, multiple = false) {
  const values = multiple ? splitList(entry.values[field]) : [String(entry.values[field] ?? "").trim()].filter(Boolean);
  const allowed = refSet(references, target);
  for (const value of values) {
    if (!allowed.has(value)) issues.push(issue("error", kind, entry, field, `${field} referencia ${value}, que no existe en ${target}.`));
  }
}

function validatePokemon(kind, entry, references, issues) {
  if (kind === "pokemon") {
    if (!ID_PATTERN.test(entry.values.InternalName || "")) issues.push(issue("error", kind, entry, "InternalName", "El ID interno debe usar mayúsculas, números o guiones bajos y comenzar por una letra."));
    for (const field of SCHEMAS.pokemon.required) {
      if (!String(entry.values[field] ?? "").trim()) issues.push(issue("error", kind, entry, field, `${field} es obligatorio.`));
    }
  } else if (!refSet(references, "pokemon").has(entry.species)) {
    issues.push(issue("error", kind, entry, "Species", `La forma pertenece a ${entry.species}, pero esa especie no existe.`));
  }

  validateReference(issues, kind, entry, "Type1", "types", references);
  validateReference(issues, kind, entry, "Type2", "types", references);
  validateReference(issues, kind, entry, "Abilities", "abilities", references, true);
  validateReference(issues, kind, entry, "HiddenAbility", "abilities", references, true);
  validateReference(issues, kind, entry, "TutorMoves", "moves", references, true);
  validateReference(issues, kind, entry, "EggMoves", "moves", references, true);
  for (const field of ["WildItemCommon", "WildItemUncommon", "WildItemRare", "Incense", "MegaStone"]) {
    validateReference(issues, kind, entry, field, "items", references);
  }
  validateReference(issues, kind, entry, "MegaMove", "moves", references);

  for (const field of ["BaseStats", "EffortPoints"]) {
    const raw = String(entry.values[field] ?? "").trim();
    if (!raw) continue;
    const stats = splitList(raw);
    if (stats.length !== 6 || stats.some((value) => !/^\d+$/.test(value))) {
      issues.push(issue("error", kind, entry, field, `${field} debe contener exactamente 6 enteros.`));
    } else if (field === "BaseStats" && stats.some((value) => Number(value) <= 0)) {
      issues.push(issue("error", kind, entry, field, "Todas las estadísticas base deben ser mayores que 0."));
    } else if (field === "EffortPoints" && stats.reduce((sum, value) => sum + Number(value), 0) > 6) {
      issues.push(issue("warning", kind, entry, field, "La suma de puntos de esfuerzo supera 6."));
    }
  }

  const movesRaw = String(entry.values.Moves ?? "");
  const moves = movesRaw ? movesRaw.split(",").map((value) => value.trim()) : [];
  if (moves.length % 2 !== 0) issues.push(issue("error", kind, entry, "Moves", "Moves debe contener pares nivel, movimiento."));
  for (let index = 0; index + 1 < moves.length; index += 2) {
    if (!/^\d+$/.test(moves[index])) issues.push(issue("error", kind, entry, "Moves", `El nivel ${moves[index]} no es válido.`));
    if (!moves[index + 1]) issues.push(issue("error", kind, entry, "Moves", "Falta elegir un movimiento."));
    else if (!refSet(references, "moves").has(moves[index + 1])) issues.push(issue("error", kind, entry, "Moves", `El movimiento ${moves[index + 1]} no existe.`));
  }

  const evolutionRaw = String(entry.values.Evolutions ?? "");
  const evolutions = evolutionRaw ? evolutionRaw.split(",").map((value) => value.trim()) : [];
  if (evolutions.length % 3 !== 0) issues.push(issue("error", kind, entry, "Evolutions", "Evolutions debe contener grupos destino, método, parámetro."));
  for (let index = 0; index + 2 < evolutions.length; index += 3) {
    const [target, method, parameter] = evolutions.slice(index, index + 3);
    if (!refSet(references, "pokemon").has(target)) issues.push(issue("error", kind, entry, "Evolutions", `La evolución ${target} no existe.`));
    if (!EVOLUTION_METHODS.includes(method)) issues.push(issue("warning", kind, entry, "Evolutions", `El método ${method} no es estándar de Essentials 19.1.`));
    const refKind = EVOLUTION_PARAMETER[method];
    if (refKind && parameter && !refSet(references, refKind).has(parameter)) issues.push(issue("error", kind, entry, "Evolutions", `El parámetro ${parameter} no existe en ${refKind}.`));
    if (INTEGER_EVOLUTIONS.has(method) && !/^\d+$/.test(parameter)) issues.push(issue("error", kind, entry, "Evolutions", `${method} necesita un parámetro entero.`));
  }

  for (const field of ["BaseEXP", "Rareness", "Happiness", "StepsToHatch", "Generation", "BattlerPlayerX", "BattlerPlayerY", "BattlerEnemyX", "BattlerEnemyY", "BattlerAltitude", "BattlerShadowX", "BattlerShadowSize", "PokedexForm", "UnmegaForm", "MegaMessage"]) {
    const raw = String(entry.values[field] ?? "").trim();
    if (!raw) continue;
    numberIssue(issues, kind, entry, field, { min: ["BattlerPlayerX", "BattlerPlayerY", "BattlerEnemyX", "BattlerEnemyY", "BattlerAltitude", "BattlerShadowX"].includes(field) ? undefined : 0, optional: true });
  }
  for (const field of ["Height", "Weight"]) {
    if (!String(entry.values[field] ?? "").trim()) continue;
    numberIssue(issues, kind, entry, field, { min: 0.1, decimal: true, optional: true });
  }
}

function validateCsv(kind, entry, references, issues) {
  const minimumId = kind === "trainerTypes" ? 0 : 1;
  if (!Number.isInteger(entry.idNumber) || entry.idNumber < minimumId) issues.push(issue("error", kind, entry, "IdNumber", `El número de ID debe ser un entero igual o mayor que ${minimumId}.`));
  if (!ID_PATTERN.test(entry.values.InternalName || "")) issues.push(issue("error", kind, entry, "InternalName", "El ID interno debe usar mayúsculas, números o guiones bajos y comenzar por una letra."));
  for (const field of fieldsFor(kind).filter((item) => item.required)) {
    if (!String(entry.values[field.key] ?? "").trim()) issues.push(issue("error", kind, entry, field.key, `${field.label} es obligatorio.`));
  }

  if (kind === "moves") {
    if (!/^[0-9A-Z]{1,3}$/i.test(entry.values.FunctionCode || "")) issues.push(issue("error", kind, entry, "FunctionCode", "El código de función debe contener de 1 a 3 caracteres alfanuméricos."));
    validateReference(issues, kind, entry, "Type", "types", references);
    if (!ENUMS.categories.includes(entry.values.Category)) issues.push(issue("error", kind, entry, "Category", "La categoría del movimiento no es válida."));
    if (!enumHas(ENUMS.targets, entry.values.Target)) issues.push(issue("error", kind, entry, "Target", "El objetivo del movimiento no es válido."));
    numberIssue(issues, kind, entry, "Power", { min: 0, max: 999 });
    numberIssue(issues, kind, entry, "Accuracy", { min: 0, max: 100 });
    numberIssue(issues, kind, entry, "TotalPP", { min: 1, max: 999 });
    numberIssue(issues, kind, entry, "EffectChance", { min: 0, max: 100 });
    numberIssue(issues, kind, entry, "Priority", { min: -7, max: 7 });
    if (entry.values.Category === "Status" && Number(entry.values.Power) !== 0) issues.push(issue("error", kind, entry, "Power", "Un movimiento de estado debe tener potencia 0."));
    if (entry.values.Category !== "Status" && Number(entry.values.Power) === 0) issues.push(issue("warning", kind, entry, "Category", "Essentials convertirá a Estado un movimiento con potencia 0."));
    const validFlags = new Set(MOVE_FLAGS.map(([flag]) => flag));
    for (const flag of entry.values.Flags || "") if (!validFlags.has(flag)) issues.push(issue("error", kind, entry, "Flags", `La propiedad ${flag} no existe en Essentials 19.1.`));
  } else if (kind === "items") {
    numberIssue(issues, kind, entry, "Pocket", { min: 1, max: 8 });
    numberIssue(issues, kind, entry, "Price", { min: 0, max: 999999 });
    numberIssue(issues, kind, entry, "FieldUse", { min: 0, max: 6 });
    numberIssue(issues, kind, entry, "BattleUse", { min: 0, max: 10 });
    numberIssue(issues, kind, entry, "ItemType", { min: 0, max: 12 });
    validateReference(issues, kind, entry, "Move", "moves", references);
    if (["3", "4", "6"].includes(entry.values.FieldUse) && !entry.values.Move) issues.push(issue("error", kind, entry, "Move", "Una MT, MO o TR debe enseñar un movimiento."));
  } else if (kind === "trainerTypes") {
    numberIssue(issues, kind, entry, "BaseMoney", { min: 0 });
    if (entry.values.SkillLevel) numberIssue(issues, kind, entry, "SkillLevel", { min: 0, optional: true });
    if (!new Set(["Male", "Female", "Mixed", "M", "F", "X", "0", "1", "2", ""]).has(entry.values.Gender)) {
      issues.push(issue("error", kind, entry, "Gender", "El género del tipo de entrenador no es válido en Essentials 19.1."));
    }
    if (entry.renamedFrom && entry.renamedFrom !== entry.values.InternalName) issues.push(issue("warning", kind, entry, "InternalName", `Se renombró ${entry.renamedFrom}; revisa los eventos y scripts que usen ese ID.`));
  }
}

function validateTrainer(entry, references, issues) {
  const kind = "trainers";
  validateReference(issues, kind, entry, "TrainerType", "trainerTypes", references);
  if (!String(entry.values.Name ?? "").trim()) issues.push(issue("error", kind, entry, "Name", "El nombre del entrenador es obligatorio."));
  numberIssue(issues, kind, entry, "Version", { min: 0 });
  validateReference(issues, kind, entry, "Items", "items", references, true);
  if (entry.renamedIdentity && (entry.renamedIdentity.trainerType !== entry.values.TrainerType || entry.renamedIdentity.name !== entry.values.Name)) {
    issues.push(issue("warning", kind, entry, "Name", `La identidad anterior era [${entry.renamedIdentity.trainerType},${entry.renamedIdentity.name}]; revisa los eventos que llamen a este combate.`));
  }
  if (!entry.pokemon.length) issues.push(issue("error", kind, entry, "Team", "El entrenador debe tener al menos un Pokémon."));
  if (entry.pokemon.length > 6) issues.push(issue("error", kind, entry, "Team", "Un equipo de entrenador no puede superar 6 Pokémon."));
  entry.pokemon.forEach((pokemon, index) => {
    const field = `Team.${index}`;
    if (!refSet(references, "pokemon").has(pokemon.Species)) issues.push(issue("error", kind, entry, field, `El Pokémon ${pokemon.Species || "sin especie"} no existe.`));
    const level = Number(pokemon.Level);
    if (!Number.isInteger(level) || level < 1 || level > ESSENTIALS_MAX_LEVEL) issues.push(issue("error", kind, entry, field, `El nivel de ${pokemon.Species || `Pokémon ${index + 1}`} debe ser un entero entre 1 y ${ESSENTIALS_MAX_LEVEL}.`));
    for (const move of splitList(pokemon.Moves)) if (!refSet(references, "moves").has(move)) issues.push(issue("error", kind, entry, field, `El movimiento ${move} no existe.`));
    if (splitList(pokemon.Moves).length > 4) issues.push(issue("error", kind, entry, field, `${pokemon.Species || `Pokémon ${index + 1}`} no puede tener más de 4 movimientos.`));
    if (pokemon.Ability && !refSet(references, "abilities").has(pokemon.Ability)) issues.push(issue("error", kind, entry, field, `La habilidad ${pokemon.Ability} no existe.`));
    if (pokemon.Item && !refSet(references, "items").has(pokemon.Item)) issues.push(issue("error", kind, entry, field, `El objeto ${pokemon.Item} no existe.`));
    if (pokemon.Ball && !refSet(references, "balls").has(pokemon.Ball)) issues.push(issue("error", kind, entry, field, `La Poké Ball ${pokemon.Ball} no existe o no está marcada como Poké Ball.`));
    if (pokemon.Gender && !["male", "female", "M", "F", "0", "1"].includes(pokemon.Gender)) issues.push(issue("error", kind, entry, field, `El género ${pokemon.Gender} no es válido.`));
    for (const statField of ["IV", "EV"]) {
      if (!pokemon[statField]) continue;
      const values = splitList(pokemon[statField]);
      if (values.length < 1 || values.length > 6 || values.some((value) => !/^\d+$/.test(value))) issues.push(issue("error", kind, entry, field, `${statField} debe contener entre 1 y 6 enteros.`));
      if (statField === "IV" && values.some((value) => Number(value) > 31)) issues.push(issue("error", kind, entry, field, "Los IV no pueden superar 31."));
      if (statField === "EV" && (values.some((value) => Number(value) > 252) || values.reduce((sum, value) => sum + Number(value), 0) > 510)) issues.push(issue("error", kind, entry, field, "Los EV deben respetar 252 por estadística y 510 en total."));
    }
    if (pokemon.Happiness && (!/^\d+$/.test(pokemon.Happiness) || Number(pokemon.Happiness) > 255)) issues.push(issue("error", kind, entry, field, "La felicidad debe estar entre 0 y 255."));
  });
}

export function validateWorkspace(documents, types = []) {
  const references = createReferences(documents, types);
  const issues = [];
  for (const kind of ["pokemon", "forms", "moves", "items", "abilities", "trainerTypes", "trainers"]) {
    const document = documents[kind];
    if (!document) continue;
    for (const message of document.parseErrors) issues.push({ level: "error", kind, key: "file", field: "file", message });
    for (const warning of document.parseWarnings ?? []) {
      const detail = typeof warning === "string" ? { key: "file", message: warning } : warning;
      issues.push({ level: "warning", kind, key: detail.key || "file", field: "file", message: detail.message });
    }
    const numberIds = new Set();
    const internalIds = new Set();
    for (const entry of document.entries) {
      if (kind === "trainers") {
        if (internalIds.has(entry.key)) issues.push(issue("error", kind, entry, "Name", `El entrenador ${entry.key} está duplicado.`));
        internalIds.add(entry.key);
      } else if (kind !== "forms") {
        if (numberIds.has(entry.idNumber)) issues.push(issue("error", kind, entry, "IdNumber", `El número ${entry.idNumber} está duplicado.`));
        numberIds.add(entry.idNumber);
        const internal = entry.values.InternalName;
        if (internalIds.has(internal)) issues.push(issue("error", kind, entry, "InternalName", `El ID ${internal} está duplicado.`));
        internalIds.add(internal);
      } else {
        if (internalIds.has(entry.key)) issues.push(issue("error", kind, entry, "Form", `La forma ${entry.key} está duplicada.`));
        internalIds.add(entry.key);
      }
      if (kind === "pokemon" || kind === "forms") validatePokemon(kind, entry, references, issues);
      else if (kind === "trainers") validateTrainer(entry, references, issues);
      else validateCsv(kind, entry, references, issues);
    }
  }
  return { references, issues, errors: issues.filter((item) => item.level === "error"), warnings: issues.filter((item) => item.level === "warning") };
}

export function issuesForEntry(validation, kind, entry) {
  return validation.issues.filter((item) => item.kind === kind && item.key === entry.key);
}

export function verifySerialization(document, serialized) {
  const reparsed = parseDocument(document.kind, serialized);
  if (reparsed.parseErrors.length) throw new Error(`La comprobación del archivo generado falló: ${reparsed.parseErrors.join(" ")}`);
  if (reparsed.entries.length !== document.entries.length) throw new Error("El archivo generado cambió la cantidad de entradas.");
  const reparsedByKey = new Map(reparsed.entries.map((entry) => [entryKey(document.kind, entry), entry]));
  const knownFields = document.format === "csv" ? CSV_COLUMNS[document.kind] : (document.kind === "pokemon" ? POKEMON_ORDER : (document.kind === "forms" ? FORM_ORDER : ["TrainerType", "Name", "Version", "Items", "LoseText"]));
  for (const entry of document.entries.filter((item) => item.dirty)) {
    const found = reparsedByKey.get(entryKey(document.kind, entry));
    if (!found) throw new Error(`La entrada ${entry.key} desapareció al volver a leer el archivo.`);
    for (const field of knownFields) {
      if (String(found.values[field] ?? "").trim() !== String(entry.values[field] ?? "").trim()) {
        throw new Error(`El campo ${field} de ${entry.key} no sobrevivió a la comprobación de lectura.`);
      }
    }
    if (document.kind === "trainers") {
      if (found.pokemon.length !== entry.pokemon.length) throw new Error(`El equipo de ${entry.key} cambió de tamaño al volver a leerlo.`);
      for (let index = 0; index < entry.pokemon.length; index += 1) {
        for (const field of ["Species", "Level", ...TRAINER_POKEMON_FIELDS]) {
          if (String(found.pokemon[index]?.[field] ?? "").trim() !== String(entry.pokemon[index]?.[field] ?? "").trim()) {
            throw new Error(`El campo ${field} del Pokémon ${index + 1} de ${entry.key} no sobrevivió a la comprobación.`);
          }
        }
      }
    }
  }
  return reparsed;
}

export async function loadDocuments(ctx) {
  const documents = {};
  for (const kind of ["pokemon", "forms", "moves", "items", "abilities", "trainerTypes", "trainers"]) {
    const text = await ctx.fs.readProjectFile(PATHS[kind]);
    documents[kind] = parseDocument(kind, text);
  }
  let types = [];
  try { types = parseTypes(await ctx.fs.readProjectFile(PATHS.types)); } catch { /* validation will report missing type references */ }
  return { documents, types, validation: validateWorkspace(documents, types) };
}

export function backupPath(path) {
  return path.replace(/\.txt$/i, ".maker-studio.bak");
}
