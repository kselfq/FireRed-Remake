import { mountPbsEditor } from "../src/app/editor.js";
import { getLanguage, setLanguage, t } from "../src/ui/i18n.js";
import { parseTypes } from "../src/pbs/pbs19.js";
import { createTypeBadge } from "../src/ui/visual_badges.js";

const gameRoot = "C:/Users/mibas/Desktop/aaa";
const memoryFiles = new Map();
const responseText = async (url) => {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${response.status} ${url}`);
  return response.text();
};

window.__TAURI__ = {
  core: {
    async invoke(command, args) {
      if (command === "read_binary_file") {
        const normalized = String(args.path).replace(/\\/g, "/");
        const relative = normalized.startsWith(gameRoot) ? normalized.slice(gameRoot.length).replace(/^\//, "") : normalized;
        const response = await fetch(`/project/${relative}`);
        if (!response.ok) throw new Error(`Missing ${relative}`);
        return [...new Uint8Array(await response.arrayBuffer())];
      }
      if (command === "list_directory") {
        const normalized = String(args.path).replace(/\\/g, "/");
        const relative = normalized.startsWith(gameRoot) ? normalized.slice(gameRoot.length).replace(/^\//, "") : normalized;
        const response = await fetch(`/directory/${relative}`);
        if (!response.ok) throw new Error(`Missing directory ${relative}`);
        return response.json();
      }
      throw new Error(`Unsupported harness command: ${command}`);
    },
  },
};

const metadataText = await responseText("/project/PBS/metadata.txt");
const maps = [];
const metadataLines = metadataText.split(/\r?\n/);
for (let index = 0; index < metadataLines.length; index += 1) {
  const match = metadataLines[index].match(/^\[(\d+)\]$/);
  if (!match || Number(match[1]) === 0) continue;
  const comment = metadataLines.slice(index + 1, index + 4).find((line) => /^#(?!-)/.test(line));
  maps.push({ id: Number(match[1]), name: comment?.replace(/^#\s*/, "") || `Map ${Number(match[1])}` });
}

const ctx = {
  fs: {
    readProjectFile: (path) => memoryFiles.has(path) ? Promise.resolve(memoryFiles.get(path)) : responseText(`/project/${path}`),
    writeProjectFile: async (path, content) => { memoryFiles.set(path, content); },
    projectExists: async (path) => (await fetch(`/project/${path}`, { method: "HEAD" })).ok,
    listProjectDir: async (path) => {
      const response = await fetch(`/directory/${String(path).replace(/^\//, "")}`);
      if (!response.ok) throw new Error(`Missing directory ${path}`);
      return response.json();
    },
  },
  editor: { gameRoot: () => gameRoot },
  projectData: { maps: () => maps },
  map: {
    info: () => { throw new Error("Harness map is deliberately not loaded"); },
    readTile: () => { throw new Error("Harness map is deliberately not loaded"); },
  },
  tileset: {
    mapTilesetId: () => { throw new Error("Harness map is deliberately not loaded"); },
    info: () => ({ id: 1, name: "Harness", tilesetName: "Exterior", autotileNames: [] }),
    getImageBlobUrl: async () => "/project/Graphics/Tilesets/Exterior.png",
  },
  ui: {
    showToast: ({ message, level }) => console.log(`[${level}] ${message}`),
    showConfirmDialog: async () => false,
  },
  log: { info: console.log, warn: console.warn, error: console.error },
};

mountPbsEditor(ctx, document.querySelector("#app"));

