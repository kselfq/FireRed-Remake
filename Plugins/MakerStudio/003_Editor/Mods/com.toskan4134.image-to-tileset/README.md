# Example: Image to Tileset

Adds a "Tools → Create Tileset from Image..." menu item. Opens a floating
window where you pick an image, configure tile size, preview it rearranged
into 8-tile-wide rows (RMXP format), and create a full tileset entry.

### What it does

1. Registers a **Tools** menu item that opens a floating dialog window
2. Uses the native file picker (`plugin:dialog|open`) to select an image
3. Shows a live preview with tiles rearranged into 8-wide rows and grid overlay
4. Lets you set tile size (default 32px) or check "Adapt to map" to auto-calculate
5. Processes the image into a proper tileset layout (8 tiles wide)
6. Saves the processed PNG to `Graphics/Tilesets/<name>.png`
7. Creates a tileset entry in `Tilesets.rxdata` via `create_tileset`

> **Note**: `plugin:dialog|open` is a Tauri dialog plugin command — the "plugin" prefix is Tauri's naming, not the editor's mod system.

### Tile size modes

- **Manual**: set any tile size (8–256px). Image is sliced into tiles and
  rearranged into 8-tile-wide rows.
- **Adapt to map**: enter map width/height in tiles. Calculates the smallest
  tile size that covers the image, so the image fills the map as background.

### Key patterns

- **`window.__TAURI__.core.invoke`** — calls Tauri commands directly without
  extending the mod API. Available because `withGlobalTauri` is enabled.
- **Floating window** — creates DOM elements with `position: fixed` and
  `z-index: 5000` (modal layer) instead of using `ctx.ui.registerPanel()`
  which creates a dockview section.
- **Canvas processing** — uses `HTMLCanvasElement` to rearrange tiles into
  8-wide rows, then `canvas.toBlob()` + `write_binary_file` to save as PNG.
- **Full tileset creation** — uses `list_tileset_files` to check for name
  collisions, `write_binary_file` to save the image, and `create_tileset` to
  register it in `Tilesets.rxdata`.

### Commands used

| Command | Purpose |
|---------|---------|
| `plugin:dialog\|open` | Native file picker |
| `read_binary_file` | Read source image |
| `write_binary_file` | Save processed tileset PNG |
| `list_tileset_files` | Check name collisions |
| `create_tileset` | Register tileset in Tilesets.rxdata |

### Manifest

```json
{
  "id": "com.toskan4134.image-to-tileset",
  "name": "Image to Tileset",
  "version": "1.0.0",
  "description": "Import any image as a new tileset with auto-processing.",
  "apiVersion": "1.0.0",
  "main": "index.js",
  "permissions": ["fs.project", "fs.write.project", "ui.dialogs", "ui.toasts"]
}
```
