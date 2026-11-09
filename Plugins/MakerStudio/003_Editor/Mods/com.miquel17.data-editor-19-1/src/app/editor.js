import { CSS } from "../ui/styles.js";
import { MOD_ASSET_ROOT } from "../core/mod_config.js";
import { writePlansAtomically } from "../core/save_transaction.js";
import { createProjectAssets } from "../infrastructure/project_assets.js";
import { createMapVisuals } from "../world/map_visuals.js";
import { button, dropdown, h, normalize, optionPairs, placeFloatingMenu, switchControl } from "../ui/ui_utils.js";
import { renderTrainerTeam as renderTrainerTeamEditor } from "../pbs/trainer_team.js";
import { createCategoryBadge, createTypeBadge } from "../ui/visual_badges.js";
import { createDomainIcon } from "../ui/domain_icons.js";
import { createCategoryPicker, createTypePicker } from "../ui/visual_pickers.js";
import {
  displayName,
  FALLBACK_MOD_VERSION,
  formatModVersion,
  internalName,
  KIND_META,
  PBS_KINDS,
  readModVersion,
  TAB_LABELS,
  WORLD_KINDS,
} from "./editor_metadata.js";
import { evolutionParameterApplies, pbsFieldDependency } from "../pbs/field_dependencies.js";
import { getLanguage, setLanguage, t } from "../ui/i18n.js";
import {
  buildEbdxWorkspace,
  ebdxBackupPath,
  loadEbdxWorkspace,
  serializeEbdxWorkspace,
  setEbdxValue,
  verifyEbdxSerialization,
} from "../ebdx/ebdx_data.js";
import { renderEbdxPositioner } from "../ebdx/ebdx_positioner.js";
import { createEbdxHistoryController } from "../ebdx/history_controller.js";
import {
  captureEntryBeforeDeletion,
  collectDocumentChanges,
  initializeDocumentTracking,
  refreshDocumentDirty,
  refreshDocumentsDirty,
  restoreAllDocumentChanges,
  restoreDocumentChange,
  trackNewEntry,
} from "../core/change_tracking.js";
import {
  createAbility,
  createForm,
  createItem,
  createMove,
  createPokemon,
  createTrainer,
  createTrainerType,
  createTrainerVersion,
  removeDocumentEntry,
  reassignFormSpecies,
  renameTrainerGroup,
  renameTrainerType,
  trainerGroup,
} from "../core/document_ops.js";
import {
  ENUMS,
  EVOLUTION_METHODS,
  EVOLUTION_PARAMETER,
  MOVE_FLAGS,
  SCHEMAS,
  STAT_NAMES,
} from "../pbs/schema.js";
import {
  backupPath,
  createEncounterPokemonReferences,
  createReferences,
  issuesForEntry,
  loadDocuments,
  parsePairs,
  parseTriplets,
  serializeDocument,
  splitList,
  validateWorkspace,
  verifySerialization,
} from "../pbs/pbs19.js";
import {
  createConnectionEntry,
  createEncounterEntry,
  createMetadataEntry,
  createTownMapRegion,
  deleteWorldEntry,
  loadWorldDocuments,
  refreshWorldEntry,
  restoreWorldDocument,
  serializeWorldDocument,
  validateWorldDocument,
  verifyWorldSerialization,
  worldBackupPath,
} from "../world/world_data.js";
import {
  renderConnectionsEditor,
  renderEncountersEditor,
  renderMetadataEditor,
  renderTownMapEditor,
  renderWorldPreview,
} from "../world/world_editors.js";

