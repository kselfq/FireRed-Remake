import assert from "node:assert/strict";
import { applyTrainerPokemonReference, trainerAbilityGroups, trainerPokemonReferenceId } from "../src/pbs/trainer_team.js";

const records = [
  { id: "RATTATA", species: "RATTATA", form: 0 },
  { id: "RATTATA_1", species: "RATTATA", form: 1 },
];

const pokemon = { Species: "RATTATA", Level: "5" };
assert.equal(trainerPokemonReferenceId(pokemon), "RATTATA");
assert.deepEqual(applyTrainerPokemonReference(pokemon, "RATTATA_1", records), { changed: true, species: "RATTATA", form: "1" });
assert.equal(trainerPokemonReferenceId(pokemon), "RATTATA_1");
assert.deepEqual(applyTrainerPokemonReference(pokemon, "RATTATA", records), { changed: true, species: "RATTATA", form: "" });
assert.equal("Form" in pokemon, false);
assert.deepEqual(applyTrainerPokemonReference(pokemon, "CUSTOM_SPECIES_3", []), { changed: true, species: "CUSTOM_SPECIES", form: "3" });

const abilityRecords = [
  { id: "RATTATA", species: "RATTATA", form: 0, entry: { values: { Abilities: "RUNAWAY,GUTS", HiddenAbility: "HUSTLE" } } },
  { id: "RATTATA_1", species: "RATTATA", form: 1, entry: { values: { Abilities: "", HiddenAbility: "GLUTTONY" } } },
  { id: "RATTATA_2", species: "RATTATA", form: 2, entry: { values: { Abilities: "TOUGHCLAWS", HiddenAbility: "" } } },
];
assert.deepEqual(trainerAbilityGroups({ Species: "RATTATA", Form: "1" }, { encounterPokemon: abilityRecords }), [
  { label: "Habilidades principales", ids: ["RUNAWAY", "GUTS"] },
  { label: "Habilidades ocultas", ids: ["GLUTTONY"] },
]);
assert.deepEqual(trainerAbilityGroups({ Species: "RATTATA", Form: "2" }, { encounterPokemon: abilityRecords }), [
  { label: "Habilidades principales", ids: ["TOUGHCLAWS"] },
  { label: "Habilidades ocultas", ids: ["HUSTLE"] },
]);

console.log("Trainer Pokémon form reference tests passed.");
