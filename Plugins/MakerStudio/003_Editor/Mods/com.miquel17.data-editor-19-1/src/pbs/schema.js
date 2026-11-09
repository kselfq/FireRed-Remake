export const PATHS = {
  pokemon: "PBS/pokemon.txt",
  forms: "PBS/pokemonforms.txt",
  moves: "PBS/moves.txt",
  items: "PBS/items.txt",
  abilities: "PBS/abilities.txt",
  trainerTypes: "PBS/trainertypes.txt",
  trainers: "PBS/trainers.txt",
  types: "PBS/types.txt",
};

export const ESSENTIALS_MAX_LEVEL = 100;

export const STAT_NAMES = ["PS", "Ataque", "Defensa", "Velocidad", "At. Esp.", "Def. Esp."];

export const ENUMS = {
  gender: [["AlwaysMale", "Siempre macho"], ["AlwaysFemale", "Siempre hembra"], ["Genderless", "Sin género"], ["FemaleOneEighth", "12,5 % hembras"], ["Female25Percent", "25 % hembras"], ["Female50Percent", "50 % hembras"], ["Female75Percent", "75 % hembras"], ["FemaleSevenEighths", "87,5 % hembras"]],
  growth: [["Medium", "Medio"], ["Erratic", "Errático"], ["Fluctuating", "Fluctuante"], ["Parabolic", "Parabólico"], ["Fast", "Rápido"], ["Slow", "Lento"]],
  colors: [["Red", "Rojo"], ["Blue", "Azul"], ["Yellow", "Amarillo"], ["Green", "Verde"], ["Black", "Negro"], ["Brown", "Marrón"], ["Purple", "Morado"], ["Gray", "Gris"], ["White", "Blanco"], ["Pink", "Rosa"]],
  shapes: [["Head", "Solo cabeza"], ["Serpentine", "Serpentino"], ["Finned", "Con aletas"], ["HeadArms", "Cabeza y brazos"], ["HeadBase", "Cabeza y base"], ["BipedalTail", "Bípedo con cola"], ["HeadLegs", "Cabeza y piernas"], ["Quadruped", "Cuadrúpedo"], ["Winged", "Alado"], ["Multiped", "Muchas patas"], ["MultiBody", "Varios cuerpos"], ["Bipedal", "Bípedo"], ["MultiWinged", "Varias alas"], ["Insectoid", "Insectoide"]],
  habitats: [["None", "Sin hábitat"], ["Grassland", "Pradera"], ["Forest", "Bosque"], ["WatersEdge", "Orilla"], ["Sea", "Mar"], ["Cave", "Cueva"], ["Mountain", "Montaña"], ["RoughTerrain", "Terreno abrupto"], ["Urban", "Urbano"], ["Rare", "Raro"]],
  eggGroups: [["Undiscovered", "Desconocido"], ["Monster", "Monstruo"], ["Water1", "Agua 1"], ["Bug", "Bicho"], ["Flying", "Volador"], ["Field", "Campo"], ["Fairy", "Hada"], ["Grass", "Planta"], ["Humanlike", "Humanoide"], ["Water3", "Agua 3"], ["Mineral", "Mineral"], ["Amorphous", "Amorfo"], ["Water2", "Agua 2"], ["Ditto", "Ditto"], ["Dragon", "Dragón"]],
  categories: ["Physical", "Special", "Status"],
  targets: [["None", "Ninguno"], ["User", "Usuario"], ["NearAlly", "Aliado cercano"], ["UserOrNearAlly", "Usuario o aliado cercano"], ["UserAndAllies", "Usuario y aliados"], ["NearFoe", "Rival cercano"], ["RandomNearFoe", "Rival cercano al azar"], ["AllNearFoes", "Todos los rivales cercanos"], ["Foe", "Un rival"], ["AllFoes", "Todos los rivales"], ["NearOther", "Otro combatiente cercano"], ["AllNearOthers", "Todos los demás cercanos"], ["Other", "Otro combatiente"], ["AllBattlers", "Todos los combatientes"], ["UserSide", "Lado del usuario"], ["FoeSide", "Lado rival"], ["BothSides", "Ambos lados"]],
  // Compatibility note: keep this list and the Pocket validator in sync if
  // Settings.bag_pocket_names is extended or reordered by the game or a plugin.
  pockets: [
    ["1", "Objetos"], ["2", "Medicinas"], ["3", "Poké Balls"], ["4", "MTs / MOs"],
    ["5", "Bayas"], ["6", "Cartas"], ["7", "Obj. Combate"], ["8", "Obj. Claves"],
  ],
  fieldUse: [
    ["0", "No se puede usar"], ["1", "En un Pokémon"], ["2", "Uso directo"], ["3", "MT"],
    ["4", "MO"], ["5", "En Pokémon, reutilizable"], ["6", "TR"],
  ],
  battleUse: [
    ["0", "No se puede usar"], ["1", "En un Pokémon"], ["2", "En un movimiento"],
    ["3", "En un combatiente"], ["4", "En un rival"], ["5", "Uso directo"],
    ["6", "En Pokémon, reutilizable"], ["7", "En movimiento, reutilizable"],
    ["8", "En combatiente, reutilizable"], ["9", "En rival, reutilizable"], ["10", "Uso directo, reutilizable"],
  ],
  itemTypes: [
    ["0", "Normal"], ["1", "Carta"], ["2", "Carta con imágenes"], ["3", "Snag Ball"],
    ["4", "Poké Ball"], ["5", "Baya plantable"], ["6", "Objeto clave"], ["7", "Piedra evolutiva"],
    ["8", "Fósil"], ["9", "Bonguri"], ["10", "Gema de tipo"], ["11", "Abono"], ["12", "Megapiedra"],
  ],
  trainerGenders: [["Male", "Masculino"], ["Female", "Femenino"], ["Mixed", "Mixto"]],
  pokemonGenders: [["male", "Macho"], ["female", "Hembra"]],
};

