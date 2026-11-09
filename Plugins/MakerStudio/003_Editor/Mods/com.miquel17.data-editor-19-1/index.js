import { mountPbsEditor } from "./src/app/editor.js";
import { t } from "./src/ui/i18n.js";

let activeDialog = null;
let activeEditor = null;

async function requestClose(ctx) {
  if (!activeEditor?.hasUnsavedChanges()) {
    activeDialog?.close();
    return;
  }
  const result = await ctx.ui.showUnsavedChangesDialog({
    message: t("Hay cambios sin guardar en Data Editor."),
  });
  if (result === "save") {
    const saved = await activeEditor.saveAll();
    if (saved) activeDialog?.close();
  } else if (result === "discard") {
    activeDialog?.close();
  }
}

export function activate(ctx) {
  ctx.menu.registerMenuItem({
    menu: "Mods",
    label: "Data Editor — Pokémon Essentials 19.1",
    shortcut: "Ctrl+Alt+P",
    icon: "database",
    handler: () => {
      if (activeDialog) return;
      activeDialog = ctx.ui.showCustomDialog({
        title: "Data Editor — Pokémon Essentials 19.1",
        width: "95vw",
        height: "91vh",
        render(body) {
          activeEditor = mountPbsEditor(ctx, body);
          return () => {
            activeEditor?.dispose();
            activeEditor = null;
            activeDialog = null;
          };
        },
        onCloseRequest: () => requestClose(ctx),
      });
    },
  });
  ctx.log.info("Data Editor for Pokémon Essentials 19.1 activated (PBS, world data, town map and optional EBDX positioning). ");
}

export function deactivate() {
  activeDialog?.close();
  activeDialog = null;
  activeEditor = null;
}
