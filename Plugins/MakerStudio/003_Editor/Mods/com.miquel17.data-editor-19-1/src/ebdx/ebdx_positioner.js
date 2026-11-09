import { h } from "../ui/ui_utils.js";
import { POSITION_FIELDS } from "./ebdx_data.js";
import { t } from "../ui/i18n.js";
import { EBDX_POSITIONER_ASSET_ROOT } from "../core/mod_config.js";

const STAGE = { width: 512, height: 432, playerX: 102, playerY: 384, enemyX: 392, enemyY: 203 };
const FIELD_META = {
  BattlerEnemyX: ["Front X", -256, 256],
  BattlerEnemyY: ["Front Y", -256, 256],
  BattlerPlayerX: ["Back X", -256, 256],
  BattlerPlayerY: ["Back Y", -128, 128],
  BattlerAltitude: ["Altitud", -128, 128],
};

function loadDomImage(url) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error("Could not decode image"));
    image.src = url;
  });
}

function spriteMetrics(image, scale, side, values) {
  if (!image) return null;
  const frame = image.naturalHeight || image.height;
  if (!frame) return null;
  const factor = side === "player" ? scale * 2 : scale;
  const width = frame * factor;
  const height = frame * factor;
  const altitude = values.BattlerAltitude;
  if (side === "player") {
    return {
      left: STAGE.playerX - width / 2 + values.BattlerPlayerX,
      top: STAGE.playerY - height + (values.BattlerPlayerY * 2) - altitude,
      width,
      height,
      anchorX: STAGE.playerX,
      anchorY: STAGE.playerY,
    };
  }
  return {
    left: STAGE.enemyX - width / 2 + values.BattlerEnemyX,
    top: STAGE.enemyY - height + values.BattlerEnemyY - altitude,
    width,
    height,
    anchorX: STAGE.enemyX,
    anchorY: STAGE.enemyY,
  };
}

function inside(point, metrics, padding = 0) {
  return metrics && point.x >= metrics.left - padding && point.x <= metrics.left + metrics.width + padding
    && point.y >= metrics.top - padding && point.y <= metrics.top + metrics.height + padding;
}

function drawPlatform(context, x, y, width, height, color) {
  context.save();
  context.translate(x, y);
  const gradient = context.createRadialGradient(0, 0, 3, 0, 0, width / 2);
  gradient.addColorStop(0, color);
  gradient.addColorStop(0.72, "rgba(101, 126, 145, .5)");
  gradient.addColorStop(1, "rgba(35, 48, 65, 0)");
  context.fillStyle = gradient;
  context.beginPath();
  context.ellipse(0, 0, width / 2, height / 2, 0, 0, Math.PI * 2);
  context.fill();
  context.restore();
}

function drawEbdxShadow(context, image, metrics, time, side) {
  if (!image || !metrics) return;
  const frameSize = image.naturalHeight;
  const frames = Math.max(1, Math.floor(image.naturalWidth / frameSize));
  const frame = Math.floor(time / 95) % frames;
  const compression = side === "player" ? 0.25 : 0.125;
  const left = metrics.left + 12;
  const top = metrics.anchorY - ((metrics.anchorY - metrics.top) - 6) * compression;
  context.save();
  context.imageSmoothingEnabled = false;
  context.globalAlpha = 0.3;
  context.filter = "brightness(0)";
  context.drawImage(
    image,
    frame * frameSize, 0, frameSize, frameSize,
    left, top, metrics.width, metrics.height * compression,
  );
  context.restore();
}

function drawSprite(context, image, metrics, time, selected) {
  if (!image || !metrics) return;
  const frameSize = image.naturalHeight;
  const frames = Math.max(1, Math.floor(image.naturalWidth / frameSize));
  const frame = Math.floor(time / 95) % frames;
  context.save();
  context.imageSmoothingEnabled = false;
  context.drawImage(image, frame * frameSize, 0, frameSize, frameSize, metrics.left, metrics.top, metrics.width, metrics.height);
  if (selected) {
    context.strokeStyle = "rgba(122, 150, 255, .95)";
    context.lineWidth = 2;
    context.setLineDash([5, 4]);
    context.strokeRect(Math.round(metrics.left) - 4, Math.round(metrics.top) - 4, Math.round(metrics.width) + 8, Math.round(metrics.height) + 8);
  }
  context.restore();
}

