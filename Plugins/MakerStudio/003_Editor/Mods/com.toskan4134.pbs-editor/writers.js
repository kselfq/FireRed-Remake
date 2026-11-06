/**
 * PBS file writers — structured data → PBS text.
 * Reconstructs the exact PBS format for each version.
 */

// ---------------------------------------------------------------------------
// Key=value section writers (v21 style)
// ---------------------------------------------------------------------------

// Evolutions round-trip. PE21 hand-written PBS uses repeatable singular
// `Evolution = SPECIES,METHOD,PARAM` lines (schema "^eeS"); the plural
// `Evolutions =` is the compiled form the game does NOT read back, so writing
// it makes evolutions vanish on the next recompile. `_evoFormat` records which
// form the source file used; default to the canonical multi-line form.
function writeEvolutions(value, format) {
  const items = value.split(',').map(s => s.trim());
  const trips = [];
  for (let i = 0; i < items.length; i += 3) {
    if (items[i]) trips.push([items[i], items[i + 1] || '', items[i + 2] || '']);
  }
  if (format === 'single') return `Evolutions = ${value}\n`;
  return trips.map(t => {
    const parts = t[2] !== '' ? [t[0], t[1], t[2]] : [t[0], t[1]];
    return `Evolution = ${parts.join(',')}\n`;
  }).join('');
}

// `_order` (captured at parse) holds the keys in their original file order so
// modeled and unmodeled (`_extra`) keys keep their positions instead of being
// reshuffled into schema order with extras dumped at the end. Falls back to
// schema order + extras for entries with no recorded order (e.g. newly added).
function writeSectionV21(header, fields, keys) {
  let out = `[${header}]\n`;
  const extra = fields._extra || {};
  const written = new Set();
  const emit = (k) => {
    if (written.has(k)) return;
    written.add(k);
    const v = (k in fields) ? fields[k] : extra[k];
    if (v === undefined || v === '') return;
    if (k === 'Evolutions') { out += writeEvolutions(v, fields._evoFormat); return; }
    out += `${k} = ${v}\n`;
  };
  if (fields._order) for (const k of fields._order) emit(k);
  for (const k of keys) emit(k);
  for (const k of Object.keys(extra)) emit(k);
  out += '\n';
  return out;
}

const SECTION_SEP = '#-------------------------------\n';

// ---------------------------------------------------------------------------
// Pokemon
// ---------------------------------------------------------------------------

const POKEMON_V21_KEYS = [
  'Name', 'Types', 'BaseStats', 'GenderRatio', 'GrowthRate',
  'BaseExp', 'EVs', 'CatchRate', 'Happiness', 'Abilities',
  'HiddenAbilities', 'Moves', 'TutorMoves', 'EggMoves',
  'EggGroups', 'Evolutions', 'HatchSteps', 'Height', 'Weight',
  'Color', 'Category', 'Habitat', 'Pokedex',
  'BattlerPlayerY', 'BattlerEnemyY', 'BattlerAltitude',
];

const POKEMON_V16_KEYS = [
  'Name', 'InternalName', 'Type1', 'Type2', 'BaseStats',
  'GenderRate', 'GrowthRate', 'BaseEXP', 'EffortPoints',
  'Rareness', 'Happiness', 'Abilities', 'HiddenAbility',
  'Moves', 'EggMoves', 'Compatibility', 'Evolutions',
  'StepsToHatch', 'Height', 'Weight', 'Color', 'Kind',
  'Habitat', 'Pokedex', 'BattlerPlayerY', 'BattlerEnemyY', 'BattlerAltitude',
];

