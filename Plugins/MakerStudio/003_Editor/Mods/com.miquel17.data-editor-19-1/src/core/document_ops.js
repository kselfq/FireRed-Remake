function markDocument(document) {
  document.dirty = true;
}

export function removeDocumentEntry(document, entry) {
  const index = document.entries.indexOf(entry);
  if (index < 0) return false;
  document.entries.splice(index, 1);
  if (!entry.isNew) {
    document.deletedEntries ||= [];
    document.deletedEntries.push(entry);
  }
  document.dirty = document.entries.some((candidate) => candidate.dirty)
    || Boolean(document.deletedEntries?.length);
  return true;
}

export function trainerKey(values) {
  return `${values.TrainerType},${values.Name},${values.Version || "0"}`;
}

export function trainerGroup(entries, entry) {
  return entries
    .filter((candidate) => candidate.values.TrainerType === entry.values.TrainerType && candidate.values.Name === entry.values.Name)
    .sort((a, b) => Number(a.values.Version || 0) - Number(b.values.Version || 0));
}

function uniqueInternalName(entries, base) {
  const used = new Set(entries.map((entry) => entry.values.InternalName));
  let candidate = base;
  let suffix = 2;
  while (used.has(candidate)) candidate = `${base}_${suffix++}`;
  return candidate;
}

function nextNumericId(document, minimum = 1) {
  return document.entries.reduce((max, entry) => Math.max(max, Number(entry.idNumber) || 0), minimum - 1) + 1;
}

function createCsvEntry(document, internalBase, values) {
  const idNumber = nextNumericId(document);
  const internalName = uniqueInternalName(document.entries, internalBase);
  const entry = {
    kind: document.kind, idNumber, key: String(idNumber), lineIndex: null,
    values: { IdNumber: String(idNumber), InternalName: internalName, ...values },
    dirty: true, isNew: true,
  };
  document.entries.push(entry);
  markDocument(document);
  return entry;
}

export function createPokemon(documents) {
  const document = documents.pokemon;
  const idNumber = nextNumericId(document);
  const internalName = uniqueInternalName(document.entries, "NEW_POKEMON");
  const firstAbility = documents.abilities.entries[0]?.values.InternalName || "";
  const firstMove = documents.moves.entries.find((entry) => entry.values.InternalName === "TACKLE")?.values.InternalName
    || documents.moves.entries[0]?.values.InternalName || "";
  const entry = {
    kind: "pokemon", idNumber, key: String(idNumber), headerIndex: null,
    values: {
      IdNumber: String(idNumber), Name: "Nuevo Pokémon", InternalName: internalName, Type1: "NORMAL",
      BaseStats: "50,50,50,50,50,50", GenderRate: "Female50Percent", GrowthRate: "Medium", BaseEXP: "100",
      EffortPoints: "0,0,0,0,0,0", Rareness: "45", Happiness: "70", Abilities: firstAbility,
      Moves: firstMove ? `1,${firstMove}` : "", Compatibility: "Undiscovered", StepsToHatch: "5120",
      Height: "1.0", Weight: "10.0", Color: "Gray", Shape: "Head", Habitat: "None",
      Kind: "Nuevo", Pokedex: "Describe aquí este Pokémon.", Generation: "0",
    },
    dirty: true, isNew: true,
  };
  document.entries.push(entry);
  markDocument(document);
  return entry;
}

export function createForm(documents, species = "") {
  const document = documents.forms;
  const target = species || documents.pokemon.entries[0]?.values.InternalName || "";
  const form = nextFormNumber(document, target);
  const entry = {
    kind: "forms", species: target, form, key: `${target},${form}`, headerIndex: null,
    values: { Species: target, Form: String(form), FormName: `Forma ${form}` },
    dirty: true, isNew: true,
  };
  document.entries.push(entry);
  markDocument(document);
  return entry;
}

function nextFormNumber(document, species, ignoredEntry = null) {
  const forms = new Set(document.entries
    .filter((entry) => entry !== ignoredEntry && entry.species === species)
    .map((entry) => Number(entry.form)));
  let form = 1;
  while (forms.has(form)) form += 1;
  return form;
}

export function reassignFormSpecies(document, entry, species) {
  const target = String(species ?? "").trim().toUpperCase();
  if (!target || target === entry.species) return false;
  const occupied = document.entries.some((candidate) => candidate !== entry && candidate.species === target && Number(candidate.form) === Number(entry.form));
  if (occupied) entry.form = nextFormNumber(document, target, entry);
  entry.species = target;
  entry.key = `${target},${entry.form}`;
  entry.values.Species = target;
  entry.values.Form = String(entry.form);
  markDocument(document);
  return true;
}