function stagePoint(canvas, event) {
  const rect = canvas.getBoundingClientRect();
  return {
    x: (event.clientX - rect.left) * STAGE.width / rect.width,
    y: (event.clientY - rect.top) * STAGE.height / rect.height,
  };
}

function spriteCandidates(entry, side) {
  const folder = side === "player" ? "Back" : "Front";
  const suffix = entry.form ? `_${entry.form}` : "";
  const numeric = String(entry.idNumber).padStart(3, "0");
  return [
    `Graphics/EBDX/Battlers/${folder}/${entry.species}${suffix}.png`,
    `Graphics/EBDX/Battlers/${folder}/${numeric}${suffix}.png`,
    `Graphics/EBDX/Battlers/${folder}/000.png`,
    "Graphics/EBDX/Battlers/000.png",
  ];
}

function toolAsset(name) {
  // Maker Studio grants plugins project-file access. Its WebView does not load
  // arbitrary file: URLs, so bundled assets must be resolved from game root.
  return [`${EBDX_POSITIONER_ASSET_ROOT}/${name}`];
}

export function renderEbdxPositioner({
  container,
  entry,
  loadImage,
  onChange,
  onReset,
  onApplyAllForms,
  canApplyAllForms,
  onBeginEdit,
  onCommitEdit,
  onUndo,
  onRedo,
  canUndo,
  canRedo,
}) {
  let selectedSide = "enemy";
  let enemyImage = null;
  let playerImage = null;
  let backgroundImage = null;
  let enemyBaseImage = null;
  let playerBaseImage = null;
  let grabberImage = null;
  let disposed = false;
  let animationFrame = 0;
  let drag = null;
  const inputs = new Map();
  const reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches ?? false;

  const title = h("div", { className: "pepbs-record-head" },
    h("div", { className: "pepbs-record-title" },
      h("div", {},
        h("h2", { text: entry.formName ? `${entry.name} · ${entry.formName}` : entry.name }),
        h("code", { text: `[${entry.header}] · PBS/EBDX/pokemon.txt` }),
      ),
      h("div", { className: "pepbs-record-badges" },
        h("span", { className: "pepbs-badge pepbs-ebdx-badge", text: "EBDX" }),
      ),
    ),
  );

  const canvas = h("canvas", {
    className: "pepbs-ebdx-canvas",
    width: STAGE.width,
    height: STAGE.height,
    tabIndex: 0,
    role: "application",
    "aria-label": t("Escenario de posición EBDX"),
  });
  const stage = h("div", { className: "pepbs-ebdx-stage" }, canvas);
  const stageShell = h("div", { className: "pepbs-ebdx-stage-shell" }, stage);
  const sideButtons = h("div", { className: "pepbs-ebdx-side-tabs", role: "tablist" });

  function updateSideButtons() {
    canvas.dataset.selectedSide = selectedSide || "";
    for (const button of sideButtons.children) {
      const active = button.dataset.side === selectedSide;
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-selected", String(active));
    }
  }

  for (const [side, label] of [["enemy", "Sprite frontal"], ["player", "Sprite trasero"]]) {
    sideButtons.appendChild(h("button", {
      type: "button",
      role: "tab",
      "data-side": side,
      text: t(label),
      onClick: () => { selectedSide = side; updateSideButtons(); canvas.focus(); },
    }));
  }
  updateSideButtons();

  const coordinateGrid = h("div", { className: "pepbs-ebdx-coordinate-grid" });
  function updateValue(field, value) {
    const [label, minimum, maximum] = FIELD_META[field];
    const next = Math.max(minimum, Math.min(maximum, Math.round(Number(value))));
    if (!Number.isFinite(next)) return;
    onChange(field, next);
    const input = inputs.get(field);
    if (input && Number(input.value) !== next) input.value = String(next);
    if (field === "BattlerAltitude") {
      altitudeRange.value = String(next);
      altitudeValue.textContent = String(next);
      altitudeZero.disabled = next === 0;
    }
    if (reducedMotion) draw(0);
  }

  for (const field of POSITION_FIELDS) {
    if (field === "BattlerAltitude") continue;
    const [label, minimum, maximum] = FIELD_META[field];
    const input = h("input", {
      className: "pepbs-input",
      type: "number",
      min: minimum,
      max: maximum,
      step: 1,
      value: entry.values[field],
      onFocus: () => onBeginEdit(t("Editar coordenadas EBDX")),
      onInput: (event) => updateValue(field, event.currentTarget.value),
      onChange: onCommitEdit,
      onBlur: onCommitEdit,
    });
    inputs.set(field, input);
    coordinateGrid.appendChild(h("label", { className: "pepbs-ebdx-coordinate" },
      h("span", { text: t(label) }), input,
    ));
  }

  const altitudeValue = h("output", {
    className: "pepbs-ebdx-altitude-value",
    for: "pepbs-ebdx-altitude-range",
    text: String(entry.values.BattlerAltitude),
  });
  const altitudeZero = h("button", {
    type: "button",
    className: "pepbs-btn pepbs-btn-compact pepbs-ebdx-altitude-zero",
    text: "0",
    disabled: Number(entry.values.BattlerAltitude) === 0,
    title: t("Poner altitud a 0"),
    "aria-label": t("Poner altitud a 0"),
    onClick: () => {
      onBeginEdit(t("Editar coordenadas EBDX"));
      updateValue("BattlerAltitude", 0);
      onCommitEdit();
    },
  });
  const altitudeRange = h("input", {
    id: "pepbs-ebdx-altitude-range",
    className: "pepbs-ebdx-range",
    type: "range",
    min: -128,
    max: 128,
    step: 1,
    value: entry.values.BattlerAltitude,
    "aria-label": t("Altitud"),
    onFocus: () => onBeginEdit(t("Editar coordenadas EBDX")),
    onPointerDown: () => onBeginEdit(t("Editar coordenadas EBDX")),
    onInput: (event) => updateValue("BattlerAltitude", event.currentTarget.value),
    onChange: onCommitEdit,
    onPointerUp: onCommitEdit,
    onPointerCancel: onCommitEdit,
    onBlur: onCommitEdit,
  });
  function syncAltitude() {
    const value = Number(entry.values.BattlerAltitude) || 0;
    altitudeRange.value = String(value);
    altitudeValue.textContent = String(value);
    altitudeZero.disabled = value === 0;
  }
  const altitudeControl = h("div", { className: "pepbs-ebdx-altitude" },
    h("div", { className: "pepbs-ebdx-altitude-head" }, h("span", { text: t("Altitud") }), altitudeValue),
    h("div", { className: "pepbs-ebdx-altitude-control" }, altitudeRange, altitudeZero),
  );

  const actions = h("div", { className: "pepbs-ebdx-actions" },
    h("button", { type: "button", className: "pepbs-btn pepbs-btn-compact", text: t("Restaurar guardado"), onClick: () => { onReset(); for (const [field, input] of inputs) input.value = entry.values[field]; syncAltitude(); } }),
    ...(canApplyAllForms ? [h("button", { type: "button", className: "pepbs-btn pepbs-btn-compact", text: t("Aplicar a todas las formas"), onClick: onApplyAllForms })] : []),
  );

  const history = h("div", { className: "pepbs-ebdx-history", role: "group", "aria-label": t("Historial de edición") },
    h("button", {
      id: "pepbs-ebdx-undo", type: "button", className: "pepbs-btn pepbs-btn-compact pepbs-ebdx-history-btn",
      disabled: !canUndo(), title: t("Deshacer último cambio"), "aria-label": t("Deshacer último cambio"),
      onClick: onUndo,
    }, h("span", { "aria-hidden": "true", text: "↶" }), h("span", { text: t("Deshacer") })),
    h("button", {
      id: "pepbs-ebdx-redo", type: "button", className: "pepbs-btn pepbs-btn-compact pepbs-ebdx-history-btn",
      disabled: !canRedo(), title: t("Rehacer último cambio"), "aria-label": t("Rehacer último cambio"),
      onClick: onRedo,
    }, h("span", { "aria-hidden": "true", text: "↷" }), h("span", { text: t("Rehacer") })),
  );

  const controls = h("aside", { className: "pepbs-ebdx-controls" },
    h("div", { className: "pepbs-ebdx-eyebrow", text: t("Posicionador de sprites") }),
    h("h3", { text: t("Composición de combate") }),
    h("p", { text: t("Edita las métricas propias de Elite Battle DX. Los campos de posición del PBS normal no se modifican.") }),
    history,
    sideButtons,
    coordinateGrid,
    altitudeControl,
    actions,
  );

  const workspace = h("div", { className: "pepbs-ebdx-workspace" }, stageShell, controls);
  container.append(title, workspace);
  const fitStage = () => {
    if (disposed) return;
    const availableHeight = Math.max(320, container.clientHeight - title.offsetHeight);
    workspace.style.height = `${availableHeight}px`;
    const width = Math.max(1, Math.min(stageShell.clientWidth, stageShell.clientHeight * STAGE.width / STAGE.height));
    stage.style.width = `${Math.floor(width)}px`;
    stage.style.height = `${Math.floor(width * STAGE.height / STAGE.width)}px`;
  };
  const resizeObserver = new ResizeObserver(fitStage);
  resizeObserver.observe(container);
  requestAnimationFrame(fitStage);

  function currentMetrics() {
    return {
      enemy: spriteMetrics(enemyImage, Number(entry.renderValues.SpriteScaleEnemy) || 2, "enemy", entry.values),
      player: spriteMetrics(playerImage, Number(entry.renderValues.SpriteScalePlayer) || 2, "player", entry.values),
    };
  }

  function draw(time = 0) {
    if (disposed) return;
    const context = canvas.getContext("2d");
    context.imageSmoothingEnabled = false;
    if (backgroundImage) {
      context.drawImage(backgroundImage, 0, 0, STAGE.width, STAGE.height);
    } else {
      const background = context.createLinearGradient(0, 0, 0, STAGE.height);
      background.addColorStop(0, "#182b3d");
      background.addColorStop(.52, "#315063");
      background.addColorStop(.525, "#526d65");
      background.addColorStop(1, "#263e3d");
      context.fillStyle = background;
      context.fillRect(0, 0, STAGE.width, STAGE.height);
    }
    context.fillStyle = "rgba(218, 236, 238, .08)";
    for (let y = 210; y < STAGE.height; y += 22) context.fillRect(0, y, STAGE.width, 1);
    if (enemyBaseImage) context.drawImage(enemyBaseImage, STAGE.enemyX - enemyBaseImage.naturalWidth / 2, STAGE.enemyY - enemyBaseImage.naturalHeight / 2);
    else drawPlatform(context, STAGE.enemyX, STAGE.enemyY + 2, 180, 52, "rgba(211, 224, 208, .72)");
    if (playerBaseImage) context.drawImage(playerBaseImage, STAGE.playerX - playerBaseImage.naturalWidth / 2, STAGE.playerY - playerBaseImage.naturalHeight / 2);
    else drawPlatform(context, STAGE.playerX, STAGE.playerY - 4, 260, 76, "rgba(211, 224, 208, .68)");
    const metrics = currentMetrics();
    drawEbdxShadow(context, enemyImage, metrics.enemy, time, "enemy");
    drawEbdxShadow(context, playerImage, metrics.player, time, "player");
    drawSprite(context, enemyImage, metrics.enemy, time, selectedSide === "enemy");
    drawSprite(context, playerImage, metrics.player, time, selectedSide === "player");
    const selectedMetrics = metrics[selectedSide];
    if (grabberImage && selectedMetrics) {
      const size = 28;
      context.save();
      context.globalAlpha = drag ? .96 : .82;
      context.drawImage(grabberImage, selectedMetrics.left + selectedMetrics.width / 2 - size / 2, selectedMetrics.top + selectedMetrics.height / 2 - size / 2, size, size);
      context.restore();
    }
    if (!enemyImage || !playerImage) {
      context.fillStyle = "rgba(10, 15, 24, .72)";
      context.fillRect(14, 342, 484, 27);
      context.fillStyle = "#d5d9e6";
      context.font = "12px system-ui";
      context.fillText(t("No se encontró uno de los sprites EBDX para esta forma."), 24, 360);
    }
    if (!reducedMotion) animationFrame = requestAnimationFrame(draw);
  }

  canvas.addEventListener("pointerdown", (event) => {
    const point = stagePoint(canvas, event);
    const metrics = currentMetrics();
    if (inside(point, metrics.player, 4)) selectedSide = "player";
    else if (inside(point, metrics.enemy, 4)) selectedSide = "enemy";
    else {
      selectedSide = null;
      drag = null;
      updateSideButtons();
      canvas.focus();
      if (reducedMotion) draw(0);
      return;
    }
    updateSideButtons();
    canvas.focus();
    canvas.setPointerCapture(event.pointerId);
    onBeginEdit(t("Mover sprite EBDX"));
    drag = {
      pointerId: event.pointerId,
      start: point,
      x: entry.values[selectedSide === "enemy" ? "BattlerEnemyX" : "BattlerPlayerX"],
      y: entry.values[selectedSide === "enemy" ? "BattlerEnemyY" : "BattlerPlayerY"],
    };
  });
  canvas.addEventListener("pointermove", (event) => {
    if (!drag || drag.pointerId !== event.pointerId) return;
    const point = stagePoint(canvas, event);
    const factor = selectedSide === "player" ? 2 : 1;
    updateValue(selectedSide === "enemy" ? "BattlerEnemyX" : "BattlerPlayerX", drag.x + point.x - drag.start.x);
    updateValue(selectedSide === "enemy" ? "BattlerEnemyY" : "BattlerPlayerY", drag.y + (point.y - drag.start.y) / factor);
  });
  const endDrag = (event) => {
    if (drag?.pointerId !== event.pointerId) return;
    drag = null;
    onCommitEdit();
  };
  canvas.addEventListener("pointerup", endDrag);
  canvas.addEventListener("pointercancel", endDrag);
  const nudgeSelected = (event) => {
    if (!selectedSide) return;
    if (!["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"].includes(event.key)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    const step = event.shiftKey ? 5 : 1;
    const xField = selectedSide === "enemy" ? "BattlerEnemyX" : "BattlerPlayerX";
    const yField = selectedSide === "enemy" ? "BattlerEnemyY" : "BattlerPlayerY";
    onBeginEdit(t("Mover sprite EBDX"));
    if (event.key === "ArrowLeft") updateValue(xField, entry.values[xField] - step);
    if (event.key === "ArrowRight") updateValue(xField, entry.values[xField] + step);
    if (event.key === "ArrowUp") updateValue(yField, entry.values[yField] - step);
    if (event.key === "ArrowDown") updateValue(yField, entry.values[yField] + step);
    onCommitEdit();
  };
  const onWindowKeyDown = (event) => {
    if (!["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"].includes(event.key)) return;
    const target = event.target;
    if (target instanceof HTMLElement && (target.matches("input, textarea, select") || target.isContentEditable)) return;
    nudgeSelected(event);
  };
  window.addEventListener("keydown", onWindowKeyDown, { capture: true });

  Promise.all([
    loadImage(spriteCandidates(entry, "enemy")).then((url) => url ? loadDomImage(url) : null).catch(() => null),
    loadImage(spriteCandidates(entry, "player")).then((url) => url ? loadDomImage(url) : null).catch(() => null),
    loadImage(toolAsset("battlebg.png")).then((url) => url ? loadDomImage(url) : null).catch(() => null),
    loadImage(toolAsset("enemybase.png")).then((url) => url ? loadDomImage(url) : null).catch(() => null),
    loadImage(toolAsset("playerbase.png")).then((url) => url ? loadDomImage(url) : null).catch(() => null),
    loadImage(toolAsset("grabber.png")).then((url) => url ? loadDomImage(url) : null).catch(() => null),
  ]).then(([enemy, player, background, enemyBase, playerBase, grabber]) => {
    if (disposed) return;
    enemyImage = enemy;
    playerImage = player;
    backgroundImage = background;
    enemyBaseImage = enemyBase;
    playerBaseImage = playerBase;
    grabberImage = grabber;
    if (reducedMotion) draw(0);
  });
  draw();

  return () => {
    onCommitEdit();
    disposed = true;
    resizeObserver.disconnect();
    window.removeEventListener("keydown", onWindowKeyDown, { capture: true });
    cancelAnimationFrame(animationFrame);
  };
}
