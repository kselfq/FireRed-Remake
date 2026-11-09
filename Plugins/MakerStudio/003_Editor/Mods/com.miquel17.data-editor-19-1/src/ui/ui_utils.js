export function h(tag, attrs = {}, ...children) {
  const element = document.createElement(tag);
  for (const [key, value] of Object.entries(attrs || {})) {
    if (key === "className") element.className = value;
    else if (key === "text") element.textContent = value;
    else if (key === "html") element.innerHTML = value;
    else if (key === "style") Object.assign(element.style, value);
    else if (key.startsWith("on") && typeof value === "function") element.addEventListener(key.slice(2).toLowerCase(), value);
    else if (value === true) element.setAttribute(key, "");
    else if (value !== false && value != null) element.setAttribute(key, String(value));
  }
  for (const child of children.flat()) {
    if (child == null) continue;
    element.append(child instanceof Node ? child : document.createTextNode(String(child)));
  }
  return element;
}

export function button(label, onClick, className = "") {
  return h("button", { type: "button", className: `pepbs-btn ${className}`.trim(), onClick, text: label });
}

export function switchControl(checked, onChange, options = {}) {
  const control = h("input", {
    type: "checkbox",
    className: `pepbs-switch ${options.className || ""}`.trim(),
    role: "switch",
    "aria-label": options.label || "",
  });
  control.checked = Boolean(checked);
  control.setAttribute("aria-checked", control.checked ? "true" : "false");
  control.addEventListener("change", () => {
    control.setAttribute("aria-checked", control.checked ? "true" : "false");
    onChange?.(control.checked);
  });
  return control;
}

export function normalize(value) {
  return String(value ?? "").trim();
}

export function optionPairs(options = []) {
  return options.map((option) => Array.isArray(option) ? option : [option, option]);
}

function visibleBoundary(element) {
  const boundary = { top: 0, right: window.innerWidth, bottom: window.innerHeight, left: 0 };
  for (let parent = element.parentElement; parent; parent = parent.parentElement) {
    const style = getComputedStyle(parent);
    const clipsX = /(auto|scroll|hidden|clip)/.test(style.overflowX);
    const clipsY = /(auto|scroll|hidden|clip)/.test(style.overflowY);
    if (!clipsX && !clipsY) continue;
    const rect = parent.getBoundingClientRect();
    // clientWidth/clientHeight exclude native scrollbar gutters. Using the
    // bounding rect alone lets a floating menu end up beneath the scrollbar.
    const verticalScrollbar = Math.max(0, parent.offsetWidth - parent.clientWidth);
    const horizontalScrollbar = Math.max(0, parent.offsetHeight - parent.clientHeight);
    if (clipsX) {
      boundary.left = Math.max(boundary.left, rect.left);
      boundary.right = Math.min(boundary.right, rect.right - verticalScrollbar);
    }
    if (clipsY) {
      boundary.top = Math.max(boundary.top, rect.top);
      boundary.bottom = Math.min(boundary.bottom, rect.bottom - horizontalScrollbar);
    }
  }
  return boundary;
}

export function placeFloatingMenu(anchor, menu, options = {}) {
  if (menu.hidden) return { direction: "down", height: 0 };
  const gap = options.gap ?? 3;
  const minimumHeight = options.minimumHeight ?? 64;
  const horizontalMargin = options.horizontalMargin ?? 4;
  const list = options.list || null;
  menu.style.removeProperty("max-height");
  menu.style.removeProperty("max-width");
  menu.style.removeProperty("min-width");
  menu.style.removeProperty("width");
  menu.style.removeProperty("left");
  menu.style.removeProperty("right");
  if (list) list.style.removeProperty("max-height");
  const boundary = visibleBoundary(anchor);
  const rect = anchor.getBoundingClientRect();
  const below = Math.max(0, boundary.bottom - rect.bottom - gap);
  const above = Math.max(0, rect.top - boundary.top - gap);
  const naturalHeight = Math.max(menu.offsetHeight, Math.min(menu.scrollHeight, options.maximumHeight ?? Infinity));
  const opensUp = below < naturalHeight && above > below;
  const available = opensUp ? above : below;
  const height = Math.max(Math.min(minimumHeight, Math.max(above, below)), Math.min(naturalHeight, available));
  anchor.classList.toggle("opens-up", opensUp);
  menu.style.maxHeight = `${Math.max(1, Math.floor(height))}px`;
  if (list) {
    const menuChrome = Math.max(0, menu.offsetHeight - list.offsetHeight);
    list.style.maxHeight = `${Math.max(40, Math.floor(height - menuChrome))}px`;
  }
  // Keep popovers inside the scrollable editor pane as well as the viewport.
  // This matters for wide visual pickers (types/categories) next to a sidebar.
  const availableWidth = Math.max(1, boundary.right - boundary.left - horizontalMargin * 2);
  const preferredWidth = Math.max(rect.width, options.preferredWidth ?? menu.offsetWidth);
  const width = Math.min(preferredWidth, availableWidth);
  const desiredLeft = Math.min(
    Math.max(rect.left, boundary.left + horizontalMargin),
    boundary.right - horizontalMargin - width,
  );
  menu.style.width = `${Math.floor(width)}px`;
  menu.style.minWidth = "0";
  menu.style.maxWidth = `${Math.floor(availableWidth)}px`;
  menu.style.left = `${Math.round(desiredLeft - rect.left)}px`;
  menu.style.right = "auto";
  return { direction: opensUp ? "up" : "down", height, width };
}

