import assert from "node:assert/strict";
import {
  encounterTriggerChanceApplies,
  evolutionParameterApplies,
  metadataFieldDependency,
  pbsFieldDependency,
  trainerPokemonFieldDependency,
} from "../src/pbs/field_dependencies.js";
import { fieldsFor } from "../src/pbs/schema.js";

assert.equal(encounterTriggerChanceApplies("Land"), true);
for (const type of ["OldRod", "GoodRod", "SuperRod", "HeadbuttLow", "HeadbuttHigh"]) {
  assert.equal(encounterTriggerChanceApplies(type), false, `${type} must not expose trigger chance`);
}

for (const method of ["None", "Happiness", "HappinessNight", "MaxHappiness", "Trade", "TradeFemale"]) {
  assert.equal(evolutionParameterApplies(method), false, `${method} must not expose a parameter`);
}
for (const method of ["Level", "Beauty", "HasMove", "Item", "TradeItem", "TradeSpecies"]) {
  assert.equal(evolutionParameterApplies(method), true, `${method} requires a parameter`);
}

assert.equal(pbsFieldDependency("moves", "Power", { Category: "Status" }).enabled, false);
assert.equal(pbsFieldDependency("moves", "Power", { Category: "Physical" }).enabled, true);
assert.equal(pbsFieldDependency("forms", "MegaMessage", {}).enabled, false);
assert.equal(pbsFieldDependency("forms", "MegaMessage", { MegaMove: "DRAGONASCENT" }).enabled, true);
assert.equal(pbsFieldDependency("forms", "UnmegaForm", { MegaStone: "VENUSAURITE" }).enabled, true);
assert.equal(pbsFieldDependency("pokemon", "BattlerShadowX", { BattlerShadowSize: "0" }).enabled, false);
assert.equal(pbsFieldDependency("forms", "BattlerShadowX", {}, (key) => key === "BattlerShadowSize" ? "2" : "").enabled, true);

assert.equal(trainerPokemonFieldDependency("AbilityIndex", { Ability: "OVERGROW" }).enabled, false);
assert.equal(trainerPokemonFieldDependency("AbilityIndex", {}).enabled, true);
assert.equal(metadataFieldDependency("Bicycle", { BicycleAlways: "true" }).enabled, false);
assert.equal(metadataFieldDependency("Bicycle", { BicycleAlways: "false" }).enabled, true);
assert.equal(metadataFieldDependency("MapSize", {}).enabled, false);
assert.equal(metadataFieldDependency("MapSize", { MapPosition: "0,12,8" }).enabled, true);

const itemMove = fieldsFor("items").find((field) => field.key === "Move");
assert.deepEqual(itemMove.visibleWhen, { key: "FieldUse", values: ["3", "4", "6"] });

console.log("Field dependency tests passed.");
