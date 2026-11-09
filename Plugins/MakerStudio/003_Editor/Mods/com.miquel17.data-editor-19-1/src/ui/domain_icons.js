const SVG_NS = "http://www.w3.org/2000/svg";

const ICONS = {
  pokemon: '<circle cx="12" cy="12" r="8.5"/><path d="M3.7 12h5.1m6.4 0h5.1"/><circle cx="12" cy="12" r="3.2"/>',
  forms: '<path d="M8.7 4.1a8.5 8.5 0 1 0 7.8 14.8"/><path d="m15.2 3.8 4.9.7-.7 4.9"/><path d="m19.8 4.8-4.6 4.1"/>',
  moves: '<path d="m13.2 2.8-2.4 6.3-6.7-1 5.2 4.3-3.2 6 5.7-3.6 4.7 4.8-1.7-6.5 6.1-3-6.8-.4-.9-6.9Z"/>',
  items: '<path d="M7.5 8.2h9l1.5 11H6l1.5-11Z"/><path d="M9 8.2V6.7a3 3 0 0 1 6 0v1.5"/>',
  abilities: '<path d="M12 2.8 13.7 9l5.5-2.7-3.1 5.3 5.1 2.1-6.1.7.8 6.2-3.9-4.9-3.9 4.9.8-6.2-6.1-.7 5.1-2.1-3.1-5.3L10.3 9 12 2.8Z"/>',
  trainers: '<circle cx="12" cy="8" r="3.3"/><path d="M5.8 20a6.2 6.2 0 0 1 12.4 0"/>',
  trainerTypes: '<path d="M12 2.8 19 5v5.3c0 4.4-2.7 7.9-7 10.9-4.3-3-7-6.5-7-10.9V5l7-2.2Z"/><path d="m12 7 .9 2.1 2.3.2-1.8 1.5.6 2.2-2-1.2-2 1.2.6-2.2-1.8-1.5 2.3-.2L12 7Z"/>',
  townMap: '<path d="m3.5 6.2 5-2.4 7 2.4 5-2.4v14l-5 2.4-7-2.4-5 2.4v-14Z"/><path d="M8.5 3.8v14m7-11.6v14"/>',
  encounters: '<path d="M12 20V9.5"/><path d="M12 14.5c-4.5 0-7-2.6-7-7 4.5 0 7 2.5 7 7Zm0-4.2c4.5 0 7-2.5 7-7-4.5 0-7 2.5-7 7Z"/>',
  metadata: '<path d="M4 6h6m4 0h6M4 12h10m4 0h2M4 18h3m4 0h9"/><circle cx="12" cy="6" r="2"/><circle cx="16" cy="12" r="2"/><circle cx="9" cy="18" r="2"/>',
  connections: '<path d="m9.2 14.8-1.4 1.4a3.7 3.7 0 0 1-5.2-5.2l3.1-3.1a3.7 3.7 0 0 1 5.2 0"/><path d="m14.8 9.2 1.4-1.4a3.7 3.7 0 0 1 5.2 5.2l-3.1 3.1a3.7 3.7 0 0 1-5.2 0"/><path d="m8.5 15.5 7-7"/>',
  ebdx: '<circle cx="12" cy="12" r="6.5"/><circle cx="12" cy="12" r="2.2"/><path d="M12 2v3.5M12 18.5V22M2 12h3.5M18.5 12H22"/>',
};

export function createDomainIcon(kind, className = "") {
  const iconKind = ICONS[kind] ? kind : "metadata";
  const span = document.createElement("span");
  span.className = `pepbs-domain-icon is-${iconKind}${className ? ` ${className}` : ""}`;
  span.setAttribute("aria-hidden", "true");
  const svg = document.createElementNS(SVG_NS, "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("fill", "none");
  svg.setAttribute("stroke", "currentColor");
  svg.setAttribute("stroke-width", "1.7");
  svg.setAttribute("stroke-linecap", "round");
  svg.setAttribute("stroke-linejoin", "round");
  svg.innerHTML = ICONS[iconKind];
  span.appendChild(svg);
  return span;
}