export function dropdown(value, options, onChange, config = {}) {
  const items = optionPairs(options).map(([itemValue, label]) => ({ value: String(itemValue), label: String(label) }));
  let current = String(value ?? "");
  const root = h("div", { className: "pepbs-dropdown" });
  const trigger = h("button", {
    type: "button",
    className: "pepbs-dropdown-trigger",
    role: "combobox",
    "aria-haspopup": "listbox",
    "aria-expanded": "false",
    "aria-label": config.label || "",
  });
  const currentLabel = h("span", { className: "pepbs-dropdown-value" });
  const arrow = h("span", { className: "pepbs-dropdown-arrow", "aria-hidden": "true" });
  const menu = h("div", { className: "pepbs-dropdown-menu", role: "listbox", hidden: true });
  const searchable = config.searchable ?? items.length > 12;
  const search = searchable ? h("input", {
    className: "pepbs-dropdown-search",
    type: "search",
    placeholder: config.searchPlaceholder || "Search…",
    autocomplete: "off",
  }) : null;
  const list = h("div", { className: "pepbs-dropdown-options" });

  function selectedItem() {
    return items.find((item) => item.value === current);
  }

  function refreshTrigger() {
    const item = selectedItem();
    currentLabel.textContent = item?.label || config.placeholder || "";
    currentLabel.classList.toggle("is-placeholder", !item);
    root.dataset.value = current;
  }

  function close({ focusTrigger = false } = {}) {
    menu.hidden = true;
    trigger.setAttribute("aria-expanded", "false");
    root.classList.remove("is-open");
    root.classList.remove("opens-up");
    menu.style.removeProperty("max-height");
    list.style.removeProperty("max-height");
    if (search) search.value = "";
    if (focusTrigger) trigger.focus();
  }

  function choose(next, emit = true) {
    current = String(next ?? "");
    refreshTrigger();
    renderOptions();
    close();
    if (emit) onChange?.(current);
  }

  function renderOptions(query = "") {
    list.innerHTML = "";
    const normalized = String(query).trim().toLocaleLowerCase("es");
    const filtered = normalized
      ? items.filter((item) => (item.label + " " + item.value).toLocaleLowerCase("es").includes(normalized))
      : items;
    filtered.forEach((item) => {
      list.appendChild(h("button", {
        type: "button",
        role: "option",
        className: "pepbs-dropdown-option " + (item.value === current ? "is-active" : ""),
        "aria-selected": item.value === current ? "true" : "false",
        onClick: () => choose(item.value),
      }, h("span", { text: item.label }), item.value === current ? h("span", { className: "pepbs-dropdown-check", text: "✓" }) : null));
    });
    if (!filtered.length) list.appendChild(h("div", { className: "pepbs-dropdown-empty", text: config.noMatches || "No matches." }));
  }

  function focusOption(direction) {
    const options = [...list.querySelectorAll(".pepbs-dropdown-option")];
    if (!options.length) return;
    const currentIndex = options.indexOf(document.activeElement);
    const nextIndex = currentIndex < 0
      ? (direction > 0 ? 0 : options.length - 1)
      : Math.max(0, Math.min(options.length - 1, currentIndex + direction));
    options[nextIndex].focus();
  }

  function placeMenu() {
    placeFloatingMenu(root, menu, { list, maximumHeight: 310 });
  }

  function open() {
    renderOptions();
    menu.hidden = false;
    trigger.setAttribute("aria-expanded", "true");
    root.classList.add("is-open");
    placeMenu();
    if (search) requestAnimationFrame(() => search.focus());
  }

  trigger.append(currentLabel, arrow);
  trigger.addEventListener("click", () => { if (menu.hidden) open(); else close(); });
  trigger.addEventListener("keydown", (event) => {
    if (event.key === "ArrowDown" || event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      if (menu.hidden) open();
      else if (event.key === "ArrowDown") focusOption(1);
    } else if (event.key === "Escape" && !menu.hidden) {
      event.preventDefault(); close({ focusTrigger: true });
    }
  });
  if (search) {
    search.addEventListener("input", () => renderOptions(search.value));
    search.addEventListener("keydown", (event) => {
      if (event.key === "Escape") { event.preventDefault(); close({ focusTrigger: true }); }
      if (event.key === "ArrowDown") {
        const first = list.querySelector(".pepbs-dropdown-option");
        if (first) { event.preventDefault(); first.focus(); }
      }
    });
    menu.appendChild(search);
  }
  list.addEventListener("keydown", (event) => {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault(); focusOption(event.key === "ArrowDown" ? 1 : -1);
    } else if (event.key === "Escape") {
      event.preventDefault(); close({ focusTrigger: true });
    } else if (event.key === "Home" || event.key === "End") {
      event.preventDefault();
      const options = [...list.querySelectorAll(".pepbs-dropdown-option")];
      options[event.key === "Home" ? 0 : options.length - 1]?.focus();
    }
  });
  menu.appendChild(list);
  root.addEventListener("focusout", () => setTimeout(() => {
    if (!root.contains(document.activeElement)) close();
  }, 0));
  Object.defineProperty(root, "value", {
    get: () => current,
    set: (next) => { current = String(next ?? ""); refreshTrigger(); renderOptions(); },
  });
  root.setValue = (next, emit = false) => choose(next, emit);
  root.append(trigger, menu);
  refreshTrigger();
  return root;
}