export const EVOLUTION_METHODS = [
  "None", "Level", "LevelMale", "LevelFemale", "LevelDay", "LevelNight", "LevelMorning", "LevelAfternoon", "LevelEvening",
  "LevelNoWeather", "LevelSun", "LevelRain", "LevelSnow", "LevelSandstorm", "LevelCycling", "LevelSurfing", "LevelDiving",
  "LevelDarkness", "LevelDarkInParty", "AttackGreater", "AtkDefEqual", "DefenseGreater", "Silcoon", "Cascoon", "Ninjask", "Shedinja",
  "Happiness", "HappinessMale", "HappinessFemale", "HappinessDay", "HappinessNight", "HappinessMove", "HappinessMoveType",
  "HappinessHoldItem", "MaxHappiness", "Beauty", "HoldItem", "HoldItemMale", "HoldItemFemale", "DayHoldItem", "NightHoldItem",
  "HoldItemHappiness", "HasMove", "HasMoveType", "HasInParty", "Location", "Region", "Item", "ItemMale", "ItemFemale", "ItemDay",
  "ItemNight", "ItemHappiness", "Trade", "TradeMale", "TradeFemale", "TradeDay", "TradeNight", "TradeItem", "TradeSpecies",
];

export const EVOLUTION_PARAMETER = {
  HappinessMove: "moves", HappinessMoveType: "types", HappinessHoldItem: "items",
  HoldItem: "items", HoldItemMale: "items", HoldItemFemale: "items", DayHoldItem: "items", NightHoldItem: "items", HoldItemHappiness: "items",
  HasMove: "moves", HasMoveType: "types", HasInParty: "pokemon", Item: "items", ItemMale: "items", ItemFemale: "items",
  ItemDay: "items", ItemNight: "items", ItemHappiness: "items", TradeItem: "items", TradeSpecies: "pokemon",
};

