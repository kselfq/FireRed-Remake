import { dropdown, h, switchControl } from "../ui/ui_utils.js";
import { t } from "../ui/i18n.js";
import { layoutConnectionWorld } from "./map_visuals.js";
import { encounterTriggerChanceApplies, metadataFieldDependency } from "../pbs/field_dependencies.js";
import { ESSENTIALS_MAX_LEVEL } from "../pbs/schema.js";
import {
  DIRECTIONS,
  ENCOUNTER_TYPES,
  ENVIRONMENTS,
  GLOBAL_METADATA_ORDER,
  MAP_METADATA_ORDER,
  OPPOSITE_DIRECTION,
  WEATHER_TYPES,
  splitCsv,
} from "./world_data.js";

const FIELD_LABELS = Object.freeze({
  Home: "Punto de inicio", WildBattleBGM: "Música de combate salvaje", TrainerBattleBGM: "Música de combate de entrenador",
  WildVictoryME: "Victoria contra Pokémon salvaje", TrainerVictoryME: "Victoria contra entrenador", WildCaptureME: "Captura de Pokémon",
  SurfBGM: "Música de surf", BicycleBGM: "Música de bicicleta", Outdoor: "Mapa exterior", ShowArea: "Mostrar nombre al entrar",
  Bicycle: "Permitir bicicleta", BicycleAlways: "Bicicleta obligatoria", HealingSpot: "Punto de curación", Weather: "Clima",
  MapPosition: "Posición en el mapa regional", DiveMap: "Mapa submarino", DarkMap: "Mapa oscuro", SafariMap: "Zona Safari",
  SnapEdges: "Ajustar bordes", Dungeon: "Mazmorra aleatoria", BattleBack: "Fondo de combate", MapSize: "Tamaño regional", Environment: "Entorno de combate",
});

function input(value, onInput, options = {}) {
  const element = h("input", { className: "pepbs-input", value: value ?? "", type: options.type || "text", min: options.min, max: options.max, step: options.step, placeholder: options.placeholder || "", disabled: options.disabled });
  element.addEventListener("input", () => onInput(element.value));
  return element;
}

function select(value, values, onChange, options = {}) {
  const items = [];
  if (options.empty !== false) items.push(["", options.emptyLabel || t("Predeterminado del juego")]);
  for (const item of values) {
    const pair = Array.isArray(item) ? item : [item, item];
    items.push([String(pair[0]), String(pair[1])]);
  }
  return dropdown(value, items, onChange, { label: options.label || "", searchPlaceholder: t("Buscar opciones…"), noMatches: t("No hay coincidencias."), searchable: options.searchable });
}

function field(label, control, options = {}) {
  const wrapper = h("div", {
    className: `pepbs-world-field ${options.wide ? "is-wide" : ""} ${options.disabled ? "is-dependency-disabled" : ""}`.trim(),
    inert: options.disabled,
    "aria-disabled": options.disabled ? "true" : null,
    title: options.disabled && options.reason ? t(options.reason) : null,
  }, h("span", { text: t(label) }), control);
  if (options.disabled) wrapper.querySelectorAll("input, textarea, button").forEach((element) => { element.disabled = true; });
  return wrapper;
}

function action(label, onClick, className = "") {
  return h("button", { type: "button", className: `pepbs-btn ${className}`, text: t(label), onClick });
}

function mapFailure(message, error) {
  const detail = String(error?.message || error || "").trim();
  return h("div", { className: "pepbs-map-error" }, h("strong", { text: t(message) }), detail ? h("code", { text: detail }) : null);
}

function mapOptions(maps) { return maps.map((map) => [map.id, `${String(map.id).padStart(3, "0")} · ${map.name}`]); }

function resourceSelect(value, values, onChange, emptyLabel = "Predeterminado del juego") {
  return select(value, values.map((name) => [name, name]), onChange, { emptyLabel: t(emptyLabel) });
}

function checkbox(value, onChange) {
  return switchControl(String(value).toLowerCase() === "true", (checked) => onChange(checked ? "true" : ""));
}

function pickerSummary(mapName, x, y) {
  if (!mapName) return t("Elegir una casilla…");
  return mapName + " · " + t("casilla") + " " + Number(x || 0) + ", " + Number(y || 0);
}

function coordinateButton(label, onClick) {
  return h("button", {
    type: "button",
    className: "pepbs-coordinate-picker-button",
    onClick,
  }, h("span", { className: "pepbs-coordinate-picker-icon", text: "⌖" }), h("span", { text: label }), h("span", { className: "pepbs-coordinate-picker-arrow", text: "›" }));
}

function dialogShell(dialogs, title, onClose) {
  const backdrop = h("div", { className: "pepbs-dialog-backdrop pepbs-map-dialog-backdrop" });
  const dialog = h("section", { className: "pepbs-map-dialog", role: "dialog", "aria-modal": "true", "aria-label": title });
  const close = () => { backdrop.remove(); onClose?.(); };
  backdrop.addEventListener("pointerdown", (event) => { if (event.target === backdrop) close(); });
  backdrop.appendChild(dialog);
  dialogs.appendChild(backdrop);
  return { backdrop, dialog, close };
}

