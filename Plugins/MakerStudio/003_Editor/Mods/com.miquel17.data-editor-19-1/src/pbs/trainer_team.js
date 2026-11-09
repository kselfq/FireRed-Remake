import { ENUMS, ESSENTIALS_MAX_LEVEL, STAT_NAMES } from "./schema.js";
import { splitList } from "./pbs19.js";
import { t } from "../ui/i18n.js";
import { dropdown, switchControl } from "../ui/ui_utils.js";

export const NATURES = [["HARDY", "Fuerte"], ["LONELY", "Huraña"], ["BRAVE", "Audaz"], ["ADAMANT", "Firme"], ["NAUGHTY", "Pícara"], ["BOLD", "Osada"], ["DOCILE", "Dócil"], ["RELAXED", "Plácida"], ["IMPISH", "Agitada"], ["LAX", "Floja"], ["TIMID", "Miedosa"], ["HASTY", "Activa"], ["SERIOUS", "Seria"], ["JOLLY", "Alegre"], ["NAIVE", "Ingenua"], ["MODEST", "Modesta"], ["MILD", "Afable"], ["QUIET", "Mansa"], ["BASHFUL", "Tímida"], ["RASH", "Alocada"], ["CALM", "Serena"], ["GENTLE", "Amable"], ["SASSY", "Grosera"], ["CAREFUL", "Cauta"], ["QUIRKY", "Rara"]];

const optionPairs = (options) => options.map((option) => Array.isArray(option) ? option : [option, option]);

function moveItem(items, index, target) {
  if (target < 0 || target >= items.length || target === index) return;
  const [item] = items.splice(index, 1);
  items.splice(target, 0, item);
}

export function trainerPokemonReferenceId(pokemon = {}) {
  return Number(pokemon.Form) > 0 ? `${pokemon.Species}_${pokemon.Form}` : String(pokemon.Species || "");
}

export function applyTrainerPokemonReference(pokemon, value, records = []) {
  const id = String(value || "");
  const record = records.find((candidate) => candidate.id === id);
  const fallback = id.match(/^(.*)_(\d+)$/);
  const species = String(record?.species || fallback?.[1] || id);
  const form = String(record?.form || fallback?.[2] || "");
  const changed = String(pokemon.Species ?? "") !== species || String(pokemon.Form ?? "") !== form;
  pokemon.Species = species;
  if (form && Number(form) > 0) pokemon.Form = form;
  else delete pokemon.Form;
  return { changed, species, form };
}

export function trainerAbilityGroups(pokemon = {}, referenceData = {}) {
  const pokemonRecords = referenceData.encounterPokemon ?? [];
  const selected = pokemonRecords.find((record) => record.id === trainerPokemonReferenceId(pokemon));
  const species = String(selected?.species || pokemon.Species || "");
  const base = pokemonRecords.find((record) => record.species === species && Number(record.form) === 0);
  const effectiveAbilities = (key) => {
    const ownValue = String(selected?.entry?.values?.[key] ?? "").trim();
    return splitList(ownValue || base?.entry?.values?.[key] || "");
  };
  return [
    { label: "Habilidades principales", ids: effectiveAbilities("Abilities") },
    { label: "Habilidades ocultas", ids: effectiveAbilities("HiddenAbility") },
  ];
}