export const MOVE_FLAGS = [
  ["a", "Contacto"], ["b", "Bloqueable con Protección"], ["c", "Reflejable con Capa Mágica"], ["d", "Robable con Robo"],
  ["e", "Copiable con Mov. Espejo"], ["f", "Activa Roca del Rey"], ["g", "Descongela al usuario"], ["h", "Alto índice crítico"],
  ["i", "Mordisco"], ["j", "Puñetazo"], ["k", "Sonido"], ["l", "Polvo"], ["m", "Pulso"], ["n", "Bomba"],
  ["o", "Danza"], ["p", "Corte"], ["q", "Viento"],
];

const text = (key, label, options = {}) => ({ key, label, type: "text", ...options });
const number = (key, label, options = {}) => ({ key, label, type: "number", ...options });
const ref = (key, label, reference, options = {}) => ({ key, label, type: "ref", reference, ...options });
const select = (key, label, options, config = {}) => ({ key, label, type: "select", options, ...config });
const list = (key, label, reference, options = {}) => ({ key, label, type: "list", reference, complex: true, ...options });

export const POKEMON_ORDER = [
  "Name", "InternalName", "Type1", "Type2", "BaseStats", "GenderRate", "GrowthRate", "BaseEXP", "EffortPoints", "Rareness", "Happiness",
  "Abilities", "HiddenAbility", "Moves", "TutorMoves", "EggMoves", "Compatibility", "StepsToHatch", "Height", "Weight", "Color", "Shape",
  "Habitat", "Kind", "Pokedex", "FormName", "Generation", "WildItemCommon", "WildItemUncommon", "WildItemRare", "BattlerPlayerX",
  "BattlerPlayerY", "BattlerEnemyX", "BattlerEnemyY", "BattlerAltitude", "BattlerShadowX", "BattlerShadowSize", "Evolutions", "Incense",
];

export const FORM_ORDER = [
  "FormName", "PokedexForm", "MegaStone", "MegaMove", "UnmegaForm", "MegaMessage", "Type1", "Type2", "BaseStats", "BaseEXP", "EffortPoints",
  "Rareness", "Happiness", "Abilities", "HiddenAbility", "Moves", "TutorMoves", "EggMoves", "Compatibility", "StepsToHatch", "Height", "Weight",
  "Color", "Shape", "Habitat", "Kind", "Pokedex", "Generation", "WildItemCommon", "WildItemUncommon", "WildItemRare", "BattlerPlayerX",
  "BattlerPlayerY", "BattlerEnemyX", "BattlerEnemyY", "BattlerAltitude", "BattlerShadowX", "BattlerShadowSize", "Evolutions",
];

