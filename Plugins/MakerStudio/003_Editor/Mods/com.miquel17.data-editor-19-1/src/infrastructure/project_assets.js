const AUDIO_EXTENSIONS = /\.(mid|midi|ogg|mp3|wav|flac)$/i;
const IMAGE_EXTENSIONS = /\.(png|gif|jpe?g|bmp)$/i;

function normalizeDirectoryEntry(entry) {
  if (typeof entry === "string") return { name: entry.split(/[\\/]/).pop(), isFile: true };
  const name = entry?.name || String(entry?.path || "").split(/[\\/]/).pop();
  const isDirectory = entry?.isDirectory ?? entry?.is_directory ?? entry?.isDir ?? entry?.is_dir ?? entry?.directory;
  const declaredFile = entry?.isFile ?? entry?.is_file ?? entry?.file;
  const kind = String(entry?.kind ?? entry?.type ?? "").toLowerCase();
  const isFile = declaredFile ?? (isDirectory != null ? !isDirectory : !["directory", "dir", "folder"].includes(kind));
  return { name, isFile: Boolean(isFile) };
}

export function createProjectAssets(ctx) {
  const transientUrls = new Set();
  const persistentUrls = new Map();

  function revokeBlobUrl(url) {
    if (typeof url !== "string" || !url.startsWith("blob:")) return;
    try { URL.revokeObjectURL(url); } catch { /* A WebView may invalidate blob URLs while the game is running. */ }
  }

  function rootPath() {
    return ctx.editor?.gameRoot?.()?.replace(/[\\/]$/, "") || "";
  }

  async function projectEntries(relativeFolder) {
    const relative = String(relativeFolder || "").replace(/^[\\/]+|[\\/]+$/g, "");
    if (typeof ctx.fs?.listProjectDir === "function") {
      return ctx.fs.listProjectDir(relative + "/");
    }
    const invoke = window.__TAURI__?.core?.invoke;
    const root = rootPath();
    if (!invoke || !root) return [];
    return invoke("list_directory", { path: root + "/" + relative });
  }

  async function graphicNames(folder) {
    const invoke = window.__TAURI__?.core?.invoke;
    const root = rootPath();
    if (invoke && root && !/[\\/]/.test(folder)) {
      try {
        const names = await invoke("list_graphic_files", { gameRoot: root, folder });
        if (Array.isArray(names)) return names.map(String);
      } catch { /* The public project filesystem remains a compatible fallback. */ }
    }
    try {
      const files = await projectEntries("Graphics/" + folder);
      return files.map(normalizeDirectoryEntry)
        .filter((entry) => entry.isFile && IMAGE_EXTENSIONS.test(entry.name))
        .map((entry) => entry.name.replace(/\.[^.]+$/, ""));
    } catch (error) {
      ctx.log.warn(`Data Editor could not list Graphics/${folder}: ${error?.message || error}`);
      return [];
    }
  }

  async function readImage(relative) {
    const invoke = window.__TAURI__?.core?.invoke;
    const root = rootPath();
    if (!invoke || !root) return null;
    const normalized = String(relative).replace(/\\/g, "/");
    const match = /^Graphics\/([^/]+)\/(.+?)(?:\.[^.]+)?$/i.exec(normalized);
    let bytes = null;
    if (match && !/[\\/]/.test(match[1])) {
      try {
        bytes = await invoke("get_graphic_image", { gameRoot: root, folder: match[1], name: match[2] });
      } catch { /* Fall back to the exact project path for older Maker Studio builds. */ }
    }
    if (!bytes) {
      if (!(await ctx.fs.projectExists(normalized))) return null;
      bytes = await invoke("read_binary_file", { path: root + "/" + normalized });
    }
    return URL.createObjectURL(new Blob([new Uint8Array(bytes)], { type: "image/png" }));
  }

  async function firstImage(candidates, persistent = false) {
    const key = candidates.join("|");
    if (persistent && persistentUrls.has(key)) return persistentUrls.get(key);
    for (const relative of candidates) {
      try {
        const url = await readImage(relative);
        if (!url) continue;
        if (persistent) persistentUrls.set(key, url);
        else transientUrls.add(url);
        return url;
      } catch { /* Continue with the next compatible Essentials filename. */ }
    }
    return null;
  }

  async function audio(folder) {
    try {
      const entries = await projectEntries("Audio/" + folder);
      return [...new Set(entries.map(normalizeDirectoryEntry)
        .filter((entry) => entry.isFile && AUDIO_EXTENSIONS.test(entry.name))
        .map((entry) => entry.name.replace(/\.[^.]+$/, "")))]
        .sort((a, b) => a.localeCompare(b, "es", { numeric: true }));
    } catch (error) {
      ctx.log.warn(`Data Editor could not list Audio/${folder}: ${error?.message || error}`);
      return [];
    }
  }

  async function directoryFiles(relativeFolder, extensions = IMAGE_EXTENSIONS) {
    try {
      const entries = await projectEntries(relativeFolder);
      return entries.map(normalizeDirectoryEntry).filter((entry) => entry.isFile && entry.name && extensions.test(entry.name)).map((entry) => entry.name).sort((a, b) => a.localeCompare(b, "en", { numeric: true }));
    } catch (error) {
      ctx.log.warn(`Data Editor could not list ${relativeFolder}: ${error?.message || error}`);
      return [];
    }
  }

  function clearTransient() {
    for (const url of transientUrls) revokeBlobUrl(url);
    transientUrls.clear();
  }

  async function initialize() {
    const [bgm, me, characters, pictures, battlebackFiles] = await Promise.all([
      audio("BGM"), audio("ME"), graphicNames("Characters"), graphicNames("Pictures"), graphicNames("Battlebacks"),
    ]);
    const stripExtension = (name) => name.replace(/\.[^.]+$/, "");
    const battlebacks = [...new Set(battlebackFiles.map(stripExtension).map((name) => name.replace(/_(?:bg|base0|base1|message)$/i, "")).filter((name) => battlebackFiles.some((file) => stripExtension(file).toLowerCase() === `${name.toLowerCase()}_bg`)))];
    return {
      audio: { bgm, me },
      graphics: {
        characters: characters.map(stripExtension),
        pictures: pictures.map(stripExtension),
        battlebacks,
      },
    };
  }

  function dispose() {
    clearTransient();
    for (const url of persistentUrls.values()) revokeBlobUrl(url);
    persistentUrls.clear();
  }

  return {
    initialize,
    loadTransient: (candidates) => firstImage(candidates, false),
    loadPersistent: (candidates) => firstImage(candidates, true),
    listFiles: directoryFiles,
    listGraphics: graphicNames,
    clearTransient,
    dispose,
  };
}
