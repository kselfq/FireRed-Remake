import { t } from "./i18n.js";

const SVG_NS = "http://www.w3.org/2000/svg";

const TYPE_VISUALS = {
  NORMAL: { color: "#8A92A3", glyph: '<circle cx="12" cy="12" r="7" fill="none" stroke="currentColor" stroke-width="3"/><circle cx="12" cy="12" r="2.2"/>' },
  FIGHTING: { color: "#D45B62", glyph: '<path d="M5 10V7.8c0-1.5 2.2-1.5 2.2 0V6.4c0-1.6 2.3-1.6 2.3 0V5.8c0-1.6 2.3-1.6 2.3 0v.7c0-1.5 2.2-1.5 2.2 0v4.2l1-1.1c1.5-1.5 3.5.3 2.3 1.8l-3.8 5.2c-.8 1-2 1.6-3.3 1.6H9c-2.2 0-4-1.8-4-4V10Z"/>' },
  FLYING: { color: "#8797E6", glyph: '<path d="M18.5 5.5C12.5 5.2 7.8 8 5.2 13.3c3.5-2.5 7.2-3.5 10.9-3.2-3.8.7-6.9 2.4-9.4 5.2 4.9-.3 8.8-3.5 11.8-9.8Z"/><path d="M4 16.8c2.5-3.8 5.5-6.2 9-7.3" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>' },
  POISON: { color: "#A86AC2", glyph: '<circle cx="12" cy="12.5" r="5.8"/><circle cx="7" cy="6.2" r="2"/><circle cx="15.8" cy="5.2" r="1.5"/><circle cx="18.2" cy="10" r="1.2"/><circle cx="10" cy="11.5" r="1.3" fill="#171925"/><circle cx="14.2" cy="11.5" r="1.3" fill="#171925"/><path d="M9.5 15.2h5" stroke="#171925" stroke-width="1.4"/>' },
  GROUND: { color: "#C99055", glyph: '<path d="M3.5 17.5 9.2 7l3.1 5 2-3.2 6.2 8.7H3.5Z"/><path d="M6.2 17.5h11.6" stroke="#171925" stroke-opacity=".28" stroke-width="1.4"/>' },
  ROCK: { color: "#A18C5D", glyph: '<path d="m5 17-1.2-6.7L9 4.8l6.9 1.1 4.1 6.3-4.8 5.6L5 17Z"/><path d="m9 4.8 2.5 7.2L4 10.3m7.5 1.7 4.4-6.1m-4.4 6.1 3.7 5.8" fill="none" stroke="#171925" stroke-opacity=".25" stroke-width="1.2"/>' },
  BUG: { color: "#86A83E", glyph: '<ellipse cx="12" cy="13" rx="5.2" ry="6.5"/><path d="M12 6.5V19M7 11h10M6.5 8.5 4 6m13.5 2.5L20 6M6.5 14 3.5 15.5m14-1.5 3 1.5M8 6 6.2 3.8M16 6l1.8-2.2" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>' },
  GHOST: { color: "#7168AA", glyph: '<path d="M5 19V11a7 7 0 0 1 14 0v8l-3-2-2 2-2-2-2 2-2-2-3 2Z"/><circle cx="9.5" cy="11" r="1.3" fill="#171925"/><circle cx="14.5" cy="11" r="1.3" fill="#171925"/>' },
  STEEL: { color: "#7897A5", glyph: '<path d="m7 4 10 0 5 8-5 8H7l-5-8 5-8Z"/><circle cx="12" cy="12" r="4" fill="#171925" fill-opacity=".8"/><circle cx="12" cy="12" r="2.2" fill="currentColor"/>' },
  QMARKS: { color: "#626A79", glyph: '<path d="M8.2 8.2a4 4 0 1 1 5.2 3.8c-1 .4-1.4 1-1.4 2.1" fill="none" stroke="currentColor" stroke-width="2.7" stroke-linecap="round"/><circle cx="12" cy="18" r="1.5"/>' },
  FIRE: { color: "#EF6A52", glyph: '<path d="M13.7 2.5c.8 4-2 5.2-2 7.5-1.1-.8-1.7-2-1.5-3.4C6.8 9 5 11.5 5 14.2A7 7 0 0 0 19 14c0-4-2.4-7.4-5.3-11.5ZM12 19c-2.2 0-3.6-1.5-3.2-3.5.3-1.3 1.3-2.4 2.8-3.5-.2 1.6.8 2.3 1.5 3.1.6.8.5 2.6-1.1 3.9Z"/>' },
  WATER: { color: "#4B90E2", glyph: '<path d="M12 2.5S5.8 9.7 5.8 14a6.2 6.2 0 0 0 12.4 0C18.2 9.7 12 2.5 12 2.5Z"/><path d="M9 15.2c.5 1.7 1.7 2.5 3.5 2.5" fill="none" stroke="#171925" stroke-opacity=".3" stroke-width="1.4" stroke-linecap="round"/>' },
  GRASS: { color: "#5AAA61", glyph: '<path d="M19.8 4.2C12 4.2 6.3 7.1 5.2 13.1c-.4 2.4 1.1 4.6 3.5 4.7 5.8.3 9.4-5.8 11.1-13.6Z"/><path d="M4 20c3.2-5.2 7.1-8.8 12-11" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>' },
  ELECTRIC: { color: "#E4B93F", glyph: '<path d="M13.2 2 5.5 13h5l-1 9L19 9.3h-5.3L13.2 2Z"/>' },
  PSYCHIC: { color: "#E26698", glyph: '<path d="M2.5 12s3.5-6 9.5-6 9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6Z"/><circle cx="12" cy="12" r="4.2" fill="#171925" fill-opacity=".82"/><circle cx="12" cy="12" r="2" fill="currentColor"/>' },
  ICE: { color: "#62B7C6", glyph: '<path d="M12 2v20M3.3 7l17.4 10M20.7 7 3.3 17M8.5 4.2 12 6.3l3.5-2.1M8.5 19.8 12 17.7l3.5 2.1M3.5 11.2 7 13.3l-.1 4.1M20.5 12.8 17 10.7l.1-4.1" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>' },
  DRAGON: { color: "#666FD3", glyph: '<path d="M4 18c1.2-7 5.3-11.5 12.5-13.5L15 9l5 1.5-3.8 3.1 2 4.4-5.3-1.8L9.5 21 9 15.5 4 18Z"/><circle cx="14.2" cy="9.2" r="1" fill="#171925"/>' },
  DARK: { color: "#5F6473", glyph: '<path d="M17.8 4.2A8.5 8.5 0 1 0 20 16.8 7 7 0 1 1 17.8 4.2Z"/><path d="m16.3 9 .8 1.7 1.9.2-1.4 1.3.4 1.9-1.7-.9-1.7.9.4-1.9-1.4-1.3 1.9-.2.8-1.7Z"/>' },
  FAIRY: { color: "#D77FBC", glyph: '<path d="m12 2 1.8 6.2L20 10l-6.2 1.8L12 18l-1.8-6.2L4 10l6.2-1.8L12 2Z"/><path d="m18.5 15 .7 2.3 2.3.7-2.3.7-.7 2.3-.7-2.3-2.3-.7 2.3-.7.7-2.3Z"/>' },
};