// Separator-style files (canonical PE21) put `#---` directly before each
// section with no blank lines; blank-line-style files use blank lines and no
// separators. Detect from `_sep` and reproduce the matching layout.
function joinSectionsV21(entries, keys) {
  const sep = entries.length && entries[0]._sep;
  if (sep) {
    return entries.map(e => {
      const header = e._header + (e._excluded ? '!exclude' : '');
      const sec = writeSectionV21(header, e, keys).replace(/\n+$/, '\n');
      return SECTION_SEP + sec;
    }).join('');
  }
  return entries.map(e => {
    const header = e._header + (e._excluded ? '!exclude' : '');
    return writeSectionV21(header, e, keys);
  }).join('\n');
}

function writePokemonV21(entries) {
  return joinSectionsV21(entries, POKEMON_V21_KEYS);
}

function writePokemonV16(entries) {
  return entries.map(e => {
    // Normalize back to v16 fields
    const fields = { ...e };
    const types = (e.Types || '').split(',');
    if (types[0]) fields.Type1 = types[0].trim();
    if (types[1]) fields.Type2 = types[1].trim();
    if (e.CatchRate) fields.Rareness = e.CatchRate;
    if (e.Category) fields.Kind = e.Category;
    if (e.HiddenAbilities) fields.HiddenAbility = e.HiddenAbilities;
    if (e.EggGroups) fields.Compatibility = e.EggGroups;
    if (e.HatchSteps) fields.StepsToHatch = e.HatchSteps;
    if (e.EVs) fields.EffortPoints = e.EVs;
    if (e.BaseExp) fields.BaseEXP = e.BaseExp;

    let out = `[${e._id}]${e._excluded ? '!exclude' : ''}\n`;
    for (const k of POKEMON_V16_KEYS) {
      if (fields[k] !== undefined && fields[k] !== '') {
        out += `${k} = ${fields[k]}\n`;
      }
    }
    out += '\n';
    return out;
  }).join('\n');
}

// ---------------------------------------------------------------------------
// Pokemon Forms
// ---------------------------------------------------------------------------

const FORMS_V21_KEYS = [
  'FormName', 'Name', 'Types', 'BaseStats', 'Abilities',
  'HiddenAbilities', 'Moves', 'TutorMoves', 'EggMoves',
  'Evolutions', 'Height', 'Weight', 'Color', 'Pokedex',
  'MegaStone', 'Region',
];

function writePokemonFormsV21(entries) {
  return joinSectionsV21(entries, FORMS_V21_KEYS);
}

function writePokemonFormsV17(entries) {
  return entries.map(e => {
    let out = `#-------------------------------\n`;
    out += `[${e._header}]${e._excluded ? '!exclude' : ''}\n`;
    const keys = ['FormName', 'Name', 'Types', 'BaseStats', 'Abilities',
      'HiddenAbilities', 'Moves', 'TutorMoves', 'EggMoves', 'Evolutions',
      'Height', 'Weight', 'Color', 'Pokedex', 'MegaStone', 'Region'];
    for (const k of keys) {
      if (e[k] !== undefined && e[k] !== '') {
        out += `${k} = ${e[k]}\n`;
      }
    }
    out += '\n';
    return out;
  }).join('');
}

// ---------------------------------------------------------------------------
// Moves
// ---------------------------------------------------------------------------

function writeMovesV21(entries) {
  return entries.map(e => {
    const keys = ['Name', 'FunctionCode', 'Power', 'Type', 'Category',
      'Accuracy', 'TotalPP', 'EffectChance', 'Priority', 'Target',
      'Flags', 'Description'];
    return writeSectionV21(e._header + (e._excluded ? '!exclude' : ''), e, keys);
  }).join('\n');
}

function writeMovesV16(entries) {
  return entries.map(e => {
    const p = e._excluded ? `${e._id}!exclude` : e._id;
    return `${p},${e.InternalName},${e.Name},${e.FunctionCode},${e.Power},${e.Type},${e.Category},${e.Accuracy},${e.TotalPP},${e.EffectChance},${e.Priority},${e.Target},${e.Flags},"${e.Description}"`;
  }).join('\n') + '\n';
}

// ---------------------------------------------------------------------------
// Abilities
// ---------------------------------------------------------------------------

