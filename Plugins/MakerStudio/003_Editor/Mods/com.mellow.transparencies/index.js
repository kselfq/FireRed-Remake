/**
 * [MDLN] Transparencies
 *
 * Registers Priority 666 ("Transparencies") in the tileset dropdown for use
 * with the Ruby plugin `[MDLN] Building Transparency`. Also scrubs gap options
 * (6..665) that Maker Studio may inject when a high custom priority is registered.
 */

// ponytail: marker for [MDLN] Building Transparency fade (Z remapped to 5 in-game)
const TRANSPARENCY_PRIORITY = 666;
const TRANSPARENCY_PRIORITY_NAME = "Transparencies";
const TRANSPARENCY_PRIORITY_LABEL = `${TRANSPARENCY_PRIORITY}: ${TRANSPARENCY_PRIORITY_NAME}`;

// Maker Studio may fill every integer from 6..maxId as bare options when a high
// custom priority (666) is registered. Hide those gaps and force our label.
let priorityListObserver = null;

function isPriorityDropdownRoot(el) {
  if (!el || el.nodeType !== 1) return false;
  const t = el.textContent || "";
  return t.includes("Above 5") && (t.includes("Below") || t.includes("Filter"));
}

function scrubPriorityOptionNode(el) {
  if (!el || el.nodeType !== 1) return;
  if (el.children && el.children.length > 2) return;
  const raw = (el.textContent || "").replace(/\s+/g, " ").trim();
  if (!raw) return;

  // Exact bare number in the gap range → hide row
  if (/^\d+$/.test(raw)) {
    const n = Number(raw);
    if (n >= 6 && n < TRANSPARENCY_PRIORITY) {
      const row = el.closest?.('[role="option"], li, [class*="option"], [class*="item"]') || el;
      row.style.display = "none";
      row.setAttribute("data-tr-priority-gap", "1");
      return;
    }
    if (n === TRANSPARENCY_PRIORITY) {
      el.textContent = TRANSPARENCY_PRIORITY_LABEL;
      return;
    }
  }

  // "666" or "666:" without name → full label
  if (raw === String(TRANSPARENCY_PRIORITY) || raw === `${TRANSPARENCY_PRIORITY}:`) {
    el.textContent = TRANSPARENCY_PRIORITY_LABEL;
    return;
  }

  // "666: transparencia" (old name) → rename
  if (/^666\s*:\s*/i.test(raw) && !raw.includes(TRANSPARENCY_PRIORITY_NAME)) {
    el.textContent = TRANSPARENCY_PRIORITY_LABEL;
  }
}

function scrubPriorityDropdown(root) {
  if (!root || !root.querySelectorAll) return;
  const nodes = root.querySelectorAll('[role="option"], li, button, span, div');
  for (const el of nodes) scrubPriorityOptionNode(el);
}

function startPriorityListObserver() {
  if (priorityListObserver || typeof MutationObserver === "undefined") return;
  priorityListObserver = new MutationObserver((mutations) => {
    for (const m of mutations) {
      for (const node of m.addedNodes) {
        if (node.nodeType !== 1) continue;
        if (isPriorityDropdownRoot(node) || isPriorityDropdownRoot(node.parentElement)) {
          scrubPriorityDropdown(isPriorityDropdownRoot(node) ? node : node.parentElement);
        } else if ((node.textContent || "").includes("Above 5")) {
          let p = node;
          for (let i = 0; i < 6 && p; i++, p = p.parentElement) {
            if (isPriorityDropdownRoot(p)) {
              scrubPriorityDropdown(p);
              break;
            }
          }
        }
      }
    }
  });
  priorityListObserver.observe(document.body, { childList: true, subtree: true });
}

function stopPriorityListObserver() {
  if (priorityListObserver) {
    priorityListObserver.disconnect();
    priorityListObserver = null;
  }
}

export async function activate(ctx) {
  ctx.log.info("[Transparency] activated");

  if (typeof ctx.tileset.registerPriority === "function") {
    ctx.tileset.registerPriority({
      id: TRANSPARENCY_PRIORITY,
      name: TRANSPARENCY_PRIORITY_NAME,
    });
    ctx.log.info(`[Transparency] priority registered: ${TRANSPARENCY_PRIORITY_LABEL}`);
    startPriorityListObserver();
  } else {
    ctx.log.warn("[Transparency] registerPriority missing — update Maker Studio");
  }
}

export function deactivate() {
  stopPriorityListObserver();
}
