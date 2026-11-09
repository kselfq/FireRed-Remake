const NO_EVOLUTION_PARAMETER = new Set([
  "None",
  "Happiness", "HappinessMale", "HappinessFemale", "HappinessDay", "HappinessNight", "MaxHappiness",
  "Trade", "TradeMale", "TradeFemale", "TradeDay", "TradeNight",
]);

const ENCOUNTER_TYPES_WITHOUT_TRIGGER_CHANCE = new Set([
  "OldRod", "GoodRod", "SuperRod", "HeadbuttLow", "HeadbuttHigh",
]);

function present(value) {
  return String(value ?? "").trim() !== "";
}

function truthy(value) {
  return /^(true|yes|1)$/i.test(String(value ?? "").trim());
}

export function evolutionParameterApplies(method) {
  return !NO_EVOLUTION_PARAMETER.has(String(method || "None"));
}

export function encounterTriggerChanceApplies(type) {
  return !ENCOUNTER_TYPES_WITHOUT_TRIGGER_CHANCE.has(String(type || ""));
}

export function pbsFieldDependency(kind, fieldKey, values = {}, effectiveValue = (key) => values[key]) {
  if (kind === "moves" && fieldKey === "Power" && String(values.Category) === "Status") {
    return { enabled: false, reason: "Los movimientos de estado no usan potencia." };
  }
  if ((kind === "pokemon" || kind === "forms") && fieldKey === "BattlerShadowX" && Number(effectiveValue("BattlerShadowSize")) === 0) {
    return { enabled: false, reason: "Sin sombra, su desplazamiento no se aplica." };
  }
  if (kind === "forms" && ["UnmegaForm", "MegaMessage"].includes(fieldKey) && !present(values.MegaStone) && !present(values.MegaMove)) {
    return { enabled: false, reason: "Solo se aplica a una forma activada por megapiedra o movimiento." };
  }
  return { enabled: true, reason: "" };
}

export function trainerPokemonFieldDependency(fieldKey, pokemon = {}) {
  if (fieldKey === "AbilityIndex" && present(pokemon.Ability)) {
    return { enabled: false, reason: "La habilidad elegida tiene prioridad sobre el índice." };
  }
  return { enabled: true, reason: "" };
}

export function metadataFieldDependency(fieldKey, values = {}) {
  if (fieldKey === "Bicycle" && truthy(values.BicycleAlways)) {
    return { enabled: false, reason: "La bicicleta obligatoria tiene prioridad." };
  }
  if (fieldKey === "MapSize" && !present(values.MapPosition)) {
    return { enabled: false, reason: "Requiere una posición en el mapa regional." };
  }
  return { enabled: true, reason: "" };
}