function writeAbilitiesV21(entries) {
  return entries.map(e => {
    return writeSectionV21(e._header + (e._excluded ? '!exclude' : ''), e, ['Name', 'Description']);
  }).join('\n');
}

function writeAbilitiesV16(entries) {
  return entries.map(e => {
    const id = e._excluded ? `${e._id}!exclude` : e._id;
    return `${id},${e.InternalName},${e.Name},"${e.Description}"`;
  }).join('\n') + '\n';
}

// ---------------------------------------------------------------------------
// Items
// ---------------------------------------------------------------------------

function writeItemsV21(entries) {
  return entries.map(e => {
    const keys = ['Name', 'NamePlural', 'PortionName', 'PortionNamePlural',
      'Pocket', 'Price', 'SellPrice', 'BPPrice', 'Description',
      'FieldUse', 'BattleUse', 'Flags', 'Consumable', 'ShowQuantity', 'Move'];
    return writeSectionV21(e._header + (e._excluded ? '!exclude' : ''), e, keys);
  }).join('\n');
}

function writeItemsV16(entries) {
  return entries.map(e => {
    const id = e._excluded ? `${e._id}!exclude` : e._id;
    return `${id},${e.InternalName},${e.Name},${e.NamePlural},${e.Pocket},${e.Price},"${e.Description}",${e.FieldUse},${e.BattleUse},${e.Flags},${e.Move || ''}`;
  }).join('\n') + '\n';
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

function writeTypesV21(entries) {
  return entries.map(e => {
    const keys = ['Name', 'IconPosition', 'IsPseudoType', 'IsSpecialType',
      'Weaknesses', 'Resistances', 'Immunities'];
    return writeSectionV21(e._header + (e._excluded ? '!exclude' : ''), e, keys);
  }).join('\n');
}

function writeTypesV16(entries) {
  return entries.map(e => {
    let out = `[${e._id}]${e._excluded ? '!exclude' : ''}\n`;
    const keys = ['InternalName', 'Name', 'IconPosition', 'IsPseudoType',
      'IsSpecialType', 'Weaknesses', 'Resistances', 'Immunities'];
    for (const k of keys) {
      if (e[k] !== undefined && e[k] !== '') out += `${k} = ${e[k]}\n`;
    }
    out += '\n';
    return out;
  }).join('\n');
}

// ---------------------------------------------------------------------------
// Encounters
// ---------------------------------------------------------------------------

function writeEncountersV21(entries) {
  return entries.map(e => {
    let out = `[${e._id}]${e._excluded ? '!exclude' : ''} # ${e.Name}\n`;
    for (const enc of (e._encounters || [])) {
      out += `${enc.type},${enc.density}\n`;
      for (const p of (enc.pokemons || [])) {
        out += `    ${p}\n`;
      }
    }
    out += '\n';
    return out;
  }).join('\n');
}

function writeEncountersV16(entries) {
  return entries.map((e, i) => {
    let out = (i > 0 ? '#' + '-'.repeat(40) + '\n' : '');
    out += `${e._id}${e._excluded ? '!exclude' : ''} # ${e.Name}\n`;
    if (e._densities) out += `${e._densities}\n`;
    for (const enc of (e._encounters || [])) {
      out += `${enc.type}\n`;
      for (const p of (enc.pokemons || [])) out += `${p}\n`;
    }
    out += '\n';
    return out;
  }).join('\n');
}

// ---------------------------------------------------------------------------
// Trainers
// ---------------------------------------------------------------------------

function writeTrainersV21(entries) {
  return entries.map(e => {
    let out = `[${e._header}]${e._excluded ? '!exclude' : ''}\n`;
    if (e.LoseText) out += `LoseText = ${e.LoseText}\n`;
    if (e.Items) out += `Items = ${e.Items}\n`;
    for (const p of (e._pokemon || [])) {
      out += `Pokemon = ${p.Pokemon}\n`;
      for (const [k, v] of Object.entries(p)) {
        if (k !== 'Pokemon' && v) out += `    ${k} = ${v}\n`;
      }
    }
    out += '\n';
    return out;
  }).join('\n');
}

function writeTrainersV16(entries) {
  return entries.map((e, i) => {
    let out = (i > 0 ? '#---' + '-'.repeat(30) + '\n' : '');
    out += `${e.TrainerType}${e._excluded ? '!exclude' : ''}\n`;
    out += `${e.Name}${e.Version ? ',' + e.Version : ''}\n`;
    const pokes = e._pokemon || [];
    const items = e.Items ? ',' + e.Items : '';
    out += `${pokes.length}${items}\n`;
    for (const p of pokes) out += `${p.Pokemon}\n`;
    return out;
  }).join('\n');
}

// ---------------------------------------------------------------------------
// Trainer Types
// ---------------------------------------------------------------------------

function writeTrainerTypesV21(entries) {
  return entries.map(e => {
    const keys = ['Name', 'BaseMoney', 'Gender', 'SkillLevel',
      'BattleBGM', 'VictoryBGM', 'IntroBGM'];
    return writeSectionV21(e._header + (e._excluded ? '!exclude' : ''), e, keys);
  }).join('\n');
}

function writeTrainerTypesV16(entries) {
  return entries.map(e => {
    return `${e._id},${e.InternalName},${e.Name},${e.BaseMoney},${e.BattleBGM || ''},${e.VictoryBGM || ''},${e.IntroBGM || ''},${e.Gender || ''},${e.SkillLevel || ''}`;
  }).join('\n') + '\n';
}

// ---------------------------------------------------------------------------
// Town Map
// ---------------------------------------------------------------------------

function writeTownMap(entries) {
  return entries.map(e => {
    let out = `[${e._id}]\n`;
    if (e.Name) out += `Name = ${e.Name}\n`;
    if (e.Filename) out += `Filename = ${e.Filename}\n`;
    // Write any Point entries
    for (const [k, v] of Object.entries(e)) {
      if (k.startsWith('Point')) out += `${k} = ${v}\n`;
    }
    out += '\n';
    return out;
  }).join('\n');
}

// ---------------------------------------------------------------------------
// TM
// ---------------------------------------------------------------------------

function writeTm(entries) {
  return entries.map(e => {
    let out = `[${e._header}]\n`;
    if (e.Pokemon) out += `${e.Pokemon}\n`;
    out += '\n';
    return out;
  }).join('\n');
}

// ---------------------------------------------------------------------------
// Dispatch table
// ---------------------------------------------------------------------------

const WRITERS = {
  pokemon:        { 16: writePokemonV16, 17: writePokemonV16, 21: writePokemonV21 },
  pokemon_forms:  { 17: writePokemonFormsV17, 21: writePokemonFormsV21 },
  moves:          { 16: writeMovesV16, 17: writeMovesV16, 21: writeMovesV21 },
  abilities:      { 16: writeAbilitiesV16, 17: writeAbilitiesV16, 21: writeAbilitiesV21 },
  items:          { 16: writeItemsV16, 17: writeItemsV16, 21: writeItemsV21 },
  types:          { 16: writeTypesV16, 17: writeTypesV16, 21: writeTypesV21 },
  encounters:     { 16: writeEncountersV16, 17: writeEncountersV16, 21: writeEncountersV21 },
  trainers:       { 16: writeTrainersV16, 17: writeTrainersV16, 21: writeTrainersV21 },
  trainer_types:  { 16: writeTrainerTypesV16, 17: writeTrainerTypesV16, 21: writeTrainerTypesV21 },
  town_map:       { 16: writeTownMap, 17: writeTownMap, 21: writeTownMap },
  tm:             { 16: writeTm, 17: writeTm },
};

export function writePbsFile(entries, fileType, version) {
  const writer = WRITERS[fileType]?.[version];
  if (!writer) return '';
  return writer(entries);
}