const pokemonSections = (optional = false) => [
  { id: "identity", label: "Identidad", fields: [
    text("Name", "Nombre", { required: !optional, inherited: optional, group: "identity" }),
    text("InternalName", "ID interno", { required: !optional, protected: true, hiddenForForms: true, group: "identity" }),
    ref("Type1", "Tipo principal", "types", { inherited: optional, group: "types" }),
    ref("Type2", "Tipo secundario", "types", { inherited: optional, group: "types" }),
    text("FormName", "Nombre de forma", { inherited: optional }),
    select("GenderRate", "Proporción de género", ENUMS.gender, { inherited: optional }),
    select("GrowthRate", "Crecimiento", ENUMS.growth, { inherited: optional }),
    select("Color", "Color de Pokédex", ENUMS.colors, { inherited: optional }),
    select("Shape", "Forma corporal", ENUMS.shapes, { inherited: optional }),
    select("Habitat", "Hábitat", ENUMS.habitats, { inherited: optional }),
    text("Kind", "Categoría Pokédex", { inherited: optional }),
    text("Pokedex", "Entrada de Pokédex", { type: "textarea", wide: true, inherited: optional }),
    number("Generation", "Generación", { min: 0, inherited: optional }),
  ]},
  { id: "stats", label: "Estadísticas", fields: [
    { key: "BaseStats", label: "Estadísticas base", type: "stats", complex: true, inherited: optional },
    { key: "EffortPoints", label: "Puntos de esfuerzo", type: "stats", complex: true, ev: true, inherited: optional },
    number("BaseEXP", "Experiencia base", { min: 0, inherited: optional }),
    number("Rareness", "Ratio de captura", { min: 0, max: 255, inherited: optional }),
    number("Happiness", "Felicidad inicial", { min: 0, max: 255, inherited: optional }),
    number("Height", "Altura (m)", { min: 0.1, step: 0.1, inherited: optional }),
    number("Weight", "Peso (kg)", { min: 0.1, step: 0.1, inherited: optional }),
  ]},
  { id: "abilities", label: "Habilidades y objetos", fields: [
    list("Abilities", "Habilidades", "abilities", { inherited: optional }),
    list("HiddenAbility", "Habilidades ocultas", "abilities", { inherited: optional }),
    ref("WildItemCommon", "Objeto salvaje común", "items", { inherited: optional }),
    ref("WildItemUncommon", "Objeto salvaje poco común", "items", { inherited: optional }),
    ref("WildItemRare", "Objeto salvaje raro", "items", { inherited: optional }),
  ]},
  { id: "moves", label: "Movimientos y crianza", fields: [
    { key: "Moves", label: "Movimientos por nivel", type: "levelMoves", reference: "moves", complex: true, inherited: optional },
    list("TutorMoves", "Movimientos de tutor / MT", "moves", { inherited: optional }),
    list("EggMoves", "Movimientos huevo", "moves", { inherited: optional }),
    { key: "Compatibility", label: "Grupos huevo", type: "list", options: ENUMS.eggGroups, complex: true, inherited: optional },
    number("StepsToHatch", "Pasos para eclosionar", { min: 1, inherited: optional }),
  ]},
  { id: "evolution", label: "Evolución", fields: [
    { key: "Evolutions", label: "Evoluciones", type: "evolutions", complex: true, inherited: optional },
    ref("Incense", "Incienso para criar", "items", { inherited: optional, hiddenForForms: true }),
  ]},
  { id: "visual", label: "Posición en combate", fields: [
    number("BattlerPlayerX", "Jugador X", { inherited: optional }), number("BattlerPlayerY", "Jugador Y", { inherited: optional }),
    number("BattlerEnemyX", "Rival X", { inherited: optional }), number("BattlerEnemyY", "Rival Y", { inherited: optional }),
    number("BattlerAltitude", "Altitud frontal", { inherited: optional }), number("BattlerShadowX", "Sombra X", { inherited: optional }),
    number("BattlerShadowSize", "Tamaño de sombra", { min: 0, inherited: optional, rerenderOnChange: true }),
  ]},
];