export function mountPbsEditor(ctx, host) {
  const state = {
    data: null,
    world: null,
    maps: [],
    ebdx: null,
    activeKind: "pokemon",
    pokemonMode: "pokemon",
    trainerMode: "trainers",
    selected: {},
    search: "",
    activeTabs: {},
    pendingLists: new Set(),
    previewToken: 0,
    saving: false,
    disposed: false,
    assets: { bgm: [], me: [], characters: [], pictures: [], battlebacks: [] },
    ebdxHistory: { undo: [], redo: [], transaction: null },
  changesOpen: false,
  connectionMapFilter: null,
  connectionAtlasFocusKey: null,
  connectionAtlasView: null,
  };
  const projectAssets = createProjectAssets(ctx);
  const mapVisuals = createMapVisuals(ctx, projectAssets);
  let ebdxCleanup = null;

  host.innerHTML = "";
  host.appendChild(h("style", { text: CSS }));
  const root = h("div", { className: "pepbs-root", lang: getLanguage() });
  root.innerHTML = `
    <header class="pepbs-toolbar">
        <div class="pepbs-brand"><div class="pepbs-mark"><img id="pepbs-mark-image" alt="" hidden /></div><div><div class="pepbs-title">Data Editor</div><div id="pepbs-version" class="pepbs-version">${formatModVersion()}</div></div></div>
      <div class="pepbs-spacer"></div>
      <div id="pepbs-language" class="pepbs-language" role="group" aria-label="Language">
        <span class="pepbs-language-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5"/><path d="M3.8 12h16.4M12 3.5c2.2 2.3 3.3 5.1 3.3 8.5S14.2 18.2 12 20.5M12 3.5C9.8 5.8 8.7 8.6 8.7 12s1.1 6.2 3.3 8.5"/></svg></span>
        <span id="pepbs-language-label" class="pepbs-visually-hidden">Language</span>
        <button type="button" data-language="en" title="English">EN</button>
        <button type="button" data-language="es" title="Español">ES</button>
      </div>
      <div id="pepbs-change-review" class="pepbs-change-review">
        <button id="pepbs-save-meta" class="pepbs-save-meta" type="button" disabled aria-expanded="false">Loading project…</button>
        <section id="pepbs-changes-panel" class="pepbs-changes-panel" hidden tabindex="-1" aria-label="Pending changes"></section>
      </div>
      <button id="pepbs-save" class="pepbs-btn pepbs-btn-primary" type="button" disabled>Save changes</button>
    </header>
    <main class="pepbs-body">
      <nav id="pepbs-rail" class="pepbs-rail"></nav>
      <section class="pepbs-catalog">
        <div id="pepbs-catalog-head" class="pepbs-catalog-head"></div>
        <div id="pepbs-list" class="pepbs-list"></div>
        <div id="pepbs-catalog-foot" class="pepbs-catalog-foot"></div>
      </section>
      <section id="pepbs-editor" class="pepbs-editor"><div id="pepbs-loading" class="pepbs-loading">Reading Essentials 19.1 PBS files…</div></section>
      <aside class="pepbs-inspector"><div id="pepbs-preview" class="pepbs-preview"></div><div id="pepbs-issues" class="pepbs-issues"></div></aside>
    </main>
    <footer id="pepbs-footer" class="pepbs-footer">No files have been modified.</footer>
    <div id="pepbs-notices" class="pepbs-notices" aria-live="polite" aria-atomic="true"></div>
    <div id="pepbs-dialogs" class="pepbs-dialogs"></div>`;
  host.appendChild(root);

  const els = {
    rail: root.querySelector("#pepbs-rail"), catalogHead: root.querySelector("#pepbs-catalog-head"),
    list: root.querySelector("#pepbs-list"), catalogFoot: root.querySelector("#pepbs-catalog-foot"),
    editor: root.querySelector("#pepbs-editor"), preview: root.querySelector("#pepbs-preview"), issues: root.querySelector("#pepbs-issues"),
    save: root.querySelector("#pepbs-save"), saveMeta: root.querySelector("#pepbs-save-meta"), changeReview: root.querySelector("#pepbs-change-review"),
    changesPanel: root.querySelector("#pepbs-changes-panel"), footer: root.querySelector("#pepbs-footer"),
    version: root.querySelector("#pepbs-version"), language: root.querySelector("#pepbs-language"), languageLabel: root.querySelector("#pepbs-language-label"),
    markImage: root.querySelector("#pepbs-mark-image"),
    notices: root.querySelector("#pepbs-notices"), dialogs: root.querySelector("#pepbs-dialogs"),
    loading: root.querySelector("#pepbs-loading"),
  };
  let modVersion = FALLBACK_MOD_VERSION;
  const refreshVersionLabel = () => { els.version.textContent = formatModVersion(modVersion); };
  const refreshLanguageControl = () => {
    els.language.querySelectorAll("[data-language]").forEach((button) => {
      const active = button.dataset.language === getLanguage();
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-pressed", String(active));
    });
  };
  void projectAssets.loadPersistent([`${MOD_ASSET_ROOT}/pikachu.png`]).then((url) => {
    if (!url || state.disposed || !els.markImage) return;
    els.markImage.src = url;
    els.markImage.hidden = false;
  });
  const changeLanguage = (nextLanguage) => {
    setLanguage(nextLanguage);
    root.lang = getLanguage();
    els.languageLabel.textContent = t("Idioma");
    els.language.setAttribute("aria-label", t("Idioma"));
    refreshLanguageControl();
    refreshVersionLabel();
    if (!state.data) {
      els.loading.textContent = t("Leyendo PBS de Essentials 19.1…");
      els.saveMeta.textContent = t("Cargando proyecto…");
      els.save.textContent = t("Guardar cambios");
      els.footer.textContent = t("Los archivos todavía no se han modificado.");
      return;
    }
    state.data.validation = validateWorkspace(state.data.documents, state.data.types);
    renderAll();
  };
  els.language.querySelectorAll("[data-language]").forEach((button) => button.addEventListener("click", () => changeLanguage(button.dataset.language)));
  refreshLanguageControl();
  els.languageLabel.textContent = t("Idioma");
  els.language.setAttribute("aria-label", t("Idioma"));
  refreshVersionLabel();
  void readModVersion(ctx).then((version) => {
    modVersion = version;
    if (!state.disposed) refreshVersionLabel();
  });
  els.loading.textContent = t("Leyendo PBS de Essentials 19.1…");
  els.saveMeta.textContent = t("Cargando proyecto…");
  els.save.textContent = t("Guardar cambios");
  els.footer.textContent = t("Los archivos todavía no se han modificado.");

  let noticeSequence = 0;
  function showNotice(message, level = "info", duration = level === "error" ? 8000 : 5200) {
    const id = ++noticeSequence;
    const notice = h("div", { className: `pepbs-notice is-${level}`, role: level === "error" ? "alert" : "status", "data-notice": id },
      h("span", { className: "pepbs-notice-mark", "aria-hidden": "true", text: level === "error" ? "!" : "✓" }),
      h("span", { className: "pepbs-notice-copy", text: message }),
      h("button", { type: "button", className: "pepbs-notice-close", text: "×", title: t("Cerrar notificación"), "aria-label": t("Cerrar notificación"), onClick: () => dismiss() }),
    );
    const dismiss = () => {
      if (!notice.isConnected || notice.classList.contains("is-leaving")) return;
      notice.classList.add("is-leaving");
      setTimeout(() => notice.remove(), 150);
    };
    els.notices.appendChild(notice);
    while (els.notices.children.length > 3) els.notices.firstElementChild.remove();
    if (duration) setTimeout(dismiss, duration);
  }

  function normalizeInternalId(value) {
    const normalized = String(value || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "")
      .toUpperCase().replace(/[^A-Z0-9_]+/g, "_").replace(/^_+|_+$/g, "");
    return /^[A-Z]/.test(normalized) ? normalized : normalized ? `ID_${normalized}` : "";
  }

  function suggestedInternalId(kind) {
    const bases = { pokemon: "NEW_POKEMON", moves: "NEW_MOVE", items: "NEW_ITEM", abilities: "NEW_ABILITY", trainerTypes: "NEW_TRAINER_TYPE" };
    const base = bases[kind] || "NEW_ENTRY";
    const used = new Set(entriesFor(kind).map((entry) => entry.values.InternalName));
    let candidate = base;
    let suffix = 2;
    while (used.has(candidate)) candidate = `${base}_${suffix++}`;
    return candidate;
  }

  function requestNewIdentity(kind) {
    return new Promise((resolve) => {
      const label = t(KIND_META[kind]?.label || kind);
      const backdrop = h("div", { className: "pepbs-dialog-backdrop" });
      const dialog = h("section", { className: "pepbs-dialog", role: "dialog", "aria-modal": "true", "aria-labelledby": "pepbs-create-title" });
      const nameInput = h("input", { className: "pepbs-input", type: "text", autocomplete: "off" });
      const idInput = h("input", { className: "pepbs-input", type: "text", value: suggestedInternalId(kind), autocomplete: "off", spellcheck: "false" });
      const error = h("div", { className: "pepbs-dialog-error", role: "status" });
      const confirm = button(t("Crear"), () => submit(), "pepbs-btn-primary");
      const cancel = button(t("Cancelar"), () => close(null), "pepbs-btn-quiet");
      const returnFocus = document.activeElement;
      let idWasEdited = false;
      const close = (result) => {
        backdrop.remove();
        if (!result && returnFocus instanceof HTMLElement && returnFocus.isConnected) returnFocus.focus();
        resolve(result);
      };
      const validate = () => {
        const name = nameInput.value.trim();
        const internalId = idInput.value.trim();
        let message = "";
        if (!name) message = t("El nombre es obligatorio.");
        else if (!/^[A-Za-z][A-Za-z0-9_]*$/.test(internalId)) message = t("El ID interno debe usar mayúsculas, números o guiones bajos y comenzar por una letra.");
        else if (entriesFor(kind).some((entry) => entry.values.InternalName === internalId)) message = t("Ese ID interno ya existe.");
        error.textContent = message;
        confirm.disabled = Boolean(message);
        return !message;
      };
      const submit = () => { if (validate()) close({ name: nameInput.value.trim(), internalId: idInput.value.trim() }); };
      nameInput.addEventListener("input", () => {
        if (!idWasEdited) idInput.value = normalizeInternalId(nameInput.value) || suggestedInternalId(kind);
        validate();
      });
      idInput.addEventListener("input", () => { idWasEdited = true; idInput.value = normalizeInternalId(idInput.value); validate(); });
      dialog.addEventListener("keydown", (event) => {
        if (event.key === "Escape") { event.preventDefault(); close(null); }
        else if (event.key === "Enter" && event.target !== confirm && event.target !== cancel) { event.preventDefault(); submit(); }
        else if (event.key === "Tab") {
          const controls = [nameInput, idInput, cancel, confirm].filter((control) => !control.disabled);
          const current = controls.indexOf(document.activeElement);
          const next = event.shiftKey ? (current <= 0 ? controls.length - 1 : current - 1) : (current >= controls.length - 1 ? 0 : current + 1);
          event.preventDefault(); controls[next].focus();
        }
      });
      dialog.append(
        h("div", { className: "pepbs-dialog-head" }, createDomainIcon(kind), h("div", {}, h("h2", { id: "pepbs-create-title", text: `${t("Crear registro")} · ${label}` }), h("p", { text: t("El ID se bloqueará al crear la entrada.") }))),
        h("div", { className: "pepbs-dialog-fields" },
          h("label", {}, h("span", { text: t("Nombre mostrado") }), nameInput),
          h("label", {}, h("span", { text: t("ID interno") }), idInput),
          error,
        ),
        h("div", { className: "pepbs-dialog-actions" }, cancel, confirm),
      );
      backdrop.appendChild(dialog);
      backdrop.addEventListener("pointerdown", (event) => { if (event.target === backdrop) close(null); });
      els.dialogs.appendChild(backdrop);
      validate();
      requestAnimationFrame(() => nameInput.focus());
    });
  }

  function requestNewForm() {
    return new Promise((resolve) => {
      let species = selectedEntry("forms")?.species
        || selectedEntry("pokemon")?.values.InternalName
        || state.data.documents.pokemon.entries[0]?.values.InternalName
        || "";
      const backdrop = h("div", { className: "pepbs-dialog-backdrop" });
      const dialog = h("section", { className: "pepbs-dialog", role: "dialog", "aria-modal": "true", "aria-labelledby": "pepbs-create-form-title" });
      const error = h("div", { className: "pepbs-dialog-error", role: "status" });
      const confirm = button(t("Crear"), () => submit(), "pepbs-btn-primary");
      const cancel = button(t("Cancelar"), () => close(null), "pepbs-btn-quiet");
      const returnFocus = document.activeElement;
      const validate = () => {
        const message = species ? "" : t("Debes elegir un Pokémon base.");
        error.textContent = message;
        confirm.disabled = Boolean(message);
        return !message;
      };
      const picker = createReferenceInput(species, "pokemon", (value) => { species = value; validate(); }, t("Elegir Pokémon…"), { allowEmpty: false });
      const close = (result) => {
        backdrop.remove();
        if (!result && returnFocus instanceof HTMLElement && returnFocus.isConnected) returnFocus.focus();
        resolve(result);
      };
      const submit = () => { if (validate()) close({ species }); };
      dialog.addEventListener("keydown", (event) => {
        if (event.key === "Escape") { event.preventDefault(); close(null); }
      });
      dialog.append(
        h("div", { className: "pepbs-dialog-head" }, createDomainIcon("forms"), h("div", {},
          h("h2", { id: "pepbs-create-form-title", text: t("Crear forma Pokémon") }),
          h("p", { text: t("Elige la especie base. El primer número de forma disponible se asignará automáticamente.") }))),
        h("div", { className: "pepbs-dialog-fields" },
          h("label", { className: "pepbs-dialog-field-wide" }, h("span", { text: t("Pokémon base") }), picker),
          error),
        h("div", { className: "pepbs-dialog-actions" }, cancel, confirm),
      );
      backdrop.appendChild(dialog);
      backdrop.addEventListener("pointerdown", (event) => { if (event.target === backdrop) close(null); });
      els.dialogs.appendChild(backdrop);
      validate();
      requestAnimationFrame(() => picker.querySelector('[role="combobox"]')?.focus());
    });
  }

  function requestEncounterMap() {
    return new Promise((resolve) => {
      const maps = state.maps.slice().sort((a, b) => Number(a.id) - Number(b.id));
      if (!maps.length) { resolve(null); return; }
      let mapId = Number(maps[0].id);
      const backdrop = h("div", { className: "pepbs-dialog-backdrop" });
      const dialog = h("section", { className: "pepbs-dialog", role: "dialog", "aria-modal": "true", "aria-labelledby": "pepbs-create-encounters-title" });
      const confirm = button(t("Crear"), () => submit(), "pepbs-btn-primary");
      const cancel = button(t("Cancelar"), () => close(null), "pepbs-btn-quiet");
      const returnFocus = document.activeElement;
      const picker = dropdown(mapId, maps.map((map) => [map.id, `${String(map.id).padStart(3, "0")} · ${map.name || `${t("Mapa")} ${map.id}`}`]), (next) => { mapId = Number(next); }, {
        label: t("Mapa"), searchable: true, searchPlaceholder: t("Buscar mapas…"),
      });
      const close = (result) => {
        backdrop.remove();
        if (!result && returnFocus instanceof HTMLElement && returnFocus.isConnected) returnFocus.focus();
        resolve(result);
      };
      const submit = () => close(maps.find((map) => Number(map.id) === mapId) || null);
      dialog.addEventListener("keydown", (event) => {
        if (event.key === "Escape") { event.preventDefault(); close(null); }
        else if (event.key === "Enter" && event.target !== cancel && event.target !== confirm) { event.preventDefault(); submit(); }
      });
      dialog.append(
        h("div", { className: "pepbs-dialog-head" }, createDomainIcon("encounters"), h("div", {},
          h("h2", { id: "pepbs-create-encounters-title", text: t("Crear encuentros") }),
          h("p", { text: t("Elige el mapa al que pertenecerán estos encuentros.") }))),
        h("div", { className: "pepbs-dialog-fields" },
          h("label", { className: "pepbs-dialog-field-wide" }, h("span", { text: t("Mapa") }), picker)),
        h("div", { className: "pepbs-dialog-actions" }, cancel, confirm),
      );
      backdrop.appendChild(dialog);
      backdrop.addEventListener("pointerdown", (event) => { if (event.target === backdrop) close(null); });
      els.dialogs.appendChild(backdrop);
      requestAnimationFrame(() => picker.querySelector('[role="combobox"]')?.focus());
    });
  }

  function actualKind() {
    if (state.activeKind === "ebdx") return "ebdx";
    if (state.activeKind === "pokemon") return state.pokemonMode;
    if (state.activeKind === "trainers") return state.trainerMode;
    return state.activeKind;
  }
  function isWorldKind(kind = actualKind()) { return WORLD_KINDS.includes(kind); }
  function documentFor(kind = actualKind()) { return kind === "ebdx" ? state.ebdx : isWorldKind(kind) ? state.world?.[kind] : state.data?.documents[kind]; }
  function entriesFor(kind = actualKind()) { return documentFor(kind)?.entries ?? []; }
  function selectedEntry(kind = actualKind()) {
    const key = state.selected[kind];
    return entriesFor(kind).find((entry) => entry.key === key) ?? null;
  }
  function dirtyDocuments() { return Object.values(state.data?.documents ?? {}).filter((document) => document.dirty || document.entries.some((entry) => entry.dirty)); }
  function dirtyWorldDocuments() { return Object.values(state.world ?? {}).filter((document) => document.dirty || document.entries.some((entry) => entry.dirty)); }
  function dirtyEbdxEntries() { return state.ebdx?.entries.filter((entry) => entry.dirty) ?? []; }
  function hasUnsavedChanges() { return dirtyDocuments().length > 0 || dirtyWorldDocuments().length > 0 || dirtyEbdxEntries().length > 0; }

  function references() {
    const base = createReferences(state.data?.documents ?? {}, state.data?.types ?? []);
    return {
      ...base,
      encounterPokemon: createEncounterPokemonReferences(state.data?.documents ?? {}, (form) => t(`Forma ${form}`)),
      bgm: state.assets.bgm.map((id) => ({ id, name: id })),
      me: state.assets.me.map((id) => ({ id, name: id })),
      pictures: state.assets.pictures.map((id) => ({ id, name: id })),
      characters: state.assets.characters.map((id) => ({ id, name: id })),
      battlebacks: state.assets.battlebacks.map((id) => ({ id, name: id })),
    };
  }

  function baseEntryFor(entry) {
    if (actualKind() !== "forms") return null;
    return state.data.documents.pokemon.entries.find((base) => base.values.InternalName === entry.species) ?? null;
  }

  function inheritedValue(entry, key) {
    return baseEntryFor(entry)?.values[key] ?? "";
  }

  function inheritedDisplayValue(field, value) {
    const rawValue = String(value ?? "");
    if (!normalize(rawValue)) return "";
    if (field.type === "select") {
      const option = optionPairs(field.options).find(([optionValue]) => String(optionValue) === rawValue);
      return t(option?.[1] ?? rawValue);
    }
    if (field.reference) {
      const record = (references()[field.reference] ?? []).find((candidate) => String(candidate.id) === rawValue);
      const label = record?.name ?? rawValue;
      return field.reference === "types" ? t(label) : label;
    }
    return rawValue;
  }

  let validationTimer = null;
  function updateValidationSoon() {
    clearTimeout(validationTimer);
    validationTimer = setTimeout(() => {
      if (!state.data || state.disposed) return;
      state.data.validation = validateWorkspace(state.data.documents, state.data.types);
      renderSaveState();
      refreshVisibleFieldIssues();
      renderIssues();
      renderFooter();
    }, 90);
  }

  function setValue(entry, key, value) {
    const next = String(value ?? "");
    if (String(entry.values[key] ?? "") === next) return;
    if (entry.kind === "forms" && key === "Species") {
      if (!reassignFormSpecies(state.data.documents.forms, entry, next)) return;
      refreshDocumentDirty(state.data.documents.forms);
      state.selected.forms = entry.key;
      state.data.validation = validateWorkspace(state.data.documents, state.data.types);
      renderAll();
      return;
    }
    if (entry.kind === "trainerTypes" && key === "InternalName") {
      const selectedTrainer = selectedEntry("trainers");
      renameTrainerType(state.data.documents, entry, next);
      refreshDocumentsDirty(state.data.documents);
      if (selectedTrainer) state.selected.trainers = selectedTrainer.key;
      renderCatalogList(); renderSaveState(); schedulePreview(); updateValidationSoon(); return;
    }
    if (entry.kind === "trainers" && ["TrainerType", "Name"].includes(key)) {
      renameTrainerGroup(state.data.documents.trainers, entry, key, next);
      refreshDocumentDirty(state.data.documents.trainers);
      state.selected.trainers = entry.key;
      renderCatalogList(); renderSaveState(); schedulePreview(); updateValidationSoon(); return;
    }
    const wasDirty = entry.dirty;
    entry.values[key] = next;
    refreshDocumentDirty(documentFor(entry.kind));
    renderSaveState();
    if (wasDirty !== entry.dirty || ["Name", "FormName", "Type", "Type1", "Type2"].includes(key)) renderCatalogList();
    schedulePreview();
    updateValidationSoon();
  }

  function markTrainerChanged(entry) {
    refreshDocumentDirty(documentFor("trainers"));
    renderSaveState(); renderCatalogList(); schedulePreview(); updateValidationSoon();
  }

  function setPokemonValue(entry, pokemon, key, value) {
    const next = String(value ?? "");
    if (String(pokemon[key] ?? "") === next) return;
    pokemon[key] = next;
    markTrainerChanged(entry);
  }

  const ebdxHistory = createEbdxHistoryController({
    state,
    root,
    setMetric: setEbdxValue,
    onSaveStateChanged: () => { renderSaveState(); renderFooter(); },
    onCatalogChanged: renderCatalogList,
    onRenderAll: renderAll,
  });
  const beginEbdxEdit = ebdxHistory.begin;
  const cancelEbdxEdit = ebdxHistory.cancel;
  const commitEbdxEdit = ebdxHistory.commit;
  const undoEbdx = ebdxHistory.undo;
  const redoEbdx = ebdxHistory.redo;

  function changeEbdxValue(entry, field, value) {
    return ebdxHistory.changeValue(entry, field, value, "Ajustar posición EBDX");
  }

  function resetEbdxEntry(entry) {
    return ebdxHistory.resetEntry(entry, "Restaurar posición EBDX");
  }

  async function applyEbdxToAllForms(entry) {
    const siblings = state.ebdx.entries.filter((candidate) => candidate.species === entry.species);
    if (siblings.length < 2) return;
    const proceed = await ctx.ui.showConfirmDialog({
      title: t("Aplicar posición a todas las formas"),
      message: t(`Se copiarán las cinco métricas de posición de ${entry.name} a sus ${siblings.length} formas. Solo cambiará PBS/EBDX/pokemon.txt.`),
      confirmLabel: t("Aplicar"),
    });
    if (!proceed) return;
    beginEbdxEdit(siblings, "Aplicar posición a todas las formas");
    for (const sibling of siblings) {
      for (const field of Object.keys(entry.values)) setEbdxValue(state.ebdx, sibling, field, entry.values[field]);
    }
    commitEbdxEdit();
    renderAll();
  }

  function deletionLabel(kind, entry) {
    if (kind === "trainers") return t(`Combate ${Number(entry.values.Version || 0) + 1}`);
    return displayName(kind, entry, state.data.documents);
  }

  async function deleteRecord(kind, entry) {
    const label = deletionLabel(kind, entry);
    const cascaded = [];
    let extra = "";
    if (kind === "pokemon") {
      const forms = state.data.documents.forms.entries.filter((form) => form.species === entry.values.InternalName);
      cascaded.push(...forms.map((form) => [state.data.documents.forms, form]));
      if (forms.length) extra = ` ${t("También se eliminarán {count} formas de esta especie.").replace("{count}", String(forms.length))}`;
    } else if (kind === "trainerTypes") {
      const battles = state.data.documents.trainers.entries.filter((battle) => battle.values.TrainerType === entry.values.InternalName);
      cascaded.push(...battles.map((battle) => [state.data.documents.trainers, battle]));
      if (battles.length) extra = ` ${t("También se eliminarán {count} combates que usan este tipo de entrenador.").replace("{count}", String(battles.length))}`;
    } else if (["moves", "items", "abilities"].includes(kind)) {
      extra = ` ${t("Las referencias que dependan de esta entrada deberán corregirse antes de guardar.")}`;
    }
    const proceed = await ctx.ui.showConfirmDialog({
      title: t(kind === "trainers" ? "Eliminar combate" : "Eliminar registro"),
      message: `${t("¿Eliminar '{name}'? Se aplicará al guardar; hasta entonces podrás restaurarlo desde Cambios pendientes.").replace("{name}", label)}${extra}`,
      confirmLabel: t("Eliminar"),
    });
    if (!proceed) return;
    for (const [document, candidate] of cascaded) {
      captureEntryBeforeDeletion(candidate);
      removeDocumentEntry(document, candidate);
    }
    captureEntryBeforeDeletion(entry);
    removeDocumentEntry(documentFor(kind), entry);
    state.selected[kind] = null;
    if (kind === "pokemon") state.selected.forms = null;
    if (kind === "trainerTypes") state.selected.trainers = null;
    state.data.validation = validateWorkspace(state.data.documents, state.data.types);
    renderAll();
    showNotice(t("'{name}' se eliminará al guardar.").replace("{name}", label));
  }

  function worldContext() {
    const species = new Set(state.data.documents.pokemon.entries.map((entry) => entry.values.InternalName));
    for (const entry of state.data.documents.forms.entries) {
      const form = Number(entry.form);
      if (entry.species && Number.isInteger(form) && form > 0) species.add(`${entry.species}_${form}`);
    }
    return {
      mapIds: new Set(state.maps.map((map) => map.id)),
      species,
      regionIds: new Set(state.world.townMap.entries.map((entry) => entry.regionId)),
      pictures: new Set(state.assets.pictures.map((name) => name.toLowerCase())),
      battlebacks: new Set(state.assets.battlebacks.map((name) => name.toLowerCase())),
    };
  }

  function changeWorldEntry(entry, rerender = false) {
    refreshWorldEntry(documentFor(entry.kind), entry);
    renderSaveState(); renderIssues(); renderFooter();
    if (rerender) { renderCatalogList(); renderDetail(); renderPreview(); }
    else { renderCatalogList(); schedulePreview(); }
  }

  async function deleteWorldRecord(kind, entry) {
    const name = worldEntryName(kind, entry);
    const proceed = await ctx.ui.showConfirmDialog({
      title: t("Eliminar registro"),
      message: t("¿Eliminar '{name}'? Se aplicará al guardar; hasta entonces podrás restaurarlo desde Cambios pendientes.").replace("{name}", name),
      confirmLabel: t("Eliminar"),
    });
    if (!proceed) return;
    deleteWorldEntry(documentFor(kind), entry);
    state.selected[kind] = null;
    renderAll();
  }

  function renderRail() {
    els.rail.innerHTML = "";
    els.rail.appendChild(h("div", { className: "pepbs-rail-label", text: t("Datos PBS") }));
    for (const kind of PBS_KINDS) {
      const meta = KIND_META[kind];
      const nav = h("button", {
        type: "button", className: `pepbs-nav ${state.activeKind === kind ? "is-active" : ""}`,
        onClick: () => {
          state.activeKind = kind; state.search = "";
          ensureSelection(); renderAll();
        },
      }, createDomainIcon(kind, "pepbs-nav-icon"), h("span", { text: t(meta.label) }));
      els.rail.appendChild(nav);
    }
    els.rail.appendChild(h("div", { className: "pepbs-rail-label pepbs-rail-label-secondary", text: t("Mundo") }));
    for (const kind of WORLD_KINDS) {
      const meta = KIND_META[kind];
      els.rail.appendChild(h("button", {
        type: "button", className: `pepbs-nav ${state.activeKind === kind ? "is-active" : ""}`,
        onClick: () => { state.activeKind = kind; state.search = ""; ensureSelection(); renderAll(); },
      }, createDomainIcon(kind, "pepbs-nav-icon"), h("span", { text: t(meta.label) })));
    }
    if (state.ebdx) {
      els.rail.appendChild(h("div", { className: "pepbs-rail-label pepbs-rail-label-secondary", text: t("Herramientas EBDX") }));
      const meta = KIND_META.ebdx;
      els.rail.appendChild(h("button", {
        type: "button",
        className: `pepbs-nav ${state.activeKind === "ebdx" ? "is-active" : ""}`,
        onClick: () => { state.activeKind = "ebdx"; state.search = ""; ensureSelection(); renderAll(); },
      }, createDomainIcon("ebdx", "pepbs-nav-icon"), h("span", { text: t(meta.label) })));
    }
  }

  function filteredEntries() {
    const query = state.search.trim().toLocaleLowerCase("es");
    const kind = actualKind();
    let entries = entriesFor();
    if (kind === "connections" && state.connectionMapFilter != null) {
      const mapId = Number(state.connectionMapFilter);
      entries = entries.filter((entry) => Number(entry.mapA) === mapId || Number(entry.mapB) === mapId);
    }
    if (kind === "trainers") {
      const groups = new Map();
      for (const entry of entries) {
        const key = `${entry.values.TrainerType}\u0000${entry.values.Name}`;
        const current = groups.get(key);
        if (!current || Number(entry.values.Version || 0) < Number(current.values.Version || 0)) groups.set(key, entry);
      }
      entries = [...groups.values()];
    }
    if (!query) return entries;
    return entries.filter((entry) => {
      let related = "";
      if (kind === "items" && entry.values.Move && ["3", "4", "6"].includes(String(entry.values.FieldUse))) {
        const move = state.data.documents.moves.entries.find((candidate) => candidate.values.InternalName === entry.values.Move);
        related = `${entry.values.Move} ${move?.values.Name || ""}`;
      }
      const haystack = `${entry.idNumber ?? ""} ${entry.species ?? ""} ${internalName(kind, entry)} ${isWorldKind(kind) ? worldEntryName(kind, entry) : displayName(kind, entry, state.data.documents)} ${related}`.toLocaleLowerCase("es");
      return haystack.includes(query);
    });
  }

  function worldEntryName(kind, entry) {
    if (kind === "townMap") return entry.name || `${t("Región")} ${entry.regionId}`;
    if (kind === "encounters") return entry.mapName || state.maps.find((map) => map.id === entry.mapId)?.name || `${t("Mapa")} ${entry.mapId}`;
    if (kind === "metadata") return entry.mapId === 0 ? t("Configuración global") : state.maps.find((map) => map.id === entry.mapId)?.name || `${t("Mapa")} ${entry.mapId}`;
    if (kind === "connections") return `${state.maps.find((map) => map.id === entry.mapA)?.name || entry.mapA} ↔ ${state.maps.find((map) => map.id === entry.mapB)?.name || entry.mapB}`;
    return displayName(kind, entry, state.data.documents);
  }

  function renderCatalogHead() {
    els.catalogHead.innerHTML = "";
    const kind = actualKind();
    const all = entriesFor(kind).length;
    const visible = filteredEntries().length;
    const count = kind === "connections" && state.connectionMapFilter != null
      ? `${visible} / ${all}`
      : t(kind === "trainers" ? `${visible} entrenadores · ${all} combates` : kind === "ebdx" ? `${all} sprites` : `${all} registros`);
    const schemaLabel = (kind === "ebdx" || isWorldKind(kind)) ? KIND_META[kind].label : SCHEMAS[kind].label;
    const heading = h("span", { className: "pepbs-catalog-heading" }, h("strong", { text: t(schemaLabel) }), h("span", { text: count }));
    const title = h("div", { className: "pepbs-catalog-title" }, heading);
    const titleActions = h("span", { className: "pepbs-catalog-actions" });
    const creationLabels = { pokemon: "+ Pokémon", forms: "+ Forma", moves: "+ Movimiento", items: "+ Objeto", abilities: "+ Habilidad", trainers: "+ Entrenador", trainerTypes: "+ Tipo" };
    if (creationLabels[kind]) {
      const createButton = button(t(creationLabels[kind]), async () => {
        const documents = state.data.documents;
        const identityKinds = ["pokemon", "moves", "items", "abilities", "trainerTypes"];
        const identity = identityKinds.includes(kind) ? await requestNewIdentity(kind) : null;
        const formIdentity = kind === "forms" ? await requestNewForm() : null;
        if (identityKinds.includes(kind) && !identity) return;
        if (kind === "forms" && !formIdentity) return;
        const creators = {
        pokemon: () => createPokemon(documents),
        forms: () => createForm(documents, formIdentity?.species),
        moves: () => createMove(documents),
        items: () => createItem(documents),
        abilities: () => createAbility(documents),
        trainers: () => createTrainer(documents, selectedEntry("trainers")?.values.TrainerType),
        trainerTypes: () => createTrainerType(documents.trainerTypes),
        };
        const entry = creators[kind]();
        if (identity) {
          entry.values.Name = identity.name;
          entry.values.InternalName = identity.internalId;
        }
      trackNewEntry(documentFor(kind), entry);
      state.selected[kind] = entry.key; state.search = ""; state.activeTabs[kind] = SCHEMAS[kind].sections[0].id;
      state.data.validation = validateWorkspace(state.data.documents, state.data.types); renderAll();
      }, "pepbs-btn-compact pepbs-create-record");
      createButton.prepend(createDomainIcon(kind, "pepbs-button-icon"));
      titleActions.appendChild(createButton);
    }
    const worldCreationLabels = { townMap: "+ Región", encounters: "+ Mapa", metadata: "+ Mapa", connections: "+ Conexión" };
    if (worldCreationLabels[kind]) {
      const createButton = button(t(worldCreationLabels[kind]), async () => {
      const document = documentFor(kind);
      if (kind === "encounters") {
        const map = await requestEncounterMap();
        if (!map) return;
        const entry = createEncounterEntry(document, Number(map.id), map.name || "");
        state.selected[kind] = entry.key; state.search = ""; renderAll();
        return;
      }
      const firstMap = state.maps.find((map) => !document.entries.some((entry) => entry.mapId === map.id)) || state.maps[0];
      const creators = {
        townMap: () => createTownMapRegion(document),
        metadata: () => createMetadataEntry(document, firstMap?.id || 1),
        connections: () => createConnectionEntry(document, state.maps[0]?.id || 1, state.maps[1]?.id || state.maps[0]?.id || 1),
      };
      const entry = creators[kind]();
      state.selected[kind] = entry.key; state.search = ""; renderAll();
      }, "pepbs-btn-compact pepbs-create-record");
      createButton.prepend(createDomainIcon(kind, "pepbs-button-icon"));
      titleActions.appendChild(createButton);
    }
    title.appendChild(titleActions); els.catalogHead.appendChild(title);
    if (state.activeKind === "pokemon") {
      const segmented = h("div", { className: "pepbs-segmented" });
      for (const [mode, label] of [["pokemon", "Especies"], ["forms", "Formas"]]) {
        segmented.appendChild(h("button", {
          type: "button", className: state.pokemonMode === mode ? "is-active" : "", text: t(label),
          onClick: () => { state.pokemonMode = mode; state.search = ""; ensureSelection(); renderAll(); },
        }));
      }
      els.catalogHead.appendChild(segmented);
    } else if (state.activeKind === "trainers") {
      const segmented = h("div", { className: "pepbs-segmented" });
      for (const [mode, label] of [["trainers", "Equipos"], ["trainerTypes", "Tipos"]]) {
        segmented.appendChild(h("button", {
          type: "button", className: state.trainerMode === mode ? "is-active" : "", text: t(label),
          onClick: () => { state.trainerMode = mode; state.search = ""; ensureSelection(); renderAll(); },
        }));
      }
      els.catalogHead.appendChild(segmented);
    }
    if (kind === "connections" && state.connectionMapFilter != null) {
      const mapId = Number(state.connectionMapFilter);
      const mapName = state.maps.find((map) => Number(map.id) === mapId)?.name || `${t("Mapa")} ${mapId}`;
      els.catalogHead.appendChild(h("button", {
        type: "button",
        className: "pepbs-connection-filter",
        title: t("Quitar filtro de mapa"),
        "aria-label": `${t("Quitar filtro de mapa")}: ${mapName}`,
        onClick: () => applyConnectionMapFilter(null),
      }, h("span", { className: "pepbs-connection-filter-label", text: t("Conexiones de") }), h("strong", { text: `${mapName} · ${String(mapId).padStart(3, "0")}` }), h("span", { className: "pepbs-connection-filter-close", "aria-hidden": "true", text: "×" })));
    }
    const wrap = h("div", { className: "pepbs-search-wrap" });
    const localizedLabel = t(schemaLabel).toLocaleLowerCase(getLanguage());
    const searchPlaceholder = kind === "items" ? t("Buscar objetos o movimientos…") : t(`Buscar ${localizedLabel}…`);
    const search = h("input", { className: "pepbs-search", type: "search", placeholder: searchPlaceholder, value: state.search, "aria-label": t("Buscar registros") });
    search.addEventListener("input", () => { state.search = search.value; renderCatalogList(); });
    wrap.appendChild(search); els.catalogHead.appendChild(wrap);
  }

  function renderCatalogList() {
    els.list.innerHTML = "";
    const kind = actualKind();
    const filtered = filteredEntries();
    for (const entry of filtered) {
      const active = state.selected[kind] === entry.key;
      const activeTrainer = kind === "trainers" ? selectedEntry("trainers") : null;
      const groupIsActive = kind === "trainers" && activeTrainer && activeTrainer.values.TrainerType === entry.values.TrainerType && activeTrainer.values.Name === entry.values.Name;
      const row = h("button", {
        type: "button", className: `pepbs-entry ${kind === "trainers" ? "has-no-index" : ""} ${active || groupIsActive ? "is-active" : ""}`,
        onClick: () => {
          state.selected[kind] = groupIsActive ? activeTrainer.key : entry.key;
          if (kind === "connections") {
            state.connectionMapFilter = null;
            state.connectionAtlasFocusKey = state.selected.connections;
            state.connectionAtlasView = null;
          }
          renderCatalogList(); renderDetail(); renderPreview(); renderIssues();
        },
      });
      if (kind !== "trainers") {
        const index = kind === "forms" ? `F${entry.form}` : kind === "townMap" ? String(entry.regionId) : ["encounters", "metadata"].includes(kind) ? String(entry.mapId).padStart(3, "0") : kind === "connections" ? String(entry.order + 1) : String(entry.idNumber).padStart(3, "0");
        row.appendChild(h("span", { className: "pepbs-entry-num", text: index }));
      }
      let secondary = internalName(kind, entry);
      if (kind === "items" && entry.values.Move && ["3", "4", "6"].includes(String(entry.values.FieldUse))) {
        const move = state.data.documents.moves.entries.find((candidate) => candidate.values.InternalName === entry.values.Move);
        secondary += ` · ${entry.values.Move}${move?.values.Name ? ` · ${move.values.Name}` : ""}`;
        row.classList.add("is-machine");
      }
      row.appendChild(h("span", { className: "pepbs-entry-main" },
        h("span", { className: "pepbs-entry-name", text: isWorldKind(kind) ? worldEntryName(kind, entry) : displayName(kind, entry, state.data.documents) }),
        h("span", { className: "pepbs-entry-id", text: secondary, title: secondary })));
      const trailing = h("span", { className: "pepbs-entry-trailing" });
      const types = kind === "moves" ? [entry.values.Type] : ["pokemon", "forms"].includes(kind) ? [entry.values.Type1 || inheritedValue(entry, "Type1"), entry.values.Type2 || inheritedValue(entry, "Type2")] : [];
      if (types.some(Boolean)) trailing.appendChild(h("span", { className: "pepbs-entry-types" }, ...types.filter(Boolean).map((type) => typeMark(type, true))));
      if (kind === "moves" && entry.values.Category) trailing.appendChild(categoryMark(entry.values.Category, true));
      if (kind === "trainers") {
        const battles = trainerGroup(entriesFor("trainers"), entry).length;
        if (battles > 1) trailing.appendChild(h("span", { className: "pepbs-battle-count", text: t(`${battles} combates`) }));
      }
      if (entry.dirty) trailing.appendChild(h("span", { className: "pepbs-dot", title: t("Modificado") }));
      row.appendChild(trailing);
      els.list.appendChild(row);
    }
    if (!filtered.length) els.list.appendChild(h("div", { className: "pepbs-empty", text: t("No hay resultados para esta búsqueda.") }));
    els.catalogFoot.innerHTML = "";
    els.catalogFoot.appendChild(h("span", { text: t(`${filtered.length} resultados`) }));
  }

function applyConnectionMapFilter(nextMapId, connectionAtlasView = null) {
  const normalized = nextMapId == null ? null : Number(nextMapId);
  state.connectionMapFilter = normalized != null && Number(state.connectionMapFilter) === normalized ? null : normalized;
  state.connectionAtlasFocusKey = null;
  state.connectionAtlasView = connectionAtlasView;
    state.search = "";
    const matches = filteredEntries();
    if (!matches.some((entry) => entry.key === state.selected.connections)) state.selected.connections = matches[0]?.key;
    renderCatalogHead(); renderCatalogList(); renderDetail(); renderPreview(); renderIssues();
  }

  function fieldIssues(kind, entry, key) {
    return issuesForEntry(state.data.validation, kind, entry).filter((item) => item.field === key && item.level === "error");
  }

  function localizedField(kind, key) {
    const baseKey = String(key || "").split(".")[0];
    const field = SCHEMAS[kind]?.sections.flatMap((section) => section.fields).find((item) => item.key === baseKey);
    return t(field?.label || baseKey || "Campo");
  }

  function typeMark(type, compact = false) {
    const record = (state.data?.types ?? []).find((item) => item.id === type);
    const label = t(record?.name || type || "Sin tipo");
    return createTypeBadge(type, label, compact);
  }

  function categoryMark(category, compact = false) {
    return createCategoryBadge(category, compact);
  }

  function createReferenceInput(value, reference, onInput, placeholder = "", config = {}) {
    if (reference === "types") return createTypePicker(value, onInput, state.data?.types ?? [], placeholder);
    const records = references()[reference] ?? [];
    let selectedId = String(value ?? "");
    const selectedRecord = () => records.find((item) => item.id === selectedId);
    const displayValue = () => selectedRecord()?.name || "";
    const wrap = h("div", { className: "pepbs-ref-picker" });
    const input = h("button", {
      type: "button", className: "pepbs-input pepbs-ref-value",
      role: "combobox", "aria-haspopup": "listbox", "aria-expanded": "false",
    });
    const currentVisual = h("span", { className: "pepbs-ref-current" });
    const toggle = h("button", { type: "button", className: "pepbs-ref-toggle", title: t("Mostrar todas las opciones"), "aria-label": t(`Mostrar opciones de ${placeholder || reference}`), "aria-expanded": "false" });
    const menu = h("div", { className: "pepbs-ref-menu", role: "listbox", hidden: true });
    const search = h("input", { className: "pepbs-ref-search", type: "search", placeholder: t("Buscar por nombre o ID…"), autocomplete: "off", "aria-label": t("Buscar por nombre o ID") });
    const optionList = h("div", { className: "pepbs-ref-options" });

    const appendOption = (record) => {
      const option = h("button", {
        type: "button", role: "option", "aria-selected": record.id === selectedId ? "true" : "false",
        className: `pepbs-ref-option ${record.id === selectedId ? "is-active" : ""}`, onClick: () => selectRecord(record.id),
      });
      option.appendChild(h("span", { className: "pepbs-ref-copy" }, h("strong", { text: record.name || record.id }), record.name !== record.id ? h("small", { text: record.id }) : null));
      if (reference === "moves") {
        const visuals = h("span", { className: "pepbs-move-visuals" });
        if (record.entry?.values.Type) visuals.appendChild(typeMark(record.entry.values.Type, true));
        if (record.entry?.values.Category) visuals.appendChild(categoryMark(record.entry.values.Category, true));
        option.appendChild(visuals);
      }
      optionList.appendChild(option);
    };
    const appendGroup = (label, groupedRecords) => {
      if (!groupedRecords.length) return;
      optionList.appendChild(h("div", { className: "pepbs-ref-group-label", role: "presentation", text: t(label) }));
      groupedRecords.forEach(appendOption);
    };
    const renderOptions = (query = "") => {
      optionList.innerHTML = "";
      const normalized = String(query).trim().toLocaleLowerCase("es");
      const filtered = normalized
        ? records.filter((record) => `${record.id} ${record.name} ${record.searchText || ""}`.toLocaleLowerCase("es").includes(normalized))
        : records;
      const emptyLabel = t(["bgm", "me"].includes(reference) ? "Predeterminado del juego" : "— Sin valor —");
      if (config.allowEmpty !== false) optionList.appendChild(h("button", { type: "button", role: "option", className: "pepbs-ref-option is-empty", text: emptyLabel, onClick: () => selectRecord("") }));
      const configuredGroups = typeof config.groups === "function" ? config.groups() : config.groups;
      if (Array.isArray(configuredGroups) && configuredGroups.length) {
        const renderedIds = new Set();
        for (const group of configuredGroups) {
          const ids = new Set((group.ids ?? []).map(String));
          const groupedRecords = filtered.filter((record) => ids.has(record.id) && !renderedIds.has(record.id));
          groupedRecords.forEach((record) => renderedIds.add(record.id));
          appendGroup(group.label, groupedRecords);
        }
        appendGroup(config.remainderLabel || "Otras opciones", filtered.filter((record) => !renderedIds.has(record.id)));
      } else {
        filtered.forEach(appendOption);
      }
      if (!filtered.length) optionList.appendChild(h("div", { className: "pepbs-ref-empty", text: t("No hay coincidencias.") }));
    };
    const closeMenu = () => {
      menu.hidden = true;
      toggle.setAttribute("aria-expanded", "false");
      input.setAttribute("aria-expanded", "false");
      wrap.classList.remove("opens-up");
      menu.style.removeProperty("max-height");
      optionList.style.removeProperty("max-height");
      search.value = "";
    };
    const selectRecord = (id) => {
      selectedId = String(id ?? "");
      refreshValue();
      onInput(selectedId);
      refreshCurrent(selectedId);
      closeMenu();
    };
    const refreshValue = () => {
      const visible = displayValue();
      input.textContent = visible || placeholder;
      input.classList.toggle("is-placeholder", !visible);
      input.dataset.value = selectedId;
    };
    const refreshCurrent = (id) => {
      currentVisual.innerHTML = "";
      wrap.classList.remove("has-move-visual", "has-pokemon-visual");
      const record = records.find((item) => item.id === id);
      if (!record) return;
      if (["pokemon", "encounterPokemon"].includes(reference) && config.showPokemonIcon !== false) {
        wrap.classList.add("has-pokemon-visual");
        const icon = h("span", { className: "pepbs-ref-pokemon-icon" });
        currentVisual.appendChild(icon);
        attachPokemonIcon(icon, record.species || record.id, record.form || 0);
        return;
      }
      if (reference !== "moves") return;
      wrap.classList.add("has-move-visual");
      if (record.entry?.values.Type) currentVisual.appendChild(typeMark(record.entry.values.Type, true));
      if (record.entry?.values.Category) currentVisual.appendChild(categoryMark(record.entry.values.Category, true));
    };
    const openAll = () => {
      renderOptions();
      menu.hidden = false;
      toggle.setAttribute("aria-expanded", "true");
      input.setAttribute("aria-expanded", "true");
      placeFloatingMenu(wrap, menu, { maximumHeight: 310, list: optionList });
      requestAnimationFrame(() => search.focus());
    };

    toggle.addEventListener("click", () => {
      if (menu.hidden) openAll();
      else { closeMenu(); input.focus(); }
    });
    input.addEventListener("click", () => { if (menu.hidden) openAll(); else closeMenu(); });
    input.addEventListener("keydown", (event) => {
      if (["ArrowDown", "Enter", " "].includes(event.key) && menu.hidden) { event.preventDefault(); openAll(); }
      if (event.key === "Escape" && !menu.hidden) { event.preventDefault(); closeMenu(); input.focus(); }
    });
    search.addEventListener("input", () => {
      renderOptions(search.value);
      placeFloatingMenu(wrap, menu, { maximumHeight: 310, list: optionList });
    });
    search.addEventListener("keydown", (event) => {
      if (event.key !== "ArrowDown") return;
      const first = optionList.querySelector(".pepbs-ref-option");
      if (first) { event.preventDefault(); first.focus(); }
    });
    wrap.addEventListener("keydown", (event) => {
      if (event.key !== "Escape" || menu.hidden) return;
      event.preventDefault();
      closeMenu();
      input.focus();
    });
    wrap.addEventListener("focusout", () => setTimeout(() => {
      if (wrap.contains(document.activeElement)) return;
      closeMenu();
    }, 0));
    refreshValue();
    refreshCurrent(selectedId);
    menu.append(search, optionList);
    wrap.append(input, currentVisual, toggle, menu);
    return wrap;
  }

  function makeSimpleControl(field, entry, kind) {
    const value = entry.values[field.key] ?? "";
    const inherited = field.inherited ? inheritedValue(entry, field.key) : "";
    const inheritedDisplay = inheritedDisplayValue(field, inherited);
    const commit = (next) => {
      setValue(entry, field.key, next);
      if (field.rerenderOnChange) renderDetail();
    };
    if (field.key === "Category") return createCategoryPicker(value, commit, ENUMS.categories);
    if (field.type === "select") {
      const options = [];
      if (field.inherited || !field.required) options.push(["", inheritedDisplay ? `${t("Heredar")} · ${inheritedDisplay}` : t("— Sin valor —")]);
      for (const [optionValue, label] of optionPairs(field.options)) {
        const code = String(optionValue);
        const visibleLabel = t(label);
        options.push([optionValue, visibleLabel !== code && /^(?:-?\d+|[A-Za-z])$/.test(code) ? `${code} · ${visibleLabel}` : visibleLabel]);
      }
      return dropdown(value, options, commit, { label: t(field.label), searchPlaceholder: t("Buscar opciones…"), noMatches: t("No hay coincidencias.") });
    }
    if (field.type === "textarea") {
      const area = h("textarea", { className: "pepbs-textarea", placeholder: inherited || "" });
      area.value = value;
      area.addEventListener("input", () => setValue(entry, field.key, area.value.replace(/[\r\n]+/g, " ")));
      return area;
    }
    if (field.type === "ref" || field.reference) {
      const config = kind === "forms" && field.key === "Species" ? { allowEmpty: false } : {};
      return createReferenceInput(value, field.reference, commit, inheritedDisplay || t("Escribe o elige un ID…"), config);
    }
    const input = h("input", {
      className: "pepbs-input", type: field.type === "number" ? "number" : "text", value,
      placeholder: inherited || "", min: field.min, max: field.max, step: field.step ?? (field.type === "number" ? 1 : undefined),
      disabled: Boolean(field.protected), spellcheck: field.type === "text" && !field.protected,
    });
    input.addEventListener("input", () => setValue(entry, field.key, input.value));
    if (field.rerenderOnChange) input.addEventListener("change", renderDetail);
    return input;
  }

  function listDraftKey(kind, entry, field) { return `${kind}:${entry.key}:${field.key}`; }

  function rowActions(index, length, onMove, onRemove) {
    const grip = h("button", {
      className: "pepbs-mini pepbs-drag-grip", type: "button", title: t("Arrastrar para reordenar"),
      "aria-label": t("Reordenar elemento"), "aria-keyshortcuts": "ArrowUp ArrowDown Home End", "aria-grabbed": "false", disabled: length < 2,
    }, h("span", { className: "pepbs-grip-dots", "aria-hidden": "true" }, ...Array.from({ length: 6 }, () => h("i"))));
    let gesture = null;
    const clearGesture = () => {
      if (!gesture) return;
      gesture.rows.forEach((row) => {
        row.classList.remove("is-reorder-source", "is-reorder-shifted");
        row.style.removeProperty("--pepbs-reorder-y");
        row.style.removeProperty("--pepbs-reorder-drag-y");
      });
      grip.classList.remove("is-dragging");
      grip.setAttribute("aria-grabbed", "false");
    };
    const previewTarget = (target) => {
      const { rows, rects, sourceRowIndex, row } = gesture;
      rows.forEach((candidate, candidateIndex) => {
        if (candidate === row) return;
        let delta = 0;
        if (sourceRowIndex < target && candidateIndex > sourceRowIndex && candidateIndex <= target) {
          delta = rects[candidateIndex - 1].top - rects[candidateIndex].top;
        } else if (sourceRowIndex > target && candidateIndex >= target && candidateIndex < sourceRowIndex) {
          delta = rects[candidateIndex + 1].top - rects[candidateIndex].top;
        }
        candidate.classList.toggle("is-reorder-shifted", delta !== 0);
        if (delta) candidate.style.setProperty("--pepbs-reorder-y", `${delta}px`);
        else candidate.style.removeProperty("--pepbs-reorder-y");
      });
    };
    grip.addEventListener("pointerdown", (event) => {
      if (event.button !== 0 || grip.disabled) return;
      const row = grip.closest("[data-reorder-row]");
      if (!row?.parentElement) return;
      const rows = [...row.parentElement.children].filter((item) => item.hasAttribute?.("data-reorder-row"));
      const sourceRowIndex = rows.indexOf(row);
      if (sourceRowIndex < 0) return;
      event.preventDefault();
      gesture = {
        pointerId: event.pointerId, startY: event.clientY, source: index, target: sourceRowIndex,
        sourceRowIndex, row, rows, rects: rows.map((item) => item.getBoundingClientRect()), dragged: false,
      };
      grip.setPointerCapture(event.pointerId);
    });
    grip.addEventListener("pointermove", (event) => {
      if (!gesture || event.pointerId !== gesture.pointerId) return;
      if (!gesture.dragged && Math.abs(event.clientY - gesture.startY) < 4) return;
      gesture.dragged = true;
      event.preventDefault();
      grip.classList.add("is-dragging");
      grip.setAttribute("aria-grabbed", "true");
      gesture.row.classList.add("is-reorder-source");
      gesture.row.style.setProperty("--pepbs-reorder-drag-y", `${event.clientY - gesture.startY}px`);
      const candidates = gesture.rects.filter((_, candidateIndex) => candidateIndex !== gesture.sourceRowIndex);
      let target = candidates.length;
      for (let candidateIndex = 0; candidateIndex < candidates.length; candidateIndex += 1) {
        const rect = candidates[candidateIndex];
        if (event.clientY < rect.top + rect.height / 2) { target = candidateIndex; break; }
      }
      gesture.target = Math.max(0, Math.min(gesture.rows.length - 1, target));
      previewTarget(gesture.target);
    });
    const finish = (commit) => {
      if (!gesture) return;
      const { source, target, dragged } = gesture;
      clearGesture();
      gesture = null;
      grip.blur();
      window.getSelection?.()?.removeAllRanges();
      if (commit && dragged && source !== target) onMove(target);
    };
    grip.addEventListener("pointerup", (event) => {
      if (gesture?.pointerId !== event.pointerId) return;
      finish(true);
      if (grip.hasPointerCapture(event.pointerId)) grip.releasePointerCapture(event.pointerId);
    });
    grip.addEventListener("pointercancel", () => finish(false));
    grip.addEventListener("lostpointercapture", () => finish(false));
    grip.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && gesture) {
        event.preventDefault();
        const pointerId = gesture.pointerId;
        finish(false);
        if (grip.hasPointerCapture(pointerId)) grip.releasePointerCapture(pointerId);
        return;
      }
      const target = event.key === "ArrowUp" ? index - 1 : event.key === "ArrowDown" ? index + 1 : event.key === "Home" ? 0 : event.key === "End" ? length - 1 : index;
      if (target === index) return;
      event.preventDefault();
      onMove(target);
    });
    return h("span", { className: "pepbs-row-actions" }, grip,
      h("button", { className: "pepbs-mini", type: "button", title: t("Eliminar"), "aria-label": t("Eliminar"), text: "×", onClick: onRemove }));
  }

  function moveItem(items, index, target) {
    if (target < 0 || target >= items.length || target === index) return;
    const [item] = items.splice(index, 1);
    items.splice(target, 0, item);
  }

  function renderComplexGuided(body, field, entry, kind, rerender) {
    if (field.type === "trainerTeam") {
      renderTrainerTeamEditor({ body, entry, rerender, h, button, rowActions, createReferenceInput, setPokemonValue, markTrainerChanged, attachPokemonIcon, references });
      return;
    }
    const draftKey = listDraftKey(kind, entry, field);
    const commitList = (items) => {
      if (items.some((item) => item !== "")) state.pendingLists.delete(draftKey);
      setValue(entry, field.key, items.filter((item) => item !== "").join(","));
    };
    if (field.type === "stats") {
      const values = String(entry.values[field.key] ?? "").split(",");
      const stats = h("div", { className: "pepbs-stats" });
      STAT_NAMES.forEach((name, index) => {
        const input = h("input", { className: "pepbs-input", type: "number", min: field.ev ? 0 : 1, max: field.ev ? 255 : 999, value: values[index] ?? "" });
        input.addEventListener("input", () => { values[index] = input.value; setValue(entry, field.key, values.join(",")); });
        stats.appendChild(h("div", { className: "pepbs-stat" }, h("label", { text: t(name) }), input));
      });
      body.appendChild(stats); return;
    }
    if (field.type === "flags") {
      const selected = new Set(String(entry.values[field.key] ?? "").split(""));
      const flags = h("div", { className: "pepbs-flags" });
      for (const [flag, label] of MOVE_FLAGS) {
        const check = switchControl(selected.has(flag), (checked) => {
          if (checked) selected.add(flag); else selected.delete(flag);
          setValue(entry, field.key, MOVE_FLAGS.map(([id]) => id).filter((id) => selected.has(id)).join(""));
        }, { label: `${flag} · ${t(label)}` });
        flags.appendChild(h("label", { className: "pepbs-flag" }, check, h("span", { text: `${flag} · ${t(label)}` })));
      }
      body.appendChild(flags); return;
    }
    if (field.type === "levelMoves") {
      const pairs = parsePairs(entry.values[field.key]);
      const rows = h("div", { className: "pepbs-rows" });
      pairs.forEach((pair, index) => {
        const level = h("input", { className: "pepbs-input", type: "number", min: 0, value: pair[0], placeholder: t("Nivel") });
        let move;
        const refreshValidity = () => {
          const levelValid = pair[0] !== "" && Number.isInteger(Number(pair[0])) && Number(pair[0]) >= 0;
          const moveValid = Boolean(pair[1]) && references().moves.some((record) => record.id === pair[1]);
          level.classList.toggle("is-invalid", !levelValid);
          level.setAttribute("aria-invalid", String(!levelValid));
          move?.classList.toggle("is-invalid", !moveValid);
          move?.querySelector(".pepbs-input")?.setAttribute("aria-invalid", String(!moveValid));
        };
        level.addEventListener("input", () => { pair[0] = level.value; setValue(entry, field.key, pairs.flat().join(",")); refreshValidity(); });
        move = createReferenceInput(pair[1], "moves", (value) => { pair[1] = value; setValue(entry, field.key, pairs.flat().join(",")); refreshValidity(); }, t("Movimiento…"));
        refreshValidity();
        rows.appendChild(h("div", { className: "pepbs-row pair", "data-reorder-row": true }, level, move,
          rowActions(index, pairs.length, (targetIndex) => { moveItem(pairs, index, targetIndex); setValue(entry, field.key, pairs.flat().join(",")); rerender(); }, () => { pairs.splice(index, 1); setValue(entry, field.key, pairs.flat().join(",")); rerender(); })));
      });
      const sortByLevel = button(t("Ordenar por nivel"), () => {
        const sortableLevel = (pair) => Number.isFinite(Number(pair[0])) ? Number(pair[0]) : Number.POSITIVE_INFINITY;
        const ordered = pairs.map((pair, index) => ({ pair, index })).sort((a, b) => sortableLevel(a.pair) - sortableLevel(b.pair) || a.index - b.index).map(({ pair }) => pair);
        pairs.splice(0, pairs.length, ...ordered);
        setValue(entry, field.key, pairs.flat().join(","));
        rerender();
      }, "pepbs-btn-compact");
      const sortableLevel = (pair) => Number.isFinite(Number(pair[0])) ? Number(pair[0]) : Number.POSITIVE_INFINITY;
      const isSorted = pairs.every((pair, index) => index === 0 || sortableLevel(pairs[index - 1]) <= sortableLevel(pair));
      sortByLevel.disabled = pairs.length < 2 || isSorted;
      const add = button(t("+ Añadir"), () => { pairs.push(["1", ""]); setValue(entry, field.key, pairs.flat().join(",")); rerender(); }, "pepbs-add");
      const actions = h("div", { className: "pepbs-level-moves-actions" }, add, sortByLevel);
      body.append(rows, actions); return;
    }
    if (field.type === "evolutions") {
      const triplets = parseTriplets(entry.values[field.key]);
      const rows = h("div", { className: "pepbs-rows" });
      triplets.forEach((triplet, index) => {
        const target = createReferenceInput(triplet[0], "pokemon", (value) => { triplet[0] = value; setValue(entry, field.key, triplets.flat().join(",")); }, t("Pokémon destino…"));
        const methodOptions = EVOLUTION_METHODS.includes(triplet[1])
          ? EVOLUTION_METHODS
          : [triplet[1], ...EVOLUTION_METHODS].filter(Boolean);
        const method = dropdown(triplet[1], methodOptions, (next) => {
          triplet[1] = next;
          setValue(entry, field.key, triplets.flat().join(","));
          rerender();
        }, { label: t("Método de evolución"), searchPlaceholder: t("Buscar métodos…"), noMatches: t("No hay coincidencias.") });
        const parameterRef = EVOLUTION_PARAMETER[triplet[1]];
        const parameterEnabled = evolutionParameterApplies(triplet[1]);
        const parameter = parameterRef
          ? createReferenceInput(triplet[2], parameterRef, (value) => { triplet[2] = value; setValue(entry, field.key, triplets.flat().join(",")); }, t("Parámetro…"))
          : h("input", { className: "pepbs-input", value: triplet[2], placeholder: t("Parámetro") });
        if (!parameterRef) parameter.addEventListener("input", () => { triplet[2] = parameter.value; setValue(entry, field.key, triplets.flat().join(",")); });
        if (!parameterEnabled) {
          parameter.classList.add("is-dependency-disabled");
          parameter.setAttribute("inert", "");
          parameter.setAttribute("aria-disabled", "true");
          parameter.title = t("Este método de evolución no usa parámetro.");
          parameter.querySelectorAll?.("input, textarea, button").forEach((control) => { control.disabled = true; });
          if (parameter.matches?.("input, textarea, button")) parameter.disabled = true;
        }
        rows.appendChild(h("div", { className: "pepbs-row triplet pepbs-evolution-row", "data-reorder-row": true }, target, method, parameter,
          rowActions(index, triplets.length, (targetIndex) => { moveItem(triplets, index, targetIndex); setValue(entry, field.key, triplets.flat().join(",")); rerender(); }, () => { triplets.splice(index, 1); setValue(entry, field.key, triplets.flat().join(",")); rerender(); })));
      });
      body.append(rows, button(t("+ Añadir evolución"), () => { triplets.push(["", "Level", "1"]); setValue(entry, field.key, triplets.flat().join(",")); rerender(); }, "pepbs-add")); return;
    }
    const items = splitList(entry.values[field.key]);
    if (state.pendingLists.has(draftKey)) items.push("");
    const rows = h("div", { className: "pepbs-rows" });
    items.forEach((item, index) => {
      let control;
      if (field.reference) control = createReferenceInput(item, field.reference, (value) => { items[index] = value; commitList(items); }, t("Escribe o elige…"));
      else {
        const options = [["", t("— Elegir —")], ...optionPairs(field.options).map(([optionValue, label]) => [optionValue, t(label)])];
        control = dropdown(item, options, (next) => { items[index] = next; commitList(items); }, { searchPlaceholder: t("Buscar opciones…"), noMatches: t("No hay coincidencias.") });
      }
      rows.appendChild(h("div", { className: "pepbs-row", "data-reorder-row": true }, control,
        rowActions(index, items.length, (targetIndex) => { moveItem(items, index, targetIndex); commitList(items); rerender(); }, () => { items.splice(index, 1); state.pendingLists.delete(draftKey); commitList(items); rerender(); })));
    });
    body.append(rows, button(t("+ Añadir"), () => { state.pendingLists.add(draftKey); rerender(); }, "pepbs-add"));
  }

  function makeComplexControl(field, entry, kind) {
    const container = h("div");
    const render = () => {
      container.innerHTML = "";
      renderComplexGuided(container, field, entry, kind, render);
    };
    render();
    return container;
  }

  function renderField(field, entry, kind) {
    const errors = fieldIssues(kind, entry, field.key);
    const dependency = pbsFieldDependency(kind, field.key, entry.values, (key) => entry.values[key] || inheritedValue(entry, key));
    const classes = ["pepbs-field", field.wide ? "is-wide" : "", field.complex ? "pepbs-complex" : "", errors.length ? "has-error" : "", !dependency.enabled ? "is-dependency-disabled" : ""].filter(Boolean).join(" ");
    const wrapper = h("div", {
      className: classes,
      "data-field-key": field.key,
      inert: !dependency.enabled,
      "aria-disabled": dependency.enabled ? null : "true",
      title: dependency.enabled ? null : t(dependency.reason),
    });
    const head = h("div", { className: "pepbs-field-head" },
      h("label", { className: "pepbs-label" }, t(field.label), field.required ? h("span", { className: "pepbs-required", text: " *" }) : null));
    let complex = null;
    if (field.complex) complex = makeComplexControl(field, entry, kind);
  else if (field.inherited && !normalize(entry.values[field.key]) && normalize(inheritedValue(entry, field.key))) {
    const inheritedDisplay = inheritedDisplayValue(field, inheritedValue(entry, field.key));
    head.appendChild(h("span", { className: "pepbs-inherited", title: inheritedDisplay, text: `${t("Heredado")}: ${inheritedDisplay}` }));
  }
    wrapper.appendChild(head);
    wrapper.appendChild(complex || makeSimpleControl(field, entry, kind));
    if (!dependency.enabled) wrapper.querySelectorAll("input, textarea, button").forEach((control) => { control.disabled = true; });
    for (const error of errors) wrapper.appendChild(h("div", { className: "pepbs-field-error", text: t(error.message) }));
    return wrapper;
  }

  function fieldIsVisible(field, entry) {
    if (!field.visibleWhen) return true;
    return field.visibleWhen.values.map(String).includes(String(entry.values[field.visibleWhen.key] ?? ""));
  }

  function renderSectionFields(grid, fields, entry, kind) {
    const visible = fields.filter((field) => fieldIsVisible(field, entry));
    for (let index = 0; index < visible.length;) {
      const field = visible[index];
      if (!field.group) { grid.appendChild(renderField(field, entry, kind)); index += 1; continue; }
      const grouped = [];
      while (index < visible.length && visible[index].group === field.group) { grouped.push(visible[index]); index += 1; }
      const group = h("div", { className: `pepbs-field-group is-wide ${grouped.length === 1 ? "is-single" : ""}`, "data-field-group": field.group, style: { "--pepbs-group-columns": String(grouped.length) } });
      grouped.forEach((item) => group.appendChild(renderField(item, entry, kind)));
      grid.appendChild(group);
    }
  }

  function renderCombatBar(entry) {
    const siblings = trainerGroup(entriesFor("trainers"), entry);
    const bar = h("div", { className: "pepbs-combat-bar" }, h("span", { className: "pepbs-combat-label", text: t("Combates") }));
    const tabs = h("div", { className: "pepbs-combat-tabs", role: "tablist", "aria-label": t("Combates de este entrenador") });
    siblings.forEach((battle, index) => tabs.appendChild(h("button", {
      type: "button", role: "tab", "aria-selected": battle.key === entry.key ? "true" : "false",
      className: `pepbs-combat-tab ${battle.key === entry.key ? "is-active" : ""}`,
      title: t(`Versión PBS ${battle.values.Version || 0}`),
      text: t(`Combate ${index + 1}`),
      onClick: () => { state.selected.trainers = battle.key; renderCatalogList(); renderDetail(); renderPreview(); renderIssues(); },
    })));
    tabs.appendChild(h("button", {
      type: "button", className: "pepbs-combat-add", title: t("Duplica este equipo como punto de partida"), "aria-label": t("Añadir otro combate"), text: t("+ Nuevo combate"),
      onClick: () => {
        const battle = createTrainerVersion(state.data.documents.trainers, entry);
        trackNewEntry(state.data.documents.trainers, battle);
        state.selected.trainers = battle.key; state.data.validation = validateWorkspace(state.data.documents, state.data.types); renderAll();
      },
    }));
    bar.append(tabs, h("span", { className: "pepbs-combat-help", text: t("El nombre y el tipo se comparten entre combates.") }));
    return bar;
  }

  function renderDetail() {
    ebdxCleanup?.();
    ebdxCleanup = null;
    els.editor.innerHTML = "";
    const kind = actualKind();
    const entry = selectedEntry(kind);
    if (!entry) { els.editor.appendChild(h("div", { className: "pepbs-empty", text: t("Selecciona un registro para editarlo.") })); return; }
    if (kind === "ebdx") {
      ebdxCleanup = renderEbdxPositioner({
        container: els.editor,
        entry,
        loadImage: loadPersistentImage,
        onChange: (field, value) => changeEbdxValue(entry, field, value),
        onReset: () => resetEbdxEntry(entry),
        onApplyAllForms: () => applyEbdxToAllForms(entry),
        canApplyAllForms: state.ebdx.entries.filter((candidate) => candidate.species === entry.species).length > 1,
        onBeginEdit: (label) => beginEbdxEdit([entry], label),
        onCommitEdit: commitEbdxEdit,
        onUndo: undoEbdx,
        onRedo: redoEbdx,
        canUndo: () => state.ebdxHistory.undo.length > 0,
        canRedo: () => state.ebdxHistory.redo.length > 0,
      });
      return;
    }
    if (isWorldKind(kind)) {
      const common = {
        container: els.editor,
        entry,
        maps: state.maps,
        ctx,
        data: {
          world: state.world,
          assets: state.assets,
          pokemon: state.data.documents.pokemon,
          trainerTypes: state.data.documents.trainerTypes.entries,
        },
        onChange: changeWorldEntry,
        loadImage: loadPersistentImage,
        loadPokemonIcon: attachPokemonIcon,
        createReferenceInput,
        rowActions,
        mapVisuals,
        dialogs: els.dialogs,
        onDelete: () => deleteWorldRecord(kind, entry),
        rerender: renderDetail,
       connectionMapFilter: state.connectionMapFilter,
       connectionAtlasFocusKey: state.connectionAtlasFocusKey,
       connectionAtlasView: state.connectionAtlasView,
       onConnectionMapFilter: applyConnectionMapFilter,
      };
      if (kind === "townMap") renderTownMapEditor(common);
      else if (kind === "encounters") renderEncountersEditor(common);
      else if (kind === "metadata") renderMetadataEditor(common);
      else renderConnectionsEditor(common);
      return;
    }
    const schema = SCHEMAS[kind];
    const activeSection = state.activeTabs[kind] || schema.sections[0].id;
    if (!schema.sections.some((section) => section.id === activeSection)) state.activeTabs[kind] = schema.sections[0].id;
    const section = schema.sections.find((item) => item.id === (state.activeTabs[kind] || schema.sections[0].id)) || schema.sections[0];
    const entryIssues = issuesForEntry(state.data.validation, kind, entry);
    const head = h("div", { className: "pepbs-record-head" });
    const title = h("div", { className: "pepbs-record-title" },
      h("div", {}, h("h2", { text: displayName(kind, entry, state.data.documents) }), h("code", { text: kind === "forms" ? `[${entry.species},${entry.form}]` : kind === "trainers" ? internalName(kind, entry) : `${entry.idNumber} · ${entry.values.InternalName}` })),
      h("div", { className: "pepbs-record-badges" }));
    if (entry.dirty) title.lastChild.appendChild(h("span", { className: "pepbs-badge pepbs-badge-dirty", text: t("Modificado") }));
    if (entryIssues.some((item) => item.level === "error")) title.lastChild.appendChild(h("span", { className: "pepbs-badge pepbs-badge-error", text: t(`${entryIssues.filter((item) => item.level === "error").length} errores`) }));
    title.lastChild.appendChild(button(t(kind === "trainers" ? "Eliminar combate" : "Eliminar"), () => deleteRecord(kind, entry), "pepbs-btn-compact pepbs-btn-danger pepbs-delete-record"));
    head.appendChild(title);
    if (kind === "trainers") head.appendChild(renderCombatBar(entry));
    const tabs = h("div", { className: "pepbs-tabs" });
    for (const item of schema.sections) tabs.appendChild(h("button", {
      type: "button", className: `pepbs-tab ${item.id === section.id ? "is-active" : ""}`, text: t(TAB_LABELS[item.id] || item.label),
      onClick: () => { state.activeTabs[kind] = item.id; renderDetail(); },
    }));
    head.appendChild(tabs); els.editor.appendChild(head);
    const form = h("div", { className: "pepbs-form" }, h("h3", { className: "pepbs-section-heading", text: t(section.label) }));
    const grid = h("div", { className: "pepbs-grid" });
    renderSectionFields(grid, section.fields, entry, kind);
    form.appendChild(grid); els.editor.appendChild(form);
  }

  function clearPreviewUrls() { projectAssets.clearTransient(); }
  let previewTimer = null;
  function schedulePreview() {
    clearTimeout(previewTimer);
    previewTimer = setTimeout(() => { if (!state.disposed) renderPreview(); }, 120);
  }
  async function loadImage(relativeCandidates) {
    return projectAssets.loadTransient(relativeCandidates);
  }

  async function loadPersistentImage(relativeCandidates) {
    return projectAssets.loadPersistent(relativeCandidates);
  }

  async function attachPokemonIcon(container, species, form = "") {
    const request = `${species}:${form || 0}:${Date.now()}:${Math.random()}`;
    container.dataset.request = request;
    if (!species) return;
    const suffix = Number(form) > 0 ? `_${form}` : "";
    const url = await loadPersistentImage([`Graphics/Pokemon/Icons/${species}${suffix}.png`, `Graphics/Pokemon/Icons/${species}.png`, "Graphics/Pokemon/Icons/000.png"]);
    if (!url || container.dataset.request !== request) return;
    container.innerHTML = "";
    container.appendChild(h("img", { src: url, alt: t(`Icono de ${species}`) }));
  }

  async function renderPreview() {
    const token = ++state.previewToken;
    clearPreviewUrls(); els.preview.innerHTML = "";
    const kind = actualKind(); const entry = selectedEntry(kind);
    if (!entry) return;
    if (kind === "ebdx") { els.preview.hidden = true; return; }
    if (isWorldKind(kind)) {
      const hasPreview = kind !== "townMap" && kind !== "connections";
      els.preview.hidden = !hasPreview;
      if (hasPreview) await renderWorldPreview({ container: els.preview, kind, entry, maps: state.maps, mapVisuals, loadImage });
      return;
    }
    els.preview.hidden = kind === "abilities";
    if (kind === "abilities") return;
    els.preview.appendChild(h("div", { className: "pepbs-preview-label", text: t("Vista previa") }));
    const art = h("div", { className: "pepbs-art" }, h("div", { className: "pepbs-art-placeholder" }, createDomainIcon(kind)));
    if (["pokemon", "forms", "items", "trainers", "trainerTypes"].includes(kind)) els.preview.appendChild(art);
    els.preview.appendChild(h("div", { className: "pepbs-preview-name", text: displayName(kind, entry, state.data.documents) }));
    els.preview.appendChild(h("div", { className: "pepbs-preview-id", text: internalName(kind, entry) }));
    if (["pokemon", "forms", "moves"].includes(kind)) {
      const typeRow = h("div", { className: "pepbs-type-row" });
      const typeValues = kind === "moves" ? [entry.values.Type] : [entry.values.Type1 || inheritedValue(entry, "Type1"), entry.values.Type2 || inheritedValue(entry, "Type2")];
      typeValues.filter(Boolean).forEach((type) => typeRow.appendChild(typeMark(type)));
      if (kind === "moves" && entry.values.Category) typeRow.appendChild(categoryMark(entry.values.Category, true));
      els.preview.appendChild(typeRow);
    }
    const description = entry.values.Description || entry.values.Pokedex || inheritedValue(entry, "Pokedex");
    if (description) els.preview.appendChild(h("p", { className: "pepbs-preview-description", text: description }));
    const summary = h("div", { className: "pepbs-summary" });
    if (kind === "pokemon" || kind === "forms") {
      const stats = splitList(entry.values.BaseStats || inheritedValue(entry, "BaseStats"));
      summary.append(h("div", {}, h("span", { text: t("Total base") }), h("strong", { text: stats.reduce((sum, value) => sum + (Number(value) || 0), 0) })),
        h("div", {}, h("span", { text: t("Generación") }), h("strong", { text: entry.values.Generation || inheritedValue(entry, "Generation") || "—" })));
    } else if (kind === "moves") {
      summary.append(h("div", {}, h("span", { text: t("Potencia") }), h("strong", { text: entry.values.Power })), h("div", {}, h("span", { text: t("Precisión / PP") }), h("strong", { text: `${entry.values.Accuracy} / ${entry.values.TotalPP}` })));
    } else if (kind === "items") {
      const pocket = optionPairs(ENUMS.pockets).find(([id]) => id === entry.values.Pocket)?.[1] || entry.values.Pocket;
      summary.append(h("div", {}, h("span", { text: t("Bolsillo") }), h("strong", { text: t(pocket) })), h("div", {}, h("span", { text: t("Precio") }), h("strong", { text: entry.values.Price })));
    } else if (kind === "trainerTypes") {
      const gender = optionPairs(ENUMS.trainerGenders).find(([id]) => id === entry.values.Gender)?.[1] || entry.values.Gender;
      summary.append(h("div", {}, h("span", { text: t("Dinero base") }), h("strong", { text: entry.values.BaseMoney })), h("div", {}, h("span", { text: t("Género") }), h("strong", { text: t(gender || "Mixto") })));
    } else if (kind === "trainers") {
      summary.append(h("div", {}, h("span", { text: t("Equipo") }), h("strong", { text: `${entry.pokemon.length} Pokémon` })), h("div", {}, h("span", { text: t("Versión") }), h("strong", { text: entry.values.Version || "0" })));
    }
    if (summary.children.length) els.preview.appendChild(summary);

    if (kind === "pokemon" || kind === "forms") {
      const id = kind === "forms" ? entry.species : entry.values.InternalName;
      const suffix = kind === "forms" ? `_${entry.form}` : "";
      const iconUrl = await loadImage([`Graphics/Pokemon/Icons/${id}${suffix}.png`, `Graphics/Pokemon/Icons/${id}.png`, "Graphics/Pokemon/Icons/000.png"]);
      if (token !== state.previewToken) return;
      art.innerHTML = "";
      if (iconUrl) art.appendChild(h("div", { className: "pepbs-icon-crop" }, h("img", { src: iconUrl, alt: t(`Icono de ${id}`) })));
      if (!iconUrl) art.appendChild(h("div", { className: "pepbs-art-placeholder" }, createDomainIcon("pokemon")));
    } else if (kind === "trainers") {
      const trainerType = entry.values.TrainerType;
      const trainerTypeEntry = state.data.documents.trainerTypes.entries.find((item) => item.values.InternalName === trainerType);
      const numeric = Number.isInteger(trainerTypeEntry?.idNumber) ? String(trainerTypeEntry.idNumber).padStart(3, "0") : "";
      const trainerUrl = await loadImage([`Graphics/Trainers/${trainerType}.png`, ...(numeric ? [`Graphics/Trainers/${numeric}.png`] : [])]);
      if (token !== state.previewToken) return;
      art.innerHTML = ""; art.classList.add("pepbs-team-preview");
      if (trainerUrl) art.appendChild(h("img", { className: "pepbs-trainer-art", src: trainerUrl, alt: t(`Entrenador ${trainerType}`) }));
      const party = h("div", { className: "pepbs-party-icons" }); art.appendChild(party);
      for (const pokemon of entry.pokemon) {
        const icon = h("div", { className: "pepbs-team-icon" }, h("span", { text: "·" }));
        party.appendChild(icon); attachPokemonIcon(icon, pokemon.Species, pokemon.Form);
      }
      if (!trainerUrl && !entry.pokemon.length) art.appendChild(h("div", { className: "pepbs-art-placeholder" }, createDomainIcon("trainers")));
    } else if (kind === "trainerTypes") {
      const id = entry.values.InternalName;
      const numeric = String(entry.idNumber).padStart(3, "0");
      const trainerUrl = await loadImage([`Graphics/Trainers/${id}.png`, `Graphics/Trainers/${numeric}.png`]);
      if (token !== state.previewToken) return;
      art.innerHTML = "";
      art.appendChild(trainerUrl ? h("img", { className: "pepbs-trainer-art", src: trainerUrl, alt: t(`Entrenador ${id}`) }) : h("div", { className: "pepbs-art-placeholder" }, createDomainIcon("trainerTypes")));
    } else if (kind === "items") {
      const id = entry.values.InternalName;
      const itemUrl = await loadImage([`Graphics/Items/${id}.png`, "Graphics/Items/000.png"]);
      if (token !== state.previewToken) return;
      art.innerHTML = ""; art.appendChild(itemUrl ? h("img", { className: "pepbs-item-art", src: itemUrl, alt: t(`Icono de ${id}`) }) : h("div", { className: "pepbs-art-placeholder" }, createDomainIcon("items")));
    }
  }

  function renderIssues() {
    els.issues.innerHTML = "";
    const kind = actualKind(); const entry = selectedEntry(kind);
    if (!entry) { els.issues.hidden = true; return; }
    if (isWorldKind(kind)) {
      const issues = validateWorldDocument(documentFor(kind), worldContext()).filter((item) => item.key === entry.key);
      els.issues.hidden = !issues.length;
      if (!issues.length) return;
      els.issues.appendChild(h("div", { className: "pepbs-issues-label", text: t("Validación") }));
      for (const issue of issues.slice(0, 12)) els.issues.appendChild(h("div", { className: "pepbs-issue error", text: t(issue.message) }));
      return;
    }
    if (kind === "ebdx") {
      const issues = state.ebdx.parsed.issues;
      els.issues.hidden = !issues.length;
      if (issues.length) {
        els.issues.appendChild(h("div", { className: "pepbs-issues-label", text: t("Validación") }));
        issues.slice(0, 12).forEach((message) => els.issues.appendChild(h("div", { className: "pepbs-issue error", text: t(message) })));
      }
      return;
    }
    const issues = issuesForEntry(state.data.validation, kind, entry);
    els.issues.hidden = !issues.length;
    if (!issues.length) return;
    els.issues.appendChild(h("div", { className: "pepbs-issues-label", text: t("Validación") }));
    issues.slice(0, 12).forEach((item) => els.issues.appendChild(h("div", { className: `pepbs-issue ${item.level}` }, h("strong", { text: `${t(item.level === "error" ? "Error" : "Aviso")} · ${localizedField(item.kind, item.field)}` }), t(item.message))));
  }

  function refreshVisibleFieldIssues() {
    const kind = actualKind();
    if (isWorldKind(kind) || kind === "ebdx") return;
    const entry = selectedEntry(kind);
    if (!entry) return;
    els.editor.querySelectorAll(".pepbs-field[data-field-key]").forEach((wrapper) => {
      const errors = fieldIssues(kind, entry, wrapper.dataset.fieldKey);
      wrapper.classList.toggle("has-error", errors.length > 0);
      wrapper.querySelectorAll(":scope > .pepbs-field-error").forEach((message) => message.remove());
      for (const issue of errors) wrapper.appendChild(h("div", { className: "pepbs-field-error", text: t(issue.message) }));
    });
  }

  function pendingChanges() {
    const changes = collectDocumentChanges(state.data?.documents);
    for (const document of Object.values(state.world ?? {})) {
      for (const entry of document.entries.filter((item) => item.dirty)) {
        const fields = document.trackedFields.filter((field) => JSON.stringify(entry[field]) !== JSON.stringify(entry.original?.[field]));
        changes.push({ kind: document.kind, document, entry, status: entry.isNew ? "created" : "modified", fields });
      }
      for (const entry of document.deletedEntries ?? []) changes.push({ kind: document.kind, document, entry, status: "deleted", fields: [] });
    }
    for (const entry of dirtyEbdxEntries()) {
      const fields = Object.keys(entry.originalValues).filter((field) => entry.values[field] !== entry.originalValues[field]);
      changes.push({ kind: "ebdx", document: state.ebdx, entry, status: "modified", fields });
    }
    return changes;
  }

  function pendingWarnings() {
    if (!state.data) return [];
    const pbsWarnings = dirtyIssues(state.data.validation).filter((issue) => issue.level === "warning");
    const worldWarnings = dirtyWorldDocuments()
      .flatMap((document) => validateWorldDocument(document, worldContext()))
      .filter((issue) => issue.level === "warning");
    return [...pbsWarnings, ...worldWarnings];
  }

  function pendingErrors() {
    if (!state.data) return [];
    const pbsErrors = dirtyIssues(state.data.validation).filter((issue) => issue.level === "error");
    const worldErrors = dirtyWorldDocuments()
      .flatMap((document) => validateWorldDocument(document, worldContext()))
      .filter((issue) => issue.level === "error");
    return [...pbsErrors, ...worldErrors];
  }

  function pendingPanelIssues() {
    return [...pendingErrors(), ...pendingWarnings()];
  }

  function changeKindLabel(kind) {
    if (kind === "forms") return t("Formas");
    return t(KIND_META[kind]?.label || kind);
  }

  function changeFieldLabel(kind, field) {
    if (field === "pokemon") return t("Equipo Pokémon");
    const ebdxFields = {
      BattlerEnemyX: "Front X", BattlerEnemyY: "Front Y", BattlerPlayerX: "Back X",
      BattlerPlayerY: "Back Y", BattlerAltitude: "Altitud",
    };
    if (kind === "ebdx" && ebdxFields[field]) return t(ebdxFields[field]);
    return localizedField(kind, field);
  }

  function changeSummary(change) {
    if (change.status === "created") return t("Nuevo registro");
    if (change.status === "deleted") return t("Registro eliminado");
    const labels = change.fields.map((field) => changeFieldLabel(change.kind, field));
    if (!labels.length) return t("Registro modificado");
    const visible = labels.slice(0, 2).join(" · ");
    return labels.length > 2 ? `${visible} · +${labels.length - 2}` : visible;
  }

  function closeChangesPanel(returnFocus = false) {
    state.changesOpen = false;
    els.saveMeta.setAttribute("aria-expanded", "false");
    els.changesPanel.hidden = true;
    if (returnFocus) els.saveMeta.focus();
  }

  function issueEntry(issue) {
    return documentFor(issue.kind)?.entries?.find((entry) => entry.key === issue.key) ?? null;
  }

  function issueLocation(issue) {
    const entry = issueEntry(issue);
    const name = entry
      ? (isWorldKind(issue.kind) ? worldEntryName(issue.kind, entry) : displayName(issue.kind, entry, state.data.documents)) || internalName(issue.kind, entry)
      : t("Archivo");
    const field = issue.field && issue.field !== "file" ? changeFieldLabel(issue.kind, issue.field) : "";
    return `${changeKindLabel(issue.kind)} / ${name}${field ? ` · ${field}` : ""}`;
  }

  function activateEntry(kind, entry, issue = null) {
    if (!entry) return;
    if (kind === "forms") {
      state.activeKind = "pokemon";
      state.pokemonMode = "forms";
    } else if (kind === "trainerTypes") {
      state.activeKind = "trainers";
      state.trainerMode = "trainerTypes";
    } else {
      state.activeKind = kind;
    }
    state.selected[kind] = entry.key;
    state.search = "";
    if (kind === "connections") state.connectionMapFilter = null;
    if (issue && SCHEMAS[kind]) {
      const fieldKey = String(issue.field || "").split(/[.[\]]/)[0];
      const section = SCHEMAS[kind].sections.find((candidate) => candidate.fields.some((field) => field.key === fieldKey || (fieldKey === "pokemon" && field.key === "Team")));
      if (section) state.activeTabs[kind] = section.id;
    }
    closeChangesPanel();
    renderAll();
    requestAnimationFrame(() => {
      if (!issue) {
        els.editor.querySelector("input, textarea, button, summary")?.focus?.({ preventScroll: true });
        return;
      }
      const fieldKey = String(issue.field || "").split(/[.[\]]/)[0];
      const wrapper = [...els.editor.querySelectorAll(".pepbs-field[data-field-key]")]
        .find((candidate) => candidate.dataset.fieldKey === fieldKey || (fieldKey === "pokemon" && candidate.dataset.fieldKey === "Team"));
      const target = wrapper?.querySelector("input, textarea, button, summary") ?? wrapper ?? els.editor;
      wrapper?.scrollIntoView({ block: "center" });
      target.focus?.({ preventScroll: true });
    });
  }

  function openPendingIssue(issue) {
    activateEntry(issue.kind, issueEntry(issue), issue);
  }

  function openPendingChange(change, issue = null) {
    if (change.status === "deleted" || !change.entry) return;
    activateEntry(change.kind, change.entry, issue);
  }

  function restorePendingChange(change) {
    if (change.kind === "ebdx") {
      for (const field of Object.keys(change.entry.originalValues)) change.entry.values[field] = change.entry.originalValues[field];
      change.entry.dirty = false;
      state.ebdx.dirty = state.ebdx.entries.some((entry) => entry.dirty);
      const touchesEntry = (command) => command.before.some((saved) => saved.key === change.entry.key);
      state.ebdxHistory.undo = state.ebdxHistory.undo.filter((command) => !touchesEntry(command));
      state.ebdxHistory.redo = state.ebdxHistory.redo.filter((command) => !touchesEntry(command));
      state.ebdxHistory.transaction = null;
    } else if (WORLD_KINDS.includes(change.kind)) {
      if (change.status === "created") change.document.entries = change.document.entries.filter((entry) => entry !== change.entry);
      else if (change.status === "deleted") {
        change.document.deletedEntries = change.document.deletedEntries.filter((entry) => entry !== change.entry);
        change.document.entries.push(change.entry);
      } else {
        Object.assign(change.entry, JSON.parse(JSON.stringify(change.entry.original)));
        change.entry.dirty = false;
      }
      change.document.entries.sort((a, b) => a.order - b.order);
      change.document.dirty = change.document.entries.some((entry) => entry.dirty) || Boolean(change.document.deletedEntries.length);
    } else {
      restoreDocumentChange(change);
    }
  }

  function discardPendingChange(change, focusIndex) {
    restorePendingChange(change);
    state.data.validation = validateWorkspace(state.data.documents, state.data.types);
    renderAll();
    requestAnimationFrame(() => {
      const buttons = [...els.changesPanel.querySelectorAll(".pepbs-change-undo")];
      if (buttons.length) buttons[Math.min(focusIndex, buttons.length - 1)].focus();
      else closeChangesPanel(true);
    });
  }

  async function discardAllPendingChanges(changes) {
    const proceed = await ctx.ui.showConfirmDialog({
      title: t("Descartar todos los cambios"),
      message: t("Se descartarán {count} cambios pendientes y se restaurará el estado anterior a guardar.").replace("{count}", changes.length),
      confirmLabel: t("Descartar todo"),
    });
    if (!proceed) return;
    restoreAllDocumentChanges(state.data.documents);
    for (const document of Object.values(state.world ?? {})) restoreWorldDocument(document);
    for (const entry of state.ebdx?.entries ?? []) {
      for (const field of Object.keys(entry.originalValues)) entry.values[field] = entry.originalValues[field];
      entry.dirty = false;
    }
    if (state.ebdx) state.ebdx.dirty = false;
    state.pendingLists.clear();
    state.ebdxHistory = { undo: [], redo: [], transaction: null };
    state.data.validation = validateWorkspace(state.data.documents, state.data.types);
    closeChangesPanel();
    renderAll();
    requestAnimationFrame(() => els.saveMeta.focus());
  }

  function renderChangesPanel(changes, issues = pendingPanelIssues()) {
    if (!changes.length) state.changesOpen = false;
    els.saveMeta.setAttribute("aria-expanded", String(state.changesOpen));
    els.saveMeta.setAttribute("aria-label", t("Revisar cambios pendientes"));
    els.changesPanel.setAttribute("aria-label", t("Cambios pendientes"));
    els.changesPanel.hidden = !state.changesOpen;
    els.changesPanel.innerHTML = "";
    if (!changes.length) return;

    const errors = issues.filter((issue) => issue.level === "error");
    const warnings = issues.filter((issue) => issue.level === "warning");
    const heading = h("div", { className: "pepbs-changes-head" },
      h("strong", { text: t("Cambios pendientes") }),
      h("span", { className: "pepbs-changes-head-actions" },
        h("span", { className: "pepbs-changes-head-counts" },
          errors.length ? h("span", { className: "pepbs-changes-issue-count is-error", text: `${errors.length} ${t(errors.length === 1 ? "error" : "errores")}` }) : null,
          warnings.length ? h("span", { className: "pepbs-changes-issue-count is-warning", text: `${warnings.length} ${t(warnings.length === 1 ? "aviso" : "avisos")}` }) : null,
          h("span", { className: "pepbs-changes-count", text: String(changes.length) }),
        ),
        h("button", {
          type: "button", className: "pepbs-btn pepbs-btn-quiet pepbs-discard-all",
          text: t("Descartar todo"), title: t("Descartar todos los cambios"),
          "aria-label": t("Descartar todos los cambios"), onClick: () => discardAllPendingChanges(changes),
        }),
      ),
    );
    const body = h("div", { className: "pepbs-changes-body" });
    const attachedIssue = (change) => issues
      .filter((issue) => issue.kind === change.kind && issue.key === change.entry?.key)
      .sort((left, right) => (left.level === "error" ? 0 : 1) - (right.level === "error" ? 0 : 1))[0] || null;
    const orphanIssues = issues.filter((issue) => !changes.some((change) => issue.kind === change.kind && issue.key === change.entry?.key));
    if (orphanIssues.length) {
      const warningList = h("div", { className: "pepbs-warning-list" });
      orphanIssues.forEach((issue) => {
        const entry = issueEntry(issue);
        const location = issueLocation(issue);
        const label = `${t(issue.level === "error" ? "Error" : "Ver aviso")}: ${location}`;
        const row = h(entry ? "button" : "div", {
          type: entry ? "button" : undefined,
          className: `pepbs-warning-row is-${issue.level}`,
          title: label,
          "aria-label": entry ? label : undefined,
          onClick: entry ? () => openPendingIssue(issue) : undefined,
        },
        h("span", { className: "pepbs-warning-mark", "aria-hidden": "true", text: "!" }),
        h("span", { className: "pepbs-warning-copy" },
          h("strong", { text: location }),
          h("small", { text: t(issue.message) }),
        ),
        entry ? h("span", { className: "pepbs-warning-open", "aria-hidden": "true", text: "›" }) : null);
        warningList.appendChild(row);
      });
      body.append(
        h("div", { className: "pepbs-warning-head" },
          h("strong", { text: t("Errores y avisos") }),
          h("span", { text: String(orphanIssues.length) }),
        ),
        warningList,
      );
    }
    const list = h("div", { className: "pepbs-changes-list", role: "list" });
    changes.forEach((change, index) => {
      const name = displayName(change.kind, change.entry, state.data.documents) || internalName(change.kind, change.entry);
      const location = `${changeKindLabel(change.kind)} / ${name}`;
      const undoLabel = `${t("Deshacer cambio")}: ${name}`;
      const issue = attachedIssue(change);
      const canOpen = change.status !== "deleted";
      const openLabel = `${t("Abrir cambio")}: ${location}${issue ? `. ${t(issue.message)}` : ""}`;
      const open = h(canOpen ? "button" : "div", {
        type: canOpen ? "button" : undefined,
        className: "pepbs-change-open",
        title: canOpen ? openLabel : undefined,
        "aria-label": canOpen ? openLabel : undefined,
        onClick: canOpen ? () => openPendingChange(change, issue) : undefined,
      },
      h("span", { className: "pepbs-change-kind", "aria-hidden": "true" }, createDomainIcon(change.kind), issue ? h("i", { className: `pepbs-change-issue-dot is-${issue.level}`, text: "!" }) : null),
      h("span", { className: "pepbs-change-copy" },
        h("strong", { text: location, title: location }),
        h("small", { text: changeSummary(change) }),
        issue ? h("small", { className: `pepbs-change-issue is-${issue.level}`, text: `${t(issue.level === "error" ? "Error" : "Aviso")} · ${changeFieldLabel(issue.kind, issue.field)}: ${t(issue.message)}`, title: t(issue.message) }) : null,
      ));
      list.appendChild(h("div", { className: `pepbs-change-row is-${change.status} ${issue ? `has-${issue.level}` : ""}`, role: "listitem" },
        open,
        h("button", { type: "button", className: "pepbs-btn pepbs-btn-quiet pepbs-change-undo", text: t("Deshacer"), title: undoLabel, "aria-label": undoLabel, onClick: () => discardPendingChange(change, index) }),
      ));
    });
    body.appendChild(list);
    els.changesPanel.append(heading, body);
  }

  function renderSaveState() {
    const changes = pendingChanges();
    const errors = pendingErrors();
    const warnings = pendingWarnings();
    const count = changes.length;
    els.save.disabled = count === 0 || state.saving;
    els.saveMeta.disabled = count === 0 || state.saving;
    els.save.textContent = t(state.saving ? "Guardando…" : "Guardar cambios");
    const changeLabel = count ? t(`${count} ${count === 1 ? "registro modificado" : "registros modificados"}`) : t("Sin cambios");
    els.saveMeta.replaceChildren(h("span", { text: changeLabel }));
    if (errors.length) {
      const errorLabel = `${errors.length} ${t(errors.length === 1 ? "error" : "errores")}`;
      els.saveMeta.appendChild(h("span", { className: "pepbs-save-error-count", text: String(errors.length), title: errorLabel, "aria-label": errorLabel }));
    }
    if (warnings.length) {
      const warningLabel = `${warnings.length} ${t(warnings.length === 1 ? "aviso" : "avisos")}`;
      els.saveMeta.appendChild(h("span", { className: "pepbs-save-warning-count", text: String(warnings.length), title: warningLabel, "aria-label": warningLabel }));
    }
    renderChangesPanel(changes, [...errors, ...warnings]);
  }

  function renderFooter() {
    const validation = state.data.validation;
    els.footer.innerHTML = "";
    const kind = actualKind();
    if (kind === "ebdx") {
      const dirty = dirtyEbdxEntries().length;
      if (dirty) els.footer.appendChild(h("span", { className: "pepbs-footer-ok", role: "status", text: t(`${dirty} ${dirty === 1 ? "posición EBDX modificada" : "posiciones EBDX modificadas"}`) }));
      return;
    }
    if (isWorldKind(kind)) {
      const issues = validateWorldDocument(documentFor(kind), worldContext());
      if (issues.length) els.footer.appendChild(h("span", { className: "error", role: "status", text: `${t("Error")}: ${t(issues[0].message)}${issues.length > 1 ? ` · +${issues.length - 1}` : ""}` }));
      return;
    }
    const errors = validation.errors.filter((item) => item.kind === kind);
    const warnings = validation.warnings.filter((item) => item.kind === kind);
    const primary = errors[0] || warnings[0];
    if (!primary) return;
    const total = primary.level === "error" ? errors.length : warnings.length;
    const extra = total > 1 ? ` · +${total - 1}` : "";
    const message = t(primary.message);
    els.footer.appendChild(h("span", { className: primary.level === "error" ? "error" : "warning", role: "status", title: message, text: `${t(primary.level === "error" ? "Error" : "Aviso")}: ${message}${extra}` }));
  }

  function ensureSelection() {
    const kind = actualKind(); const entries = entriesFor(kind);
    if (!entries.some((entry) => entry.key === state.selected[kind])) state.selected[kind] = entries[0]?.key;
  }

  function renderAll() {
    if (!state.data) return;
    root.classList.toggle("is-ebdx", state.activeKind === "ebdx");
    root.classList.toggle("is-townmap", state.activeKind === "townMap");
    root.classList.toggle("is-connections", state.activeKind === "connections");
    els.preview.hidden = state.activeKind === "ebdx" || state.activeKind === "townMap" || state.activeKind === "connections";
    ensureSelection(); renderRail(); renderCatalogHead(); renderCatalogList(); renderDetail(); renderPreview(); renderIssues(); renderSaveState(); renderFooter();
  }

  function dirtyIssues(validation) {
    const dirtyKeys = new Map();
    for (const [kind, document] of Object.entries(state.data.documents)) dirtyKeys.set(kind, new Set(document.entries.filter((entry) => entry.dirty).map((entry) => entry.key)));
    const hasDeletion = Object.values(state.data.documents).some((document) => document.deletedEntries?.length);
    return validation.issues.filter((item) => (hasDeletion && item.level === "error") || dirtyKeys.get(item.kind)?.has(item.key) || (item.key === "file" && documentFor(item.kind)?.dirty));
  }

  async function saveAll() {
    if (!hasUnsavedChanges() || state.saving) return true;
    clearTimeout(validationTimer);
    state.data.validation = validateWorkspace(state.data.documents, state.data.types);
    const relevant = dirtyIssues(state.data.validation);
    const worldIssues = dirtyWorldDocuments().flatMap((document) => validateWorldDocument(document, worldContext()));
    const errors = [...relevant.filter((item) => item.level === "error"), ...worldIssues.filter((item) => item.level === "error")];
    if (errors.length) {
      renderAll();
      const first = t(errors[0].message);
      const extra = errors.length > 1 ? ` · +${errors.length - 1}` : "";
      showNotice(`${t("No se ha guardado")}: ${first}${extra}`, "error");
      return false;
    }
    const warnings = pendingWarnings();
    if (warnings.length) {
      const proceed = await ctx.ui.showConfirmDialog({
        title: t("Guardar con avisos"),
        message: t(`Hay ${warnings.length} avisos en las entradas modificadas. No son incompatibilidades de formato, pero conviene revisarlos. ¿Guardar de todos modos?`),
        confirmLabel: t("Guardar"),
      });
      if (!proceed) return false;
    }

    state.saving = true; renderSaveState();
    const plans = [];
    try {
      for (const document of dirtyDocuments()) {
        const output = serializeDocument(document);
        const parsed = verifySerialization(document, output);
        plans.push({ scope: "pbs", kind: document.kind, parsed, path: document.path, backup: backupPath(document.path), originalText: document.originalText, output });
      }
      const mapNames = new Map(state.maps.map((map) => [map.id, map.name]));
      for (const document of dirtyWorldDocuments()) {
        const output = serializeWorldDocument(document, mapNames);
        const parsed = verifyWorldSerialization(document, output, worldContext());
        plans.push({ scope: "world", kind: document.kind, parsed, path: document.path, backup: worldBackupPath(document.path), originalText: document.info.text, output });
      }
      if (dirtyEbdxEntries().length) {
        const output = serializeEbdxWorkspace(state.ebdx);
        verifyEbdxSerialization(state.ebdx, output);
        plans.push({ scope: "ebdx", kind: "ebdx", path: state.ebdx.path, backup: ebdxBackupPath(state.ebdx.path), originalText: state.ebdx.originalText, output });
      }
      await writePlansAtomically(ctx.fs, plans);
      const selected = { ...state.selected };
      const nextDocuments = { ...state.data.documents };
      const nextWorld = { ...state.world };
      for (const plan of plans) {
        if (plan.scope === "pbs") nextDocuments[plan.kind] = plan.parsed;
        else if (plan.scope === "world") nextWorld[plan.kind] = plan.parsed;
      }
      initializeDocumentTracking(nextDocuments);
      state.data = { documents: nextDocuments, types: state.data.types, validation: validateWorkspace(nextDocuments, state.data.types) };
      state.world = nextWorld;
      if (state.ebdx) {
        const ebdxPlan = plans.find((plan) => plan.scope === "ebdx");
        state.ebdx = buildEbdxWorkspace(ebdxPlan?.output ?? state.ebdx.originalText, nextDocuments, Boolean(ebdxPlan || state.ebdx.exists));
      }
      state.ebdxHistory = { undo: [], redo: [], transaction: null };
      state.selected = selected;
      renderAll();
      showNotice(t(`${plans.length} archivos guardados y comprobados. Compila los datos en modo Debug para aplicar los cambios.`));
      ctx.log.info(`Data Editor saved: ${plans.map((plan) => plan.path).join(", ")}. Backups created.`);
      return true;
    } catch (error) {
      ctx.log.error(`Data Editor could not save: ${error?.stack || error}`);
      const prefix = error?.partialSave ? "El guardado falló y no se pudo restaurar todo" : "No se guardó ningún cambio";
      showNotice(t(`${prefix}: ${t(error?.message || error)}`), "error");
      return false;
    } finally {
      state.saving = false; renderSaveState();
    }
  }

  els.save.addEventListener("click", saveAll);
  els.saveMeta.addEventListener("click", () => {
    if (els.saveMeta.disabled) return;
    state.changesOpen = !state.changesOpen;
    renderChangesPanel(pendingChanges(), pendingPanelIssues());
    if (state.changesOpen) els.changesPanel.focus();
  });
  const onDocumentPointerDown = (event) => {
    if (!state.changesOpen || els.changeReview.contains(event.target)) return;
    closeChangesPanel();
  };
  document.addEventListener("pointerdown", onDocumentPointerDown);
  const onKeyDown = (event) => {
    if (!host.isConnected) return;
    if (event.key === "Escape" && state.changesOpen) {
      event.preventDefault();
      closeChangesPanel(true);
      return;
    }
    const command = event.ctrlKey || event.metaKey;
    const key = event.key.toLowerCase();
    if (command && !event.altKey && state.activeKind === "ebdx") {
      const wantsRedo = (key === "z" && event.shiftKey) || key === "y";
      if (key === "z" || wantsRedo) {
        event.preventDefault();
        event.stopImmediatePropagation();
        if (wantsRedo) redoEbdx();
        else undoEbdx();
        return;
      }
    }
    if (command && key === "s") {
      event.preventDefault(); event.stopImmediatePropagation(); saveAll();
    }
  };
  window.addEventListener("keydown", onKeyDown, { capture: true });

  (async () => {
    try {
      const [pbsData, worldData, resources] = await Promise.all([loadDocuments(ctx), loadWorldDocuments(ctx), projectAssets.initialize()]);
      state.data = pbsData;
      state.world = worldData;
      state.maps = [...(ctx.projectData?.maps?.() ?? [])].sort((a, b) => a.id - b.id);
      initializeDocumentTracking(state.data.documents);
      state.ebdx = await loadEbdxWorkspace(ctx, state.data.documents);
      state.assets = { ...resources.audio, ...resources.graphics };
      ensureSelection(); renderAll();
      if (state.data.validation.errors.length) ctx.log.warn(`Data Editor loaded with ${state.data.validation.errors.length} existing validation errors.`);
    } catch (error) {
      ctx.log.error(`Data Editor failed to load: ${error?.stack || error}`);
      els.editor.innerHTML = "";
      els.editor.appendChild(h("div", { className: "pepbs-empty", text: t(`No se pudieron cargar los PBS requeridos. ${t(error?.message || error)}`) }));
      els.saveMeta.textContent = t("Error de carga");
      showNotice(t("No se pudieron leer los PBS requeridos, incluidos trainers.txt y trainertypes.txt."), "error", 0);
    }
  })();

  return {
    hasUnsavedChanges,
    saveAll,
    dispose() {
      state.disposed = true; clearTimeout(validationTimer); clearTimeout(previewTimer); ebdxCleanup?.(); mapVisuals.clear(); projectAssets.dispose();
      window.removeEventListener("keydown", onKeyDown, { capture: true });
      document.removeEventListener("pointerdown", onDocumentPointerDown);
    },
  };
}