export function renderTrainerTeam({
  body, entry, rerender, h, button, rowActions, createReferenceInput,
  setPokemonValue, markTrainerChanged, attachPokemonIcon, references,
}) {
  const labeled = (label, control, options = {}) => h("div", {
    className: `pepbs-team-field ${options.disabled ? "is-dependency-disabled" : ""}`.trim(),
    inert: options.disabled,
    "aria-disabled": options.disabled ? "true" : null,
    title: options.disabled && options.reason ? t(options.reason) : null,
  }, h("span", { text: t(label) }), control);
  const stats = (pokemon, key) => {
    const values = String(pokemon[key] ?? "").split(",");
    const wrap = h("div", { className: "pepbs-team-stats" });
    STAT_NAMES.forEach((name, index) => {
      const input = h("input", { className: "pepbs-input", type: "number", min: 0, max: key === "IV" ? 31 : 252, value: values[index] ?? "", placeholder: "—" });
      input.addEventListener("input", () => { values[index] = input.value; setPokemonValue(entry, pokemon, key, values.join(",").replace(/,+$/, "")); });
      wrap.appendChild(labeled(t(name), input));
    });
    return wrap;
  };

  const team = h("div", { className: "pepbs-team" });
  entry.pokemon.forEach((pokemon, index) => {
    const card = h("article", { className: "pepbs-team-card", "data-reorder-row": true });
    const art = h("div", { className: "pepbs-team-icon" }, h("span", { text: String(index + 1) }));
    attachPokemonIcon(art, pokemon.Species, pokemon.Form);
    const selectedSpecies = trainerPokemonReferenceId(pokemon);
    const species = createReferenceInput(selectedSpecies, "encounterPokemon", (value) => {
      const next = applyTrainerPokemonReference(pokemon, value, references().encounterPokemon);
      if (!next.changed) return;
      markTrainerChanged(entry);
      attachPokemonIcon(art, next.species, next.form);
    }, t("Elegir Pokémon…"), { showPokemonIcon: false });
    const level = h("input", { className: "pepbs-input", type: "number", min: 1, max: ESSENTIALS_MAX_LEVEL, value: pokemon.Level, placeholder: t("Nivel") });
    level.addEventListener("input", () => setPokemonValue(entry, pokemon, "Level", level.value));
    card.appendChild(h("div", { className: "pepbs-team-head" }, art,
      h("div", { className: "pepbs-team-identity" }, labeled("Pokémon", species), labeled("Nivel", level)),
      rowActions(
        index,
        entry.pokemon.length,
        (targetIndex) => { moveItem(entry.pokemon, index, targetIndex); markTrainerChanged(entry); rerender(); },
        () => { entry.pokemon.splice(index, 1); markTrainerChanged(entry); rerender(); },
      )));

    const moves = splitList(pokemon.Moves); while (moves.length < 4) moves.push("");
    const moveGrid = h("div", { className: "pepbs-team-moves" });
    moves.slice(0, 4).forEach((move, moveIndex) => moveGrid.appendChild(labeled(t(`Movimiento ${moveIndex + 1}`), createReferenceInput(move, "moves", (value) => {
      moves[moveIndex] = value;
      setPokemonValue(entry, pokemon, "Moves", moves.filter(Boolean).join(","));
    }, t("Vacío")))));

    const advanced = h("details", { className: "pepbs-team-advanced" }, h("summary", { text: t("Configuración avanzada") }));
    advanced.open = moves.some(Boolean);
    const grid = h("div", { className: "pepbs-team-grid" });
    const textControl = (key, attrs = {}) => {
      const input = h("input", { className: "pepbs-input", value: pokemon[key] ?? "", ...attrs });
      input.addEventListener("input", () => setPokemonValue(entry, pokemon, key, input.value));
      return input;
    };
    const selectControl = (key, options, emptyLabel = "— Automático —") => {
      const items = [["", t(emptyLabel)], ...optionPairs(options).map(([value, label]) => [value, t(label)])];
      return dropdown(pokemon[key] ?? "", items, (next) => setPokemonValue(entry, pokemon, key, next), { searchPlaceholder: t("Buscar opciones…"), noMatches: t("No hay coincidencias.") });
    };
    const abilityControl = createReferenceInput(pokemon.Ability, "abilities", (value) => {
      setPokemonValue(entry, pokemon, "Ability", value);
      setPokemonValue(entry, pokemon, "AbilityIndex", "");
    }, t("Por especie"), {
      groups: () => trainerAbilityGroups(pokemon, references()),
      remainderLabel: "Otras habilidades",
    });
    grid.append(
      labeled("Apodo", textControl("Name")),
      labeled("Género", selectControl("Gender", ENUMS.pokemonGenders)),
      labeled("Objeto", createReferenceInput(pokemon.Item, "items", (value) => setPokemonValue(entry, pokemon, "Item", value), t("Sin objeto"))),
      labeled("Habilidad", abilityControl),
      labeled("Naturaleza", selectControl("Nature", NATURES, "— Automática —")),
      labeled("Poké Ball", createReferenceInput(pokemon.Ball, "balls", (value) => setPokemonValue(entry, pokemon, "Ball", value), t("Por defecto"))),
      labeled("Felicidad", textControl("Happiness", { type: "number", min: 0, max: 255 })),
    );
    const toggles = h("div", { className: "pepbs-team-toggles" });
    for (const [key, label] of [["Shiny", "Shiny"], ["Shadow", "Pokémon oscuro"]]) {
      const check = switchControl(/^(yes|true|1)$/i.test(pokemon[key] ?? ""), (checked) => {
        setPokemonValue(entry, pokemon, key, checked ? "yes" : "");
      }, { label: t(label) });
      toggles.appendChild(h("label", {}, check, h("span", { text: t(label) })));
    }
    advanced.append(moveGrid, grid, toggles,
      h("div", { className: "pepbs-team-stat-block" }, h("strong", { text: "IV" }), stats(pokemon, "IV")),
      h("div", { className: "pepbs-team-stat-block" }, h("strong", { text: "EV" }), stats(pokemon, "EV")));
    card.appendChild(advanced);
    team.appendChild(card);
  });

  body.appendChild(team);
  const add = button(t("+ Añadir Pokémon"), () => {
    if (entry.pokemon.length >= 6) return;
    entry.pokemon.push({ Species: references().pokemon[0]?.id || "", Level: "5" });
    markTrainerChanged(entry);
    rerender();
  }, "pepbs-add");
  add.disabled = entry.pokemon.length >= 6;
  body.append(add, h("span", { className: "pepbs-team-count", text: t(`${entry.pokemon.length}/6 miembros`) }));
}