const CATEGORY_VISUALS = {
  Physical: { label: "Físico", color: "#E35D62", glyph: '<path d="m12 2 2.2 5.2L19 4.5l-.7 5.8 5.2 1.7-5.2 1.7.7 5.8-4.8-2.7L12 22l-2.2-5.2L5 19.5l.7-5.8L.5 12l5.2-1.7L5 4.5l4.8 2.7L12 2Z"/><circle cx="12" cy="12" r="3.3" fill="#171925" fill-opacity=".42"/>' },
  Special: { label: "Especial", color: "#5B83DD", glyph: '<circle cx="12" cy="12" r="8" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="4.5" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="1.8"/>' },
  Status: { label: "Estado", color: "#898EA5", glyph: '<path d="M18.5 8.5c-1.4-3.7-6-5.2-9.4-3.1C5.8 7.5 5 12 7.5 15c2.3 2.8 6.7 2.9 9 .2 1.9-2.2 1.4-5.7-1.1-7.2-2.2-1.3-5-.3-5.8 2.1-.6 1.9.7 4 2.7 4.2 1.5.1 2.9-.8 3.3-2.2" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/><circle cx="15.8" cy="12" r="1.5"/>' },
};

function glyph(markup) {
  const svg = document.createElementNS(SVG_NS, "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("aria-hidden", "true");
  svg.innerHTML = markup;
  return svg;
}

function badge(className, visual, label, compact) {
  const mark = document.createElement("span");
  mark.className = `${className}${compact ? " is-compact" : ""}`;
  mark.title = label;
  mark.style.setProperty("--badge-color", visual.color);
  const icon = document.createElement("span");
  icon.className = "pepbs-badge-icon";
  icon.appendChild(glyph(visual.glyph));
  const copy = document.createElement("span");
  copy.className = "pepbs-badge-copy";
  copy.textContent = label;
  mark.append(icon, copy);
  return mark;
}

export function createTypeBadge(type, label, compact = false) {
  const visual = TYPE_VISUALS[type] || TYPE_VISUALS.QMARKS;
  return badge("pepbs-type-logo", visual, label || type || "Sin tipo", compact);
}

export function createCategoryBadge(category, compact = false) {
  const visual = CATEGORY_VISUALS[category] || CATEGORY_VISUALS.Status;
  return badge("pepbs-category-logo", visual, t(visual.label), compact);
}