function enablePanZoom(viewport, content, options = {}) {
  let scale = options.initialScale || 1;
  let drag = null;
  const apply = () => { content.style.transform = "scale(" + scale + ")"; content.style.setProperty("--pepbs-view-scale", scale); options.onScale?.(scale); };
  const zoom = (next, clientX, clientY) => {
    const old = scale;
    scale = Math.max(options.minScale || 0.25, Math.min(options.maxScale || 4, next));
    if (old === scale) return;
    const rect = viewport.getBoundingClientRect();
    const pointX = clientX == null ? rect.width / 2 : clientX - rect.left;
    const pointY = clientY == null ? rect.height / 2 : clientY - rect.top;
    const worldX = (viewport.scrollLeft + pointX) / old;
    const worldY = (viewport.scrollTop + pointY) / old;
    apply();
    viewport.scrollLeft = worldX * scale - pointX;
    viewport.scrollTop = worldY * scale - pointY;
  };
  viewport.addEventListener("wheel", (event) => {
    if (!event.ctrlKey && !options.wheelAlways) return;
    event.preventDefault();
    zoom(scale * (event.deltaY < 0 ? 1.12 : 0.89), event.clientX, event.clientY);
  }, { passive: false });
  viewport.addEventListener("pointerdown", (event) => {
    // Map labels are buttons. Let a plain left click reach them; the canvas
    // background and the middle mouse button remain available for panning.
    if (event.button === 0 && event.target instanceof Element && event.target.closest("button, input, select, textarea, a")) return;
    const leftPan = event.button === 0 && (options.panAnywhere || event.target === viewport || event.target === content);
    if (event.button !== 1 && !leftPan) return;
    drag = { x: event.clientX, y: event.clientY, left: viewport.scrollLeft, top: viewport.scrollTop, moved: false };
    viewport.setPointerCapture(event.pointerId);
    viewport.classList.add("is-panning");
  });
  viewport.addEventListener("pointermove", (event) => {
    if (!drag) return;
    const dx = event.clientX - drag.x, dy = event.clientY - drag.y;
    if (Math.abs(dx) + Math.abs(dy) > 4) drag.moved = true;
    viewport.scrollLeft = drag.left - dx;
    viewport.scrollTop = drag.top - dy;
  });
  const finishDrag = () => {
    if (drag?.moved) viewport.dataset.justPanned = "true";
    drag = null; viewport.classList.remove("is-panning");
    setTimeout(() => { delete viewport.dataset.justPanned; }, 0);
  };
  viewport.addEventListener("pointerup", finishDrag);
  viewport.addEventListener("pointercancel", finishDrag);
  viewport.addEventListener("lostpointercapture", finishDrag);
  const focus = (bounds, focusOptions = {}) => {
    if (!bounds || !bounds.width || !bounds.height) return;
    const padding = focusOptions.padding ?? 28;
    const width = Math.max(1, viewport.clientWidth - padding * 2);
    const height = Math.max(1, viewport.clientHeight - padding * 2);
    const target = Math.min(width / bounds.width, height / bounds.height, focusOptions.maxScale ?? options.maxScale ?? 4);
    scale = Math.max(options.minScale || 0.25, Math.min(options.maxScale || 4, target));
    apply();
    viewport.scrollLeft = (bounds.x + bounds.width / 2) * scale - viewport.clientWidth / 2;
    viewport.scrollTop = (bounds.y + bounds.height / 2) * scale - viewport.clientHeight / 2;
  };
  apply();
  const viewState = () => ({ scale, left: viewport.scrollLeft, top: viewport.scrollTop });
  const restore = (view) => {
    if (!view || !Number.isFinite(Number(view.scale))) return;
    scale = Math.max(options.minScale || 0.25, Math.min(options.maxScale || 4, Number(view.scale)));
    apply();
    viewport.scrollLeft = Math.max(0, Number(view.left) || 0);
    viewport.scrollTop = Math.max(0, Number(view.top) || 0);
  };
  return { zoomIn: () => zoom(scale * 1.2), zoomOut: () => zoom(scale / 1.2), reset: () => { scale = 1; apply(); }, focus, value: () => scale, viewState, restore };
}

function openMapCoordinateDialog(options) {
  const { dialogs, maps, mapVisuals, value, facing, onApply, allowEmpty = true, defaultMapId = 0 } = options;
  const parts = splitCsv(value);
  const savedMapId = Number(parts[0] || 0);
  const preferredMapId = Number(defaultMapId || 0);
  let mapId = maps.some((map) => Number(map.id) === savedMapId)
    ? savedMapId
    : maps.some((map) => Number(map.id) === preferredMapId) ? preferredMapId : Number(maps[0]?.id || 0);
  let x = Number(parts[1] || 0), y = Number(parts[2] || 0), direction = String(parts[3] || 2);
  if (!["2", "4", "6", "8"].includes(direction)) direction = "2";
  const shell = dialogShell(dialogs, t("Elegir una casilla"), null);
  const mapSelect = select(mapId, mapOptions(maps), (next) => { mapId = Number(next); x = 0; y = 0; renderMap(); }, { empty: false });
  const coordinates = h("span", { className: "pepbs-map-dialog-coordinates" });
  const viewport = h("div", { className: "pepbs-map-picker-viewport" });
  const stage = h("div", { className: "pepbs-map-picker-stage" });
  viewport.appendChild(stage);
  const zoomLabel = h("span", { className: "pepbs-zoom-label", text: "100%" });
  const panZoom = enablePanZoom(viewport, stage, { minScale: 0.5, maxScale: 3, wheelAlways: true, onScale: (scale) => { zoomLabel.textContent = Math.round(scale * 100) + "%"; } });
  const updateCoordinates = () => { coordinates.textContent = t("Casilla") + " " + x + ", " + y; };
  const renderMap = async () => {
    const token = String(Date.now()) + Math.random(); stage.dataset.token = token;
    stage.innerHTML = ""; stage.classList.add("is-loading");
    stage.appendChild(h("div", { className: "pepbs-map-loading", text: t("Cargando mapa…") }));
    try {
      const visual = await mapVisuals.render(mapId, 16);
      if (stage.dataset.token !== token || !stage.isConnected) return;
      stage.innerHTML = ""; stage.classList.remove("is-loading");
      stage.style.width = visual.canvas.width + "px"; stage.style.height = visual.canvas.height + "px";
      const marker = h("span", { className: "pepbs-map-cell-marker" });
      const placeMarker = () => { marker.style.left = (x * visual.tileSize) + "px"; marker.style.top = (y * visual.tileSize) + "px"; };
      visual.canvas.addEventListener("click", (event) => {
        if (viewport.dataset.justPanned) return;
        const rect = visual.canvas.getBoundingClientRect();
        x = Math.max(0, Math.min(visual.width - 1, Math.floor((event.clientX - rect.left) * visual.canvas.width / rect.width / visual.tileSize)));
        y = Math.max(0, Math.min(visual.height - 1, Math.floor((event.clientY - rect.top) * visual.canvas.height / rect.height / visual.tileSize)));
        placeMarker(); updateCoordinates();
      });
      stage.append(visual.canvas, marker); placeMarker(); updateCoordinates();
      requestAnimationFrame(() => { viewport.scrollLeft = Math.max(0, x * visual.tileSize - viewport.clientWidth / 2); viewport.scrollTop = Math.max(0, y * visual.tileSize - viewport.clientHeight / 2); });
    } catch (error) {
      stage.classList.remove("is-loading"); stage.innerHTML = "";
      stage.appendChild(mapFailure("No se pudo cargar este mapa.", error));
    }
  };
  const header = h("header", { className: "pepbs-map-dialog-head" }, h("div", {}, h("h2", { text: t("Elegir una casilla") }), h("p", { text: t("Haz clic en el mapa para elegir la posición.") })), h("button", { type: "button", className: "pepbs-dialog-close", text: "×", onClick: shell.close }));
  const toolbar = h("div", { className: "pepbs-map-dialog-toolbar" }, mapSelect, coordinates, h("div", { className: "pepbs-zoom-controls" }, action("−", panZoom.zoomOut, "pepbs-btn-compact"), zoomLabel, action("+", panZoom.zoomIn, "pepbs-btn-compact")));
  const footer = h("footer", { className: "pepbs-dialog-actions" });
  if (allowEmpty) footer.appendChild(action("Quitar posición", () => { onApply(""); shell.close(); }, "pepbs-btn-quiet pepbs-btn-danger"));
  footer.append(action("Cancelar", shell.close, "pepbs-btn-quiet"), action("Usar esta casilla", () => { onApply([mapId, x, y].concat(facing ? [direction] : []).join(",")); shell.close(); }, "pepbs-btn-primary"));
  if (facing) {
    const directionControl = h("div", { className: "pepbs-direction-control" }, h("span", { text: t("Dirección") }));
    const directionButtons = h("div", { className: "pepbs-direction-buttons", role: "group", "aria-label": t("Dirección") });
    const buttons = [];
    const refreshDirection = () => buttons.forEach(([value, button]) => {
      const active = direction === value;
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-pressed", String(active));
    });
    for (const [value, arrow, label] of [["8", "↑", "Arriba"], ["2", "↓", "Abajo"], ["4", "←", "Izquierda"], ["6", "→", "Derecha"]]) {
      const button = h("button", { type: "button", className: "pepbs-direction-button", text: arrow, title: t(label), "aria-label": t(label), onClick: () => { direction = value; refreshDirection(); } });
      buttons.push([value, button]); directionButtons.appendChild(button);
    }
    refreshDirection(); directionControl.appendChild(directionButtons); toolbar.insertBefore(directionControl, toolbar.lastChild);
  }
  shell.dialog.append(header, toolbar, viewport, footer);
  renderMap();
}