export const SCHEMAS = {
  pokemon: {
    label: "Pokémon", file: PATHS.pokemon, order: POKEMON_ORDER, required: ["Name", "InternalName"],
    sections: pokemonSections(false),
  },
  forms: {
    label: "Formas", file: PATHS.forms, order: FORM_ORDER, required: [], sections: [
      { id: "form", label: "Forma especial", fields: [
        ref("Species", "Pokémon base", "pokemon", { required: true, wide: true }),
        text("FormName", "Nombre de forma", { inherited: true }), number("PokedexForm", "Forma mostrada en Pokédex", { min: 0, inherited: true }),
        ref("MegaStone", "Megapiedra", "items", { inherited: true, rerenderOnChange: true }), ref("MegaMove", "Movimiento de megaevolución", "moves", { inherited: true, rerenderOnChange: true }),
        number("UnmegaForm", "Forma al revertir", { min: 0, inherited: true }), number("MegaMessage", "Mensaje de megaevolución", { min: 0, inherited: true }),
      ]},
      ...pokemonSections(true).map((section) => ({ ...section, fields: section.fields.filter((field) => !field.hiddenForForms && field.key !== "Name" && field.key !== "FormName" && field.key !== "GenderRate" && field.key !== "GrowthRate" && field.key !== "Incense") })),
    ],
  },
  moves: {
    label: "Movimientos", file: PATHS.moves,
    sections: [
      { id: "move", label: "Movimiento", fields: [
        text("InternalName", "ID interno", { protected: true, required: true, group: "moveIdentity" }), text("Name", "Nombre", { required: true, group: "moveIdentity" }),
        text("FunctionCode", "Código de función", { reference: "functionCodes", required: true }),
        ref("Type", "Tipo", "types", { required: true, group: "moveKind" }), select("Category", "Categoría", ENUMS.categories, { required: true, group: "moveKind", rerenderOnChange: true }),
        number("Power", "Potencia", { min: 0, max: 999, required: true }),
        number("Accuracy", "Precisión", { min: 0, max: 100, required: true }), number("TotalPP", "PP", { min: 1, max: 999, required: true }),
        number("EffectChance", "Probabilidad de efecto (%)", { min: 0, max: 100, required: true }), number("Priority", "Prioridad", { min: -7, max: 7, required: true }),
        select("Target", "Objetivo", ENUMS.targets, { required: true }),
        { key: "Flags", label: "Propiedades", type: "flags", complex: true },
        text("Description", "Descripción", { type: "textarea", wide: true, required: true }),
      ]},
    ],
  },
  items: {
    label: "Objetos", file: PATHS.items,
    sections: [
      { id: "item", label: "Objeto", fields: [
        text("InternalName", "ID interno", { protected: true, required: true, group: "itemNames" }), text("Name", "Nombre", { required: true, group: "itemNames" }), text("NamePlural", "Nombre plural", { required: true, group: "itemNames" }),
        select("Pocket", "Bolsillo", ENUMS.pockets, { required: true, group: "itemStorage" }), number("Price", "Precio de compra", { min: 0, max: 999999, required: true, group: "itemStorage" }),
        select("FieldUse", "Uso fuera de combate", ENUMS.fieldUse, { required: true, group: "itemUse", rerenderOnChange: true }), select("BattleUse", "Uso en combate", ENUMS.battleUse, { required: true, group: "itemUse" }),
        select("ItemType", "Clase especial", ENUMS.itemTypes, { required: true, group: "machine" }), ref("Move", "Movimiento que enseña", "moves", { group: "machine", visibleWhen: { key: "FieldUse", values: ["3", "4", "6"] } }),
        text("Description", "Descripción", { type: "textarea", wide: true, required: true }),
      ]},
    ],
  },
  abilities: {
    label: "Habilidades", file: PATHS.abilities,
    sections: [
      { id: "ability", label: "Habilidad", fields: [
        text("InternalName", "ID interno", { protected: true, required: true }), text("Name", "Nombre", { required: true }),
        text("Description", "Descripción", { type: "textarea", wide: true, required: true }),
      ]},
    ],
  },
  trainerTypes: {
    label: "Tipos de entrenador", file: PATHS.trainerTypes,
    sections: [
      { id: "trainerType", label: "Tipo de entrenador", fields: [
        text("InternalName", "ID interno", { required: true, protected: true }), text("Name", "Nombre mostrado", { required: true }),
        number("BaseMoney", "Dinero base", { min: 0, required: true }), select("Gender", "Género", ENUMS.trainerGenders, { required: true }),
        ref("BattleBGM", "Música de combate", "bgm"), ref("VictoryME", "Música de victoria", "me"), ref("IntroME", "Música de introducción", "me"),
        number("SkillLevel", "Nivel de habilidad", { min: 0 }), text("SkillCode", "Código de habilidad", { type: "textarea", wide: true }),
      ]},
    ],
  },
  trainers: {
    label: "Entrenadores", file: PATHS.trainers,
    sections: [
      { id: "trainer", label: "Entrenador", fields: [
        ref("TrainerType", "Tipo de entrenador", "trainerTypes", { required: true }),
        text("Name", "Nombre", { required: true }),
        list("Items", "Objetos de combate", "items"), text("LoseText", "Texto al perder", { type: "textarea", wide: true }),
      ]},
      { id: "team", label: "Equipo Pokémon", fields: [{ key: "Team", label: "Equipo", type: "trainerTeam", complex: true }] },
    ],
  },
};

export function fieldsFor(kind) {
  return SCHEMAS[kind].sections.flatMap((section) => section.fields);
}
