import { h, placeFloatingMenu } from "./ui_utils.js";
import { t } from "./i18n.js";
import { createCategoryBadge, createTypeBadge } from "./visual_badges.js";

const CATEGORY_LABELS = Object.freeze({
  Physical: "Físico",
  Special: "Especial",
  Status: "Estado",
});

function typeBadge(type, types, compact = false) {
  const record = types.find((item) => item.id === type);
  return createTypeBadge(type, t(record?.name || type || "Sin tipo"), compact);
}

function categoryLabel(category) {
  return t(CATEGORY_LABELS[category] || CATEGORY_LABELS.Status);
}

export function createTypePicker(value, onInput, types = [], placeholder = "") {
  const resolvedPlaceholder = placeholder || t("Elegir tipo…");
  let current = value || "";
  const details = h("details", { className: "pepbs-type-picker" });
  const summary = h("summary", { className: "pepbs-type-summary", "aria-label": current ? t(`Tipo ${current}`) : resolvedPlaceholder });
  const refresh = () => {
    summary.innerHTML = "";
    summary.setAttribute("aria-label", current ? t(`Tipo ${current}`) : resolvedPlaceholder);
    if (current) summary.append(typeBadge(current, types));
    else summary.appendChild(h("span", { className: "pepbs-type-placeholder", text: resolvedPlaceholder }));
  };
  const menu = h("div", { className: "pepbs-type-menu" });

  menu.appendChild(h("button", {
    type: "button",
    className: "pepbs-type-option is-empty",
    text: t("— Sin valor —"),
    onClick: () => { current = ""; onInput(""); refresh(); details.open = false; },
  }));
  for (const type of types) {
    menu.appendChild(h("button", {
      type: "button",
      title: t(type.name || type.id),
      className: `pepbs-type-option ${type.id === current ? "is-active" : ""}`,
      onClick: () => { current = type.id; onInput(type.id); refresh(); details.open = false; },
    }, typeBadge(type.id, types)));
  }

  refresh();
  details.append(summary, menu);
  details.addEventListener("toggle", () => {
    if (details.open) placeFloatingMenu(details, menu, { maximumHeight: 290, preferredWidth: 320, horizontalMargin: 8 });
    else details.classList.remove("opens-up");
  });
  return details;
}

export function createCategoryPicker(value, onInput, categories = []) {
  let current = value || "Status";
  const details = h("details", { className: "pepbs-category-picker" });
  const summary = h("summary", {
    className: "pepbs-category-summary",
    "aria-label": `${t("Categoría")} ${categoryLabel(current)}`,
  }, createCategoryBadge(current));
  const menu = h("div", { className: "pepbs-category-menu" });
  const refresh = () => {
    summary.innerHTML = "";
    summary.setAttribute("aria-label", `${t("Categoría")} ${categoryLabel(current)}`);
    summary.appendChild(createCategoryBadge(current));
  };

  for (const category of categories) {
    menu.appendChild(h("button", {
      type: "button",
      className: `pepbs-category-option ${category === current ? "is-active" : ""}`,
      title: categoryLabel(category),
      onClick: () => { current = category; onInput(category); refresh(); details.open = false; },
    }, createCategoryBadge(category)));
  }

  details.append(summary, menu);
  details.addEventListener("toggle", () => {
    if (details.open) placeFloatingMenu(details, menu, { maximumHeight: 290, preferredWidth: 300, horizontalMargin: 8 });
    else details.classList.remove("opens-up");
  });
  return details;
}