const harnessParams = new URLSearchParams(location.search);
if (harnessParams.has("measureTypes")) {
  const typeRecords = parseTypes(await responseText("/project/PBS/types.txt"));
  const previousLanguage = getLanguage();
  const measure = document.createElement("div");
  measure.style.cssText = "position:fixed;left:-10000px;top:0;display:flex;align-items:flex-start;gap:2px;visibility:hidden";
  document.body.appendChild(measure);
  let regularWidth = 0;
  let compactWidth = 0;
  let longest = "";
  for (const language of ["en", "es"]) {
    setLanguage(language);
    for (const type of typeRecords) {
      const label = t(type.name || type.id);
      for (const compact of [false, true]) {
        const badge = createTypeBadge(type.id, label, compact);
        badge.style.width = "max-content";
        badge.style.minWidth = "0";
        measure.appendChild(badge);
        const width = Math.ceil(badge.getBoundingClientRect().width);
        if (compact) compactWidth = Math.max(compactWidth, width);
        else regularWidth = Math.max(regularWidth, width);
        if (width === (compact ? compactWidth : regularWidth)) longest = `${language}:${label}`;
      }
    }
  }
  setLanguage(previousLanguage);
  measure.remove();
  document.body.dataset.typeRegularNaturalWidth = String(regularWidth);
  document.body.dataset.typeCompactNaturalWidth = String(compactWidth);
  document.body.dataset.typeLongestLabel = longest;
  const renderedWidthTimer = setInterval(() => {
    const badges = [...document.querySelectorAll(".pepbs-type-logo.is-compact")];
    if (!badges.length) return;
    clearInterval(renderedWidthTimer);
    const widths = [...new Set(badges.map((badge) => badge.getBoundingClientRect().width.toFixed(2)))];
    document.body.dataset.typeRenderedCompactWidths = widths.join(",");
  }, 50);
  setTimeout(() => clearInterval(renderedWidthTimer), 10000);
}
const requestedSection = harnessParams.get("section");
if (requestedSection) {
  const timer = setInterval(() => {
    const button = [...document.querySelectorAll(".pepbs-nav")].find((item) => item.textContent.trim().toLowerCase() === requestedSection.toLowerCase());
    if (!button) return;
    clearInterval(timer);
    button.click();
    const townMapFly = harnessParams.get("townMapFly");
    if (townMapFly) {
      const pointTimer = setInterval(() => {
        const point = [...document.querySelectorAll(".pepbs-townmap-point")].find((item) => item.title === townMapFly);
        if (!point) return;
        clearInterval(pointTimer);
        point.click();
        const dialogTimer = setInterval(() => {
          const picker = document.querySelector(".pepbs-townmap-properties .pepbs-coordinate-picker-button");
          if (!picker) return;
          picker.click();
          const selectedMap = document.querySelector(".pepbs-map-dialog-toolbar .pepbs-dropdown-value")?.textContent || "";
          if (!selectedMap) return;
          clearInterval(dialogTimer);
          document.body.dataset.townMapFlyDefault = selectedMap;
        }, 50);
        setTimeout(() => clearInterval(dialogTimer), 10000);
      }, 50);
      setTimeout(() => clearInterval(pointTimer), 10000);
    }
    const encounterForm = harnessParams.get("encounterForm");
    if (encounterForm) {
      const formTimer = setInterval(() => {
        const picker = document.querySelector(".pepbs-encounter-species .pepbs-ref-picker");
        if (!picker) return;
        picker.querySelector(".pepbs-ref-toggle")?.click();
        const option = [...picker.querySelectorAll(".pepbs-ref-option")].find((item) => item.querySelector("small")?.textContent === encounterForm);
        if (!option) return;
        clearInterval(formTimer);
        option.click();
        const input = picker.querySelector("input");
        picker.querySelector(".pepbs-ref-toggle")?.click();
        input?.dispatchEvent(new Event("input", { bubbles: true }));
        document.body.dataset.encounterFormValue = input?.value || "";
        document.body.dataset.encounterFormLabel = option.querySelector("strong")?.textContent || "";
      }, 50);
      setTimeout(() => clearInterval(formTimer), 10000);
    }
    if (harnessParams.has("zoom")) {
      const zoomTimer = setInterval(() => {
        const zoomIn = document.querySelector(".pepbs-connection-zoom button:last-child");
        if (!zoomIn) return;
        clearInterval(zoomTimer);
        zoomIn.click();
      }, 50);
      setTimeout(() => clearInterval(zoomTimer), 10000);
    }
  }, 50);
  setTimeout(() => clearInterval(timer), 10000);
}