function mapCoordinateControl(value, maps, onChange, facing = false, options = {}) {
  const parts = splitCsv(value);
  const mapName = maps.find((map) => Number(map.id) === Number(parts[0]))?.name;
  return coordinateButton(pickerSummary(mapName, parts[1], parts[2]), () => openMapCoordinateDialog({ ...options, maps, value, facing, onApply: onChange }));
}

function normalizedMapName(value) {
  return String(value || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").trim().toLocaleLowerCase("es");
}

export function findTownMapPointMapId(regionId, point, metadataEntries, maps) {
  const region = Number(regionId);
  const x = Number(point?.x);
  const y = Number(point?.y);
  const candidates = (metadataEntries || []).filter((metadata) => {
    const [mapRegion, mapX, mapY] = splitCsv(metadata.values?.MapPosition).map(Number);
    return Number(metadata.mapId) > 0 && mapRegion === region && mapX === x && mapY === y;
  });
  if (!candidates.length) return Number(maps[0]?.id || 0);
  const pointName = normalizedMapName(point?.name);
  const named = pointName && candidates.find((metadata) => {
    const mapName = maps.find((map) => Number(map.id) === Number(metadata.mapId))?.name;
    return normalizedMapName(mapName) === pointName;
  });
  const outdoor = candidates.find((metadata) => String(metadata.values?.Outdoor).toLowerCase() === "true");
  return Number((named || outdoor || candidates[0]).mapId);
}

function openRegionCoordinateDialog(options) {
  const { dialogs, regions, value, loadImage, onApply } = options;
  const parts = splitCsv(value);
  let regionId = Number(parts[0] || regions[0]?.regionId || 0), x = Number(parts[1] || 0), y = Number(parts[2] || 0);
  const shell = dialogShell(dialogs, t("Elegir una casilla regional"), null);
  const viewport = h("div", { className: "pepbs-map-picker-viewport pepbs-region-picker-viewport" });
  const stage = h("div", { className: "pepbs-map-picker-stage" }); viewport.appendChild(stage);
  const coordinates = h("span", { className: "pepbs-map-dialog-coordinates" });
  const regionSelect = select(regionId, regions.map((region) => [region.regionId, region.regionId + " · " + region.name]), (next) => { regionId = Number(next); x = 0; y = 0; renderRegion(); }, { empty: false });
  const renderRegion = async () => {
    const region = regions.find((item) => Number(item.regionId) === regionId); stage.innerHTML = "";
    const filename = String(region?.filename || "").replace(/^Graphics[\\/]Pictures[\\/]/i, "");
    const url = filename ? await loadImage(["Graphics/Pictures/" + filename, "Graphics/Pictures/" + filename + ".png"]) : null;
    if (!url || !stage.isConnected) { stage.appendChild(h("div", { className: "pepbs-map-error", text: t("No se pudo cargar esta imagen regional.") })); return; }
    const image = h("img", { src: url, alt: region?.name || "", draggable: "false" });
    image.onload = () => {
      stage.style.width = image.naturalWidth + "px"; stage.style.height = image.naturalHeight + "px";
      const marker = h("span", { className: "pepbs-map-cell-marker is-region" });
      const place = () => { marker.style.left = (x * 16) + "px"; marker.style.top = (y * 16) + "px"; coordinates.textContent = t("Casilla") + " " + x + ", " + y; };
      image.addEventListener("click", (event) => { const rect = image.getBoundingClientRect(); x = Math.max(0, Math.floor((event.clientX - rect.left) * image.naturalWidth / rect.width / 16)); y = Math.max(0, Math.floor((event.clientY - rect.top) * image.naturalHeight / rect.height / 16)); place(); });
      stage.appendChild(marker); place();
    }; stage.appendChild(image);
  };
  shell.dialog.append(h("header", { className: "pepbs-map-dialog-head" }, h("div", {}, h("h2", { text: t("Elegir una casilla regional") }), h("p", { text: t("Haz clic en el mapa regional para elegir la posición.") })), h("button", { type: "button", className: "pepbs-dialog-close", text: "×", onClick: shell.close })), h("div", { className: "pepbs-map-dialog-toolbar" }, regionSelect, coordinates), viewport, h("footer", { className: "pepbs-dialog-actions" }, action("Quitar posición", () => { onApply(""); shell.close(); }, "pepbs-btn-quiet pepbs-btn-danger"), action("Cancelar", shell.close, "pepbs-btn-quiet"), action("Usar esta casilla", () => { onApply([regionId, x, y].join(",")); shell.close(); }, "pepbs-btn-primary")));
  renderRegion();
}

function regionCoordinateControl(value, regions, onChange, options = {}) {
  const parts = splitCsv(value);
  const region = regions.find((item) => Number(item.regionId) === Number(parts[0]));
  return coordinateButton(pickerSummary(region?.name, parts[1], parts[2]), () => openRegionCoordinateDialog({ ...options, regions, value, onApply: onChange }));
}

function playerControl(key, value, data, onChange, loadImage, createReferenceInput) {
  const values = splitCsv(value);
  while (values.length < 8) values.push("");
  const labels = ["Tipo de entrenador", "Caminar", "Bicicleta", "Surf", "Correr", "Bucear", "Pescar", "Pescar en surf"];
  const wrap = h("section", { className: "pepbs-world-player" });
  const head = h("div", { className: "pepbs-world-player-head" }, h("strong", { text: key }), h("div", { className: "pepbs-world-player-preview" }));
  const preview = head.lastChild;
  const grid = h("div", { className: "pepbs-world-grid" });
  const emit = () => onChange(values.join(","));
  values.forEach((current, index) => {
    const update = (next) => { values[index] = next; emit(); if (index === 1) updatePreview(); };
    const control = index === 0
      ? createReferenceInput(current, "trainerTypes", update, t("— Sin valor —"))
      : resourceSelect(current, data.assets.characters, update, "— Sin valor —");
    grid.appendChild(field(labels[index], control));
  });
  async function updatePreview() {
    preview.innerHTML = "";
    const name = values[1];
    if (!name) return;
    const request = `${name}:${Date.now()}:${Math.random()}`;
    preview.dataset.request = request;
    const url = await loadImage([`Graphics/Characters/${name}.png`]);
    if (!url || !preview.isConnected || preview.dataset.request !== request) return;
    const image = new Image();
    image.alt = name;
    image.onload = () => {
      if (!preview.isConnected || preview.dataset.request !== request) return;
      const frameWidth = Math.max(1, Math.floor(image.naturalWidth / 4));
      const frameHeight = Math.max(1, Math.floor(image.naturalHeight / 4));
      const canvas = h("canvas", { className: "pepbs-world-player-frame", width: frameWidth, height: frameHeight, role: "img", "aria-label": name });
      const context = canvas.getContext("2d");
      context.imageSmoothingEnabled = false;
      context.drawImage(image, 0, 0, frameWidth, frameHeight, 0, 0, frameWidth, frameHeight);
      preview.innerHTML = ""; preview.appendChild(canvas);
    };
    image.src = url;
  }
  wrap.append(head, grid); updatePreview(); return wrap;
}

export function renderMetadataEditor(options) {
  const { container, entry, maps, data, onChange, loadImage, onDelete, dialogs, mapVisuals, createReferenceInput } = options;
  const global = entry.mapId === 0;
  const order = global ? GLOBAL_METADATA_ORDER : MAP_METADATA_ORDER;
  const form = h("div", { className: "pepbs-world-form" });
  const titleActions = h("div", { className: "pepbs-world-head-actions" }, entry.dirty ? h("span", { className: "pepbs-badge pepbs-badge-dirty", text: t("Modificado") }) : null, action("Eliminar", onDelete, "pepbs-btn-compact pepbs-btn-danger"));
  const title = h("header", { className: "pepbs-world-record-head" }, h("div", {}, h("h2", { text: global ? t("Configuración global") : (maps.find((map) => map.id === entry.mapId)?.name || `${t("Mapa")} ${entry.mapId}`) }), h("code", { text: `[${String(entry.mapId).padStart(3, "0")}]` })), titleActions);
  form.appendChild(title);
  const update = (key, next, rerender = false) => {
    entry.values[key] = next;
    onChange(entry);
    if (rerender) options.rerender();
  };
  const fields = new Map();
  for (const key of order) {
    if (/^Player[A-H]$/.test(key)) continue;
    const value = entry.values[key] || "";
    let control;
    if (["Outdoor", "ShowArea", "Bicycle", "BicycleAlways", "DarkMap", "SafariMap", "SnapEdges", "Dungeon"].includes(key)) control = checkbox(value, (next) => update(key, next, key === "BicycleAlways"));
    else if (key === "Home") control = mapCoordinateControl(value, maps, (next) => update(key, next), true, { dialogs, mapVisuals, allowEmpty: false });
    else if (key === "HealingSpot") control = mapCoordinateControl(value, maps, (next) => update(key, next), false, { dialogs, mapVisuals });
    else if (key === "DiveMap") control = select(value, mapOptions(maps), (next) => update(key, next), { emptyLabel: t("— Sin valor —") });
    else if (key === "MapPosition") control = regionCoordinateControl(value, data.world.townMap.entries, (next) => update(key, next, true), { dialogs, loadImage });
    else if (["WildBattleBGM", "TrainerBattleBGM", "SurfBGM", "BicycleBGM"].includes(key)) control = createReferenceInput(value.replace(/\.(mid|midi|ogg|mp3|wav)$/i, ""), "bgm", (next) => update(key, next), t("Buscar música…"));
    else if (["WildVictoryME", "TrainerVictoryME", "WildCaptureME"].includes(key)) control = createReferenceInput(value.replace(/\.(mid|midi|ogg|mp3|wav)$/i, ""), "me", (next) => update(key, next), t("Buscar música…"));
    else if (key === "BattleBack") control = createReferenceInput(value, "battlebacks", (next) => update(key, next), t("Buscar fondo de combate…"));
    else if (key === "Environment") control = select(value, ENVIRONMENTS, (next) => update(key, next), { emptyLabel: t("Predeterminado del juego") });
    else if (key === "Weather") {
      const parts = splitCsv(value); const row = h("div", { className: "pepbs-world-coordinate pepbs-world-weather" });
      let weatherType = parts[0] || "", weatherChance = parts[1] || "";
      const emit = () => update(key, weatherType ? `${weatherType},${weatherChance || 100}` : "");
      const chance = input(weatherChance, (next) => { weatherChance = next; emit(); }, { type: "number", min: 0, max: 100, placeholder: "%", disabled: !weatherType });
      const syncChance = () => {
        chance.disabled = !weatherType;
        chance.classList.toggle("is-dependency-disabled", !weatherType);
        chance.title = !weatherType ? t("El clima predeterminado no usa probabilidad.") : "";
      };
      syncChance();
      row.append(select(weatherType, WEATHER_TYPES.filter((type) => type !== "None"), (next) => { weatherType = next; emit(); syncChance(); }, { emptyLabel: t("Sin clima") }), chance); control = row;
    } else control = input(value, (next) => update(key, next));
    const dependency = metadataFieldDependency(key, entry.values);
    fields.set(key, field(FIELD_LABELS[key] || key, control, { disabled: !dependency.enabled, reason: dependency.reason }));
  }
  const section = (titleText, keys, gridClass = "") => {
    const grid = h("div", { className: `pepbs-metadata-grid ${gridClass}`.trim() });
    keys.forEach((key) => { if (fields.has(key)) grid.appendChild(fields.get(key)); });
    if (!grid.childElementCount) return null;
    return h("section", { className: "pepbs-metadata-section" }, h("h3", { text: t(titleText) }), grid);
  };
  if (global) {
    const location = section("Ubicación", ["Home"], "is-stack");
    const audio = section("Audio", ["WildBattleBGM", "TrainerBattleBGM", "WildVictoryME", "TrainerVictoryME", "WildCaptureME", "SurfBGM", "BicycleBGM"]);
    if (location) form.appendChild(h("div", { className: "pepbs-metadata-overview is-global" }, location));
    if (audio) form.appendChild(audio);
  } else {
    const overview = h("div", { className: "pepbs-metadata-overview" });
    const location = section("Ubicación y clima", ["MapPosition", "HealingSpot", "Weather"], "is-stack");
    const access = section("Acceso y navegación", ["Outdoor", "ShowArea", "Bicycle", "BicycleAlways"], "is-switches");
    if (location) overview.appendChild(location);
    if (access) overview.appendChild(access);
    form.appendChild(overview);

    const environment = h("section", { className: "pepbs-metadata-section" }, h("h3", { text: t("Entorno y combate") }));
    const environmentFields = h("div", { className: "pepbs-metadata-grid" });
    ["DiveMap", "BattleBack", "Environment", "MapSize"].forEach((key) => { if (fields.has(key)) environmentFields.appendChild(fields.get(key)); });
    const environmentSwitches = h("div", { className: "pepbs-metadata-grid is-switches is-secondary" });
    ["DarkMap", "SafariMap", "SnapEdges", "Dungeon"].forEach((key) => { if (fields.has(key)) environmentSwitches.appendChild(fields.get(key)); });
    environment.append(environmentFields, environmentSwitches);
    form.appendChild(environment);

    const audio = section("Audio del mapa", ["WildBattleBGM", "TrainerBattleBGM", "WildVictoryME", "TrainerVictoryME", "WildCaptureME"]);
    if (audio) form.appendChild(audio);
  }
  if (global) for (const key of GLOBAL_METADATA_ORDER.filter((item) => /^Player/.test(item))) form.appendChild(playerControl(key, entry.values[key] || "", data, (next) => update(key, next), loadImage, createReferenceInput));
  container.appendChild(form);
}

export function renderEncountersEditor(options) {
  const { container, entry, data, maps, onChange, loadPokemonIcon, createReferenceInput, rowActions, onDelete } = options;
  const root = h("div", { className: "pepbs-world-form" });
  const identity = h("div", { className: "pepbs-world-head-fields is-version-only" }, field("Versión", input(entry.version, (next) => { entry.version = Number(next); onChange(entry); }, { type: "number", min: 0 })));
  const headActions = h("div", { className: "pepbs-world-head-actions" }, action("+ Método", () => { entry.groups.push({ type: "Land", chance: "21", slots: [] }); onChange(entry, true); }, "pepbs-btn-compact"), action("Eliminar", onDelete, "pepbs-btn-compact pepbs-btn-danger"));
  const head = h("header", { className: "pepbs-world-record-head" }, h("div", {}, h("h2", { text: entry.mapName || `${t("Mapa")} ${entry.mapId}` }), h("code", { text: `[${String(entry.mapId).padStart(3, "0")}${entry.version ? `,${entry.version}` : ""}]` })), identity, headActions);
  root.appendChild(head);
  entry.groups.forEach((group, groupIndex) => {
    const section = h("section", { className: "pepbs-encounter-group" });
    const groupHead = h("div", { className: "pepbs-encounter-head" });
    const chanceApplies = encounterTriggerChanceApplies(group.type);
    const typeSelect = select(group.type, ENCOUNTER_TYPES.map(([id]) => id), (next) => { group.type = next; if (group.chance === "") group.chance = String(ENCOUNTER_TYPES.find(([id]) => id === next)?.[1] ?? ""); onChange(entry, true); }, { empty: false });
    groupHead.append(typeSelect, field("Probabilidad de activación", input(group.chance, (next) => { group.chance = next; onChange(entry); }, { type: "number", min: 0, max: 100, disabled: !chanceApplies }), { wide: false, disabled: !chanceApplies, reason: "Este método de encuentro se activa de forma directa." }), action("Eliminar método", () => { entry.groups.splice(groupIndex, 1); onChange(entry, true); }, "pepbs-btn-compact pepbs-btn-danger"));
    const table = h("div", { className: "pepbs-encounter-table" }, h("div", { className: "pepbs-encounter-labels" }, h("span", { text: "%" }), h("span", { text: t("Pokémon") }), h("span", { text: t("Nivel mínimo") }), h("span", { text: t("Nivel máximo") }), h("span")));
    group.slots.forEach((slot, slotIndex) => {
      const icon = h("span", { className: "pepbs-encounter-icon" });
      const showSpeciesIcon = (id) => {
        const match = String(id || "").match(/^(.*)_(\d+)$/);
        loadPokemonIcon(icon, match ? match[1] : id, match ? Number(match[2]) : 0);
      };
      const speciesPicker = createReferenceInput(slot.species, "encounterPokemon", (next) => { slot.species = next; onChange(entry); showSpeciesIcon(next); }, t("Buscar Pokémon…"), { showPokemonIcon: false });
      const speciesWrap = h("div", { className: "pepbs-encounter-species" }, icon, speciesPicker);
      showSpeciesIcon(slot.species);
      let minLevelInput;
      let maxLevelInput;
      minLevelInput = input(slot.minLevel, (next) => {
        slot.minLevel = next;
        if (String(next).trim() !== "" && Number.isFinite(Number(next)) && Number(slot.maxLevel) < Number(next)) {
          slot.maxLevel = next;
          maxLevelInput.value = next;
        }
        onChange(entry);
      }, { type: "number", min: 1, max: ESSENTIALS_MAX_LEVEL });
      maxLevelInput = input(slot.maxLevel, (next) => {
        slot.maxLevel = next;
        if (String(next).trim() !== "" && Number.isFinite(Number(next)) && Number(slot.minLevel) > Number(next)) {
          slot.minLevel = next;
          minLevelInput.value = next;
        }
        onChange(entry);
      }, { type: "number", min: 1, max: ESSENTIALS_MAX_LEVEL });
      table.appendChild(h("div", { className: "pepbs-encounter-row", "data-reorder-row": true }, input(slot.weight, (next) => { slot.weight = next; onChange(entry); }, { type: "number", min: 0, max: 100 }), speciesWrap, minLevelInput, maxLevelInput, rowActions(slotIndex, group.slots.length, (targetIndex) => { const [moved] = group.slots.splice(slotIndex, 1); group.slots.splice(targetIndex, 0, moved); onChange(entry, true); }, () => { group.slots.splice(slotIndex, 1); onChange(entry, true); })));
    });
    const slotWeight = (slot) => Number.isFinite(Number(slot.weight)) ? Number(slot.weight) : Number.NEGATIVE_INFINITY;
    const slotsAreSorted = group.slots.every((slot, index) => index === 0 || slotWeight(group.slots[index - 1]) >= slotWeight(slot));
    const addEncounter = action("+ Encuentro", () => {
      group.slots.push({ weight: "0", species: data.pokemon.entries[0]?.values.InternalName || "BULBASAUR", minLevel: "5", maxLevel: "5" });
      onChange(entry, true);
    }, "pepbs-add");
    const sortByWeight = action("Ordenar por porcentaje", () => {
      const ordered = group.slots.map((slot, index) => ({ slot, index })).sort((a, b) => slotWeight(b.slot) - slotWeight(a.slot) || a.index - b.index).map(({ slot }) => slot);
      group.slots.splice(0, group.slots.length, ...ordered);
      onChange(entry, true);
    }, "pepbs-btn-compact");
    sortByWeight.disabled = group.slots.length < 2 || slotsAreSorted;
    table.appendChild(h("div", { className: "pepbs-encounter-actions" }, addEncounter, sortByWeight));
    section.append(groupHead, table); root.appendChild(section);
  });
  container.appendChild(root);
}

export function renderConnectionsEditor(options) {
  const { container, entry, maps, onChange, onDelete, mapVisuals, data } = options;
  const update = () => onChange(entry);
  const root = h("div", { className: "pepbs-world-form pepbs-connection-form" });
  root.appendChild(h("header", { className: "pepbs-world-record-head" }, h("div", {}, h("h2", { text: t("Conexión de mapas") }), h("code", { text: `${entry.mapA} ${entry.directionA} ↔ ${entry.directionB} ${entry.mapB}` }))));
  const edgeMode = DIRECTIONS.includes(String(entry.directionA)) || DIRECTIONS.includes(String(entry.directionB));
  const connectionStage = h("div", { className: "pepbs-atlas-stage is-loading" }, h("div", { className: "pepbs-map-loading", text: t("Generando mapa completo…") }));
  const connectionViewport = h("div", { className: "pepbs-connection-viewport" }, connectionStage);
  const zoomLabel = h("span", { className: "pepbs-zoom-label", text: "100%" });
  const panZoom = enablePanZoom(connectionViewport, connectionStage, { minScale: 0.08, maxScale: 4, wheelAlways: true, panAnywhere: true, onScale: (scale) => { zoomLabel.textContent = Math.round(scale * 100) + "%"; } });
  const zoomOut = h("button", { type: "button", className: "pepbs-btn pepbs-btn-compact", text: "−", title: t("Alejar"), "aria-label": t("Alejar"), onClick: panZoom.zoomOut });
  const zoomIn = h("button", { type: "button", className: "pepbs-btn pepbs-btn-compact", text: "+", title: t("Acercar"), "aria-label": t("Acercar"), onClick: panZoom.zoomIn });
  const diagram = h("section", { className: "pepbs-connection-preview" }, h("div", { className: "pepbs-connection-preview-head" }, h("div", { className: "pepbs-connection-preview-copy" }, h("strong", { text: t("Mapa de conexiones") }), h("span", { text: t("Arrastra para moverte y usa la rueda para acercar o alejar.") })), h("div", { className: "pepbs-connection-zoom" }, zoomOut, zoomLabel, zoomIn)), connectionViewport);
  const refreshPreview = async () => {
    const highlightedConnection = options.connectionAtlasFocusKey === entry.key ? entry : null;
    const result = await renderConnectionAtlas(connectionStage, maps, mapVisuals, data.world.connections.entries, highlightedConnection, {
      filteredMapId: options.connectionMapFilter,
      onMapClick: (mapId) => options.onConnectionMapFilter?.(mapId, panZoom.viewState()),
      clickGuard: () => connectionViewport.dataset.justPanned === "true",
    });
    if (!connectionStage.isConnected) return;
    if (options.connectionAtlasView) {
      requestAnimationFrame(() => panZoom.restore(options.connectionAtlasView));
    } else if (result?.focusBounds) {
      requestAnimationFrame(() => panZoom.focus(result.focusBounds, { padding: 34, maxScale: 2.5 }));
    }
  };
  const grid = h("div", { className: "pepbs-world-grid pepbs-connection-settings-grid" });
  grid.appendChild(field("Modo de conexión", select(edgeMode ? "edge" : "coordinates", [["edge", t("Por bordes")], ["coordinates", t("Por coordenadas")]], (next) => {
    if (next === "edge") { entry.directionA = "N"; entry.offsetA = 0; entry.directionB = "S"; entry.offsetB = 0; }
    else { entry.directionA = 0; entry.offsetA = 0; entry.directionB = 0; entry.offsetB = 0; }
    update(); options.rerender();
  }, { empty: false }), { wide: true }));
  const side = (prefix) => {
    const mapKey = `map${prefix}`, directionKey = `direction${prefix}`, offsetKey = `offset${prefix}`;
    const axisControl = edgeMode
      ? select(entry[directionKey], DIRECTIONS, (next) => { entry[directionKey] = next; if (prefix === "A") entry.directionB = OPPOSITE_DIRECTION[next]; update(); options.rerender(); }, { empty: false })
      : input(entry[directionKey], (next) => { entry[directionKey] = Number(next); update(); refreshPreview(); }, { type: "number", step: 1 });
    grid.append(field(`Mapa ${prefix}`, select(entry[mapKey], mapOptions(maps), (next) => { entry[mapKey] = Number(next); update(); options.rerender(); }, { empty: false })), field(edgeMode ? `Lado ${prefix}` : `Coordenada X ${prefix}`, axisControl), field(edgeMode ? `Desplazamiento ${prefix}` : `Coordenada Y ${prefix}`, input(entry[offsetKey], (next) => { entry[offsetKey] = Number(next); update(); refreshPreview(); }, { type: "number", step: 1 })));
  };
  side("A"); side("B");
  const settings = h("aside", { className: "pepbs-connection-settings" },
    h("div", { className: "pepbs-connection-settings-head" }, h("h3", { text: t("Configuración de conexión") }), action("Eliminar", onDelete, "pepbs-btn-compact pepbs-btn-danger")),
    grid,
  );
  root.appendChild(h("div", { className: "pepbs-connection-workspace" }, h("div", { className: "pepbs-connection-canvas" }, diagram), settings));
  container.appendChild(root); refreshPreview();
}

function copyCanvas(source, className = "") {
  const canvas = document.createElement("canvas");
  canvas.width = source.width; canvas.height = source.height; canvas.className = className;
  const context = canvas.getContext("2d"); context.imageSmoothingEnabled = false; context.drawImage(source, 0, 0);
  return canvas;
}

function connectionPoint(position, info, direction, offset) {
  const side = String(direction).toUpperCase();
  const along = Number(offset) || 0;
  if (/^-?\d+$/.test(side)) return { x: position.x + Number(side), y: position.y + along };
  if (side === "N") return { x: position.x + along, y: position.y };
  if (side === "S") return { x: position.x + along, y: position.y + info.height };
  if (side === "W") return { x: position.x, y: position.y + along };
  return { x: position.x + info.width, y: position.y + along };
}

function connectionFocusBounds(connection, layout, tileSize, atlasInset) {
  if (!connection) return null;
  const positionA = layout.positions.get(Number(connection.mapA));
  const positionB = layout.positions.get(Number(connection.mapB));
  const infoA = layout.infos.get(Number(connection.mapA));
  const infoB = layout.infos.get(Number(connection.mapB));
  if (!positionA || !positionB || !infoA || !infoB) return null;
  const pointA = connectionPoint(positionA, infoA, connection.directionA, connection.offsetA);
  const pointB = connectionPoint(positionB, infoB, connection.directionB, connection.offsetB);
  const horizontalContext = 32;
  const verticalContext = 24;
  const minX = Math.max(0, Math.min(pointA.x, pointB.x) - horizontalContext);
  const minY = Math.max(0, Math.min(pointA.y, pointB.y) - verticalContext);
  const maxX = Math.min(layout.width, Math.max(pointA.x, pointB.x) + horizontalContext);
  const maxY = Math.min(layout.height, Math.max(pointA.y, pointB.y) + verticalContext);
  return {
    x: (minX + atlasInset) * tileSize,
    y: (minY + atlasInset) * tileSize,
    width: Math.max(tileSize, (maxX - minX) * tileSize),
    height: Math.max(tileSize, (maxY - minY) * tileSize),
  };
}

async function renderConnectionAtlas(stage, maps, mapVisuals, connections, selectedConnection = null, options = {}) {
  const token = String(Date.now()) + Math.random();
  stage.dataset.token = token;
  try {
    const mapIds = connections.flatMap((connection) => [connection.mapA, connection.mapB]);
    await mapVisuals.prepare(mapIds);
    if (!stage.isConnected || stage.dataset.token !== token) return null;
    const layout = layoutConnectionWorld(connections, (mapId) => mapVisuals.info(mapId));
    const tileSize = 4;
    const atlasInset = 48;
    const stageWidth = Math.max(1, (layout.width + atlasInset * 2) * tileSize);
    const stageHeight = Math.max(1, (layout.height + atlasInset * 2) * tileSize);
    stage.style.width = stageWidth + "px"; stage.style.height = stageHeight + "px";
    const visuals = await Promise.all([...layout.positions.keys()].map(async (mapId) => [mapId, await mapVisuals.render(mapId, tileSize)]));
    if (!stage.isConnected || stage.dataset.token !== token) return null;
    stage.innerHTML = ""; stage.classList.remove("is-loading");
    const links = document.createElement("canvas"); links.className = "pepbs-atlas-links"; links.width = stageWidth; links.height = stageHeight;
    const context = links.getContext("2d"); context.strokeStyle = "rgba(112, 137, 255, .85)"; context.lineWidth = 2;
    for (const connection of connections) {
      const a = layout.positions.get(Number(connection.mapA)), b = layout.positions.get(Number(connection.mapB));
      const ia = layout.infos.get(Number(connection.mapA)), ib = layout.infos.get(Number(connection.mapB));
      if (!a || !b || !ia || !ib) continue;
      context.beginPath(); context.moveTo((a.x + atlasInset + ia.width / 2) * tileSize, (a.y + atlasInset + ia.height / 2) * tileSize); context.lineTo((b.x + atlasInset + ib.width / 2) * tileSize, (b.y + atlasInset + ib.height / 2) * tileSize); context.stroke();
    }
    stage.appendChild(links);
    const selectedIds = new Set(selectedConnection ? [Number(selectedConnection.mapA), Number(selectedConnection.mapB)] : []);
    const highlights = [];
    visuals.forEach(([mapId, visual]) => {
      const position = layout.positions.get(mapId);
      const name = maps.find((map) => Number(map.id) === Number(mapId))?.name || "Map " + mapId;
      const displayId = String(mapId).padStart(3, "0");
      const focused = selectedIds.has(Number(mapId));
      const focusSide = Number(selectedConnection?.mapA) === Number(mapId) ? "a"
        : Number(selectedConnection?.mapB) === Number(mapId) ? "b" : "";
      const filtered = Number(options.filteredMapId) === Number(mapId);
      const label = `${name} · ${displayId}`;
      const item = h("button", {
        type: "button",
        className: `pepbs-atlas-map ${focused ? `is-focused is-focused-${focusSide}` : ""} ${filtered ? "is-filtered" : ""}`.trim(),
        style: { left: ((position.x + atlasInset) * tileSize) + "px", top: ((position.y + atlasInset) * tileSize) + "px" },
        "aria-label": t("Filtrar conexiones por {map}", { map: label }),
        "aria-pressed": filtered ? "true" : "false",
        onClick: () => { if (!options.clickGuard?.()) options.onMapClick?.(mapId); },
      }, copyCanvas(visual.canvas, "pepbs-map-raster"), h("span", { text: label }));
      stage.appendChild(item);
      if (focusSide || filtered) {
        highlights.push({
          position,
          width: visual.canvas.width,
          height: visual.canvas.height,
          className: focusSide ? `is-focused-${focusSide}` : "is-filtered",
        });
      }
    });
    // Decorations live in their own final layer so overlapping map canvases
    // can never paint over a selected-map indicator.
    highlights.forEach((highlight) => {
      stage.appendChild(h("span", {
        className: `pepbs-atlas-corners ${highlight.className}`,
        style: {
          left: ((highlight.position.x + atlasInset) * tileSize - 6) + "px",
          top: ((highlight.position.y + atlasInset) * tileSize - 6) + "px",
          width: (highlight.width + 12) + "px",
          height: (highlight.height + 12) + "px",
        },
        "aria-hidden": "true",
      }));
    });
    const focusBounds = connectionFocusBounds(selectedConnection, layout, tileSize, atlasInset);
    return { layout, tileSize, focusBounds };
  } catch (error) {
    if (stage.dataset.token !== token) return null;
    stage.classList.remove("is-loading"); stage.innerHTML = ""; stage.appendChild(mapFailure("No se pudo generar el mapa completo.", error));
    return null;
  }
}

export function renderTownMapEditor(options) {
  const { container, entry, data, maps, onChange, loadImage, createReferenceInput, onDelete, dialogs, mapVisuals } = options;
  const root = h("div", { className: "pepbs-townmap-workspace" });
  const stage = h("div", { className: "pepbs-townmap-stage" });
  const inspector = h("aside", { className: "pepbs-townmap-properties" });
  const map = h("div", { className: "pepbs-townmap-map" });
  const image = h("img", { alt: entry.name, draggable: "false" });
  const overlay = h("div", { className: "pepbs-townmap-overlay" });
  let selected = null;
  let drag = null;
  map.append(image, overlay); stage.appendChild(map); root.append(stage, inspector); container.appendChild(root);

  function changed(rerender = false) { onChange(entry, rerender); }
  function renderPoints() {
    overlay.innerHTML = "";
    for (const point of entry.points) {
      const marker = h("button", { type: "button", className: `pepbs-townmap-point ${point === selected ? "is-active" : ""}`, style: { left: `${point.x * 16}px`, top: `${point.y * 16}px` }, title: point.name || `${point.x}, ${point.y}`, onClick: (event) => { event.stopPropagation(); selected = point; renderPoints(); renderInspector(); } });
      marker.addEventListener("pointerdown", (event) => { event.stopPropagation(); marker.setPointerCapture(event.pointerId); drag = { point, marker }; selected = point; renderInspector(); });
      marker.addEventListener("pointermove", (event) => {
        if (!drag || drag.marker !== marker) return;
        const rect = overlay.getBoundingClientRect();
        const x = Math.max(0, Math.floor((event.clientX - rect.left) * (overlay.offsetWidth / rect.width) / 16));
        const y = Math.max(0, Math.floor((event.clientY - rect.top) * (overlay.offsetHeight / rect.height) / 16));
        if (!entry.points.some((other) => other !== point && other.x === x && other.y === y)) { point.x = x; point.y = y; marker.style.left = `${x * 16}px`; marker.style.top = `${y * 16}px`; changed(); }
      });
      marker.addEventListener("pointerup", () => { drag = null; renderInspector(); });
      overlay.appendChild(marker);
    }
  }

  function renderInspector() {
    inspector.innerHTML = "";
    const imagePicker = createReferenceInput(entry.filename.replace(/\.[^.]+$/i, ""), "pictures", (next) => { entry.filename = next ? `${next}.png` : ""; changed(); loadMap(); }, t("Buscar imagen…"));
    inspector.append(h("div", { className: "pepbs-townmap-properties-head" }, h("strong", { text: t("Región") }), action("Eliminar región", onDelete, "pepbs-btn-compact pepbs-btn-danger")), h("div", { className: "pepbs-townmap-region-grid" }, field("ID de región", input(entry.regionId, (next) => { entry.regionId = Number(next); changed(); }, { type: "number", min: 0 })), field("Nombre de la región", input(entry.name, (next) => { entry.name = next; changed(); }))), field("Imagen regional", imagePicker));
    if (!selected) return;
    const defaultFlyMapId = findTownMapPointMapId(entry.regionId, selected, data.world.metadata.entries, maps);
    inspector.append(h("div", { className: "pepbs-world-divider" }), h("strong", { className: "pepbs-world-subheading", text: t("Punto del mapa") }), field("Coordenadas", h("div", { className: "pepbs-world-coordinate" }, input(selected.x, (next) => { selected.x = Number(next); changed(); renderPoints(); }, { type: "number", min: 0 }), input(selected.y, (next) => { selected.y = Number(next); changed(); renderPoints(); }, { type: "number", min: 0 }))), field("Nombre del lugar", input(selected.name, (next) => { selected.name = next; changed(); })), field("Punto de interés", input(selected.poi, (next) => { selected.poi = next; changed(); })), field("Destino de vuelo", mapCoordinateControl([selected.healingMap, selected.healingX, selected.healingY].join(","), maps, (next) => { [selected.healingMap, selected.healingX, selected.healingY] = splitCsv(next); changed(); }, false, { dialogs, mapVisuals, defaultMapId: defaultFlyMapId })), field("Interruptor de visibilidad", input(selected.switchId, (next) => { selected.switchId = next; changed(); }, { type: "number", min: 1 })), action("Eliminar punto", () => { entry.points = entry.points.filter((point) => point !== selected); selected = null; changed(); renderPoints(); renderInspector(); }, "pepbs-btn-danger"));
  }

  overlay.addEventListener("click", () => { selected = null; renderPoints(); renderInspector(); });
  overlay.addEventListener("dblclick", (event) => {
    const rect = overlay.getBoundingClientRect();
    const x = Math.floor((event.clientX - rect.left) * (overlay.offsetWidth / rect.width) / 16), y = Math.floor((event.clientY - rect.top) * (overlay.offsetHeight / rect.height) / 16);
    if (entry.points.some((point) => point.x === x && point.y === y)) return;
    selected = { x, y, name: "", poi: "", healingMap: "", healingX: "", healingY: "", switchId: "" }; entry.points.push(selected); changed(); renderPoints(); renderInspector();
  });

  async function loadMap() {
    image.removeAttribute("src"); map.classList.add("is-loading");
    const filename = entry.filename.replace(/^Graphics[\\/]Pictures[\\/]/i, "");
    if (!filename) { map.classList.remove("is-loading"); return; }
    const url = await loadImage([`Graphics/Pictures/${filename}`, `Graphics/Pictures/${filename}.png`]);
    if (!url || !image.isConnected) { map.classList.remove("is-loading"); return; }
    image.onload = () => { map.style.width = `${image.naturalWidth}px`; map.style.height = `${image.naturalHeight}px`; map.classList.remove("is-loading"); renderPoints(); };
    image.src = url;
  }
  renderInspector(); loadMap();
}

export async function renderWorldPreview(options) {
  const { container, kind, entry, maps, mapVisuals, loadImage } = options;
  container.innerHTML = "";
  if (!entry || kind === "townMap") return;
  container.appendChild(h("div", { className: "pepbs-preview-label", text: t("Vista previa") }));
  if (kind === "encounters") {
    container.append(h("div", { className: "pepbs-preview-name", text: entry.mapName || maps.find((map) => map.id === entry.mapId)?.name || `Map ${entry.mapId}` }), h("div", { className: "pepbs-preview-id", text: `${entry.groups.length} ${t("métodos")}` }));
    const species = [...new Set(entry.groups.flatMap((group) => group.slots.map((slot) => slot.species)))].slice(0, 12);
    const party = h("div", { className: "pepbs-world-icon-grid" }); container.appendChild(party);
    for (const id of species) {
      let url = null;
      try {
        if (typeof loadImage === "function") url = await loadImage([`Graphics/Pokemon/Icons/${id}.png`, "Graphics/Pokemon/Icons/000.png"]);
      } catch { /* A missing preview graphic must not interrupt the editor. */ }
      if (url && party.isConnected) party.appendChild(h("span", { className: "pepbs-team-icon", title: id }, h("img", { src: url, alt: id })));
    }
  } else if (kind === "connections") {
    container.append(h("div", { className: "pepbs-preview-name", text: `${maps.find((map) => map.id === entry.mapA)?.name || entry.mapA} ↔ ${maps.find((map) => map.id === entry.mapB)?.name || entry.mapB}` }), h("div", { className: "pepbs-preview-id", text: `${entry.directionA} ${entry.offsetA} · ${entry.directionB} ${entry.offsetB}` }));
  } else if (kind === "metadata") {
    container.append(h("div", { className: "pepbs-preview-name", text: entry.mapId === 0 ? t("Configuración global") : maps.find((map) => map.id === entry.mapId)?.name || `Map ${entry.mapId}` }), h("div", { className: "pepbs-preview-id", text: `[${String(entry.mapId).padStart(3, "0")}]` }));
    if (entry.mapId !== 0 && mapVisuals) {
      const frame = h("div", { className: "pepbs-metadata-map-preview" }, h("div", { className: "pepbs-map-loading", text: t("Cargando mapa…") }));
      container.appendChild(frame);
      try {
        await mapVisuals.prepare([entry.mapId]);
        const mapInfo = mapVisuals.info(entry.mapId);
        const tileSize = Math.max(1, Math.min(6, Math.floor(Math.min(260 / Math.max(1, mapInfo.width), 180 / Math.max(1, mapInfo.height)))));
        const visual = await mapVisuals.render(entry.mapId, tileSize);
        if (frame.isConnected) { frame.innerHTML = ""; frame.appendChild(copyCanvas(visual.canvas, "pepbs-map-raster")); }
      } catch (error) {
        if (frame.isConnected) { frame.innerHTML = ""; frame.appendChild(mapFailure("No se pudo cargar este mapa.", error)); }
      }
    }
  }
}
