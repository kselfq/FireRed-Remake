// Single source of truth for the installation path. If the manifest ID or the
// mod folder is renamed, update MOD_ID here and keep manifest.json in sync.
export const MOD_ID = "com.miquel17.data-editor-19-1";
export const MOD_PROJECT_ROOT = `Plugins/MakerStudio/003_Editor/Mods/${MOD_ID}`;
export const MOD_ASSET_ROOT = `${MOD_PROJECT_ROOT}/assets`;
export const MOD_MANIFEST_PATH = `${MOD_PROJECT_ROOT}/manifest.json`;
export const EBDX_POSITIONER_ASSET_ROOT = `${MOD_ASSET_ROOT}/ebdx-positioner`;