export function createMove(documents) {
  return createCsvEntry(documents.moves, "NEW_MOVE", {
    Name: "Nuevo movimiento", FunctionCode: "000", Power: "0", Type: "NORMAL", Category: "Status",
    Accuracy: "0", TotalPP: "10", EffectChance: "0", Target: "None", Priority: "0", Flags: "",
    Description: "Describe aquí el efecto del movimiento.",
  });
}

export function createItem(documents) {
  return createCsvEntry(documents.items, "NEW_ITEM", {
    Name: "Nuevo objeto", NamePlural: "Nuevos objetos", Pocket: "1", Price: "0",
    Description: "Describe aquí el objeto.", FieldUse: "0", BattleUse: "0", ItemType: "0", Move: "",
  });
}

export function createAbility(documents) {
  return createCsvEntry(documents.abilities, "NEW_ABILITY", {
    Name: "Nueva habilidad", Description: "Describe aquí el efecto de la habilidad.",
  });
}

function uniqueTrainerName(entries, trainerType, base) {
  const used = new Set(entries.filter((entry) => entry.values.TrainerType === trainerType).map((entry) => entry.values.Name));
  let candidate = base;
  let suffix = 2;
  while (used.has(candidate)) candidate = `${base} ${suffix++}`;
  return candidate;
}

export function createTrainerType(document) {
  const idNumber = nextNumericId(document, 0);
  const internalName = uniqueInternalName(document.entries, "NEW_TRAINER_TYPE");
  const entry = {
    kind: "trainerTypes",
    idNumber,
    key: String(idNumber),
    lineIndex: null,
    values: {
      IdNumber: String(idNumber), InternalName: internalName, Name: "Nuevo tipo de entrenador", BaseMoney: "30",
      BattleBGM: "", VictoryME: "", IntroME: "", Gender: "Mixed", SkillLevel: "", SkillCode: "",
    },
    dirty: true,
    isNew: true,
  };
  document.entries.push(entry);
  markDocument(document);
  return entry;
}

export function createTrainer(documents, trainerType = "") {
  const type = trainerType || documents.trainerTypes.entries[0]?.values.InternalName || "";
  const name = uniqueTrainerName(documents.trainers.entries, type, "Nuevo entrenador");
  const entry = {
    kind: "trainers", key: "", headerIndex: null,
    values: { TrainerType: type, Name: name, Version: "0", Items: "", LoseText: "..." },
    pokemon: [{ Species: documents.pokemon.entries[0]?.values.InternalName || "BULBASAUR", Level: "5" }],
    dirty: true, isNew: true,
  };
  entry.key = trainerKey(entry.values);
  documents.trainers.entries.push(entry);
  markDocument(documents.trainers);
  return entry;
}

export function createTrainerVersion(document, source) {
  const siblings = trainerGroup(document.entries, source);
  const versions = new Set(siblings.map((entry) => Number(entry.values.Version || 0)));
  let version = 0;
  while (versions.has(version)) version += 1;
  const entry = {
    kind: "trainers", key: "", headerIndex: null,
    values: { ...source.values, Version: String(version) },
    pokemon: source.pokemon.map((pokemon) => ({ ...pokemon })),
    dirty: true, isNew: true,
  };
  entry.key = trainerKey(entry.values);
  document.entries.push(entry);
  markDocument(document);
  return entry;
}

export function renameTrainerType(documents, entry, nextId) {
  const previous = entry.values.InternalName;
  entry.renamedFrom ||= previous;
  entry.values.InternalName = nextId;
  entry.dirty = true;
  markDocument(documents.trainerTypes);
  for (const trainer of documents.trainers.entries) {
    if (trainer.values.TrainerType !== previous) continue;
    trainer.values.TrainerType = nextId;
    trainer.key = trainerKey(trainer.values);
    trainer.dirty = true;
    markDocument(documents.trainers);
  }
}

export function renameTrainerGroup(document, source, field, value) {
  const siblings = trainerGroup(document.entries, source);
  for (const entry of siblings) {
    entry.renamedIdentity ||= { trainerType: entry.values.TrainerType, name: entry.values.Name };
    entry.values[field] = value;
    entry.key = trainerKey(entry.values);
    entry.dirty = true;
  }
  markDocument(document);
  return siblings;
}
