import { MOD_MANIFEST_PATH } from "../core/mod_config.js";
import { t } from "../ui/i18n.js";

export const PBS_KINDS = Object.freeze(["pokemon", "moves", "items", "abilities", "trainers"]);
export const WORLD_KINDS = Object.freeze(["townMap", "encounters", "metadata", "connections"]);
export const FALLBACK_MOD_VERSION = "1.0.0";

export const KIND_META = Object.freeze({
  pokemon: { label: "Pokémon" },
  moves: { label: "Movimientos" },
  items: { label: "Objetos" },
  abilities: { label: "Habilidades" },
  trainers: { label: "Entrenadores" },
  trainerTypes: { label: "Tipos de entrenador" },
  townMap: { label: "Mapa regional" },
  encounters: { label: "Encuentros" },
  metadata: { label: "Metadatos" },
  connections: { label: "Conexiones" },
  ebdx: { label: "Posiciones EBDX" },
});

export const TAB_LABELS = Object.freeze({
  identity: "Identidad",
  stats: "Estadísticas",
  abilities: "Habilidades",
  moves: "Movimientos",
  evolution: "Evolución",
  visual: "Posición",
  form: "Forma",
  trainer: "Entrenador",
  trainerType: "Tipo",
  team: "Equipo",
});

export function formatModVersion(version = FALLBACK_MOD_VERSION) {
  return `v${version} · Pokémon Essentials 19.1`;
}

export async function readModVersion(ctx) {
  try {
    const manifest = JSON.parse(await ctx.fs.readProjectFile(MOD_MANIFEST_PATH));
    return String(manifest?.version || FALLBACK_MOD_VERSION);
  } catch {
    return FALLBACK_MOD_VERSION;
  }
}

export function displayName(kind, entry, documents) {
  if (!entry) return "";
  if (kind === "townMap") return entry.name || `Region ${entry.regionId}`;
  if (kind === "encounters") return entry.mapName || `Map ${entry.mapId}`;
  if (kind === "metadata") return entry.mapId === 0 ? t("Configuración global") : `Map ${entry.mapId}`;
  if (kind === "connections") return `${entry.mapA} ${entry.directionA} ↔ ${entry.directionB} ${entry.mapB}`;
  if (kind === "ebdx") return entry.formName ? `${entry.name} · ${entry.formName}` : entry.name;
  if (kind === "forms") {
    const base = documents.pokemon.entries.find((item) => item.values.InternalName === entry.species);
    return entry.values.FormName || `${base?.values.Name || entry.species} · ${t("Forma")} ${entry.form}`;
  }
  if (kind === "trainers") return `${entry.values.Name} · ${documents.trainerTypes.entries.find((item) => item.values.InternalName === entry.values.TrainerType)?.values.Name || entry.values.TrainerType}`;
  return entry.values.Name || entry.values.InternalName || `#${entry.idNumber}`;
}

export function internalName(kind, entry) {
  if (kind === "townMap") return `[${entry.regionId}]`;
  if (kind === "encounters") return `[${entry.mapId}${entry.version ? `,${entry.version}` : ""}]`;
  if (kind === "metadata") return `[${String(entry.mapId).padStart(3, "0")}]`;
  if (kind === "connections") return `${entry.mapA},${entry.directionA},${entry.offsetA},${entry.mapB},${entry.directionB},${entry.offsetB}`;
  if (kind === "ebdx") return `[${entry.header}]`;
  if (kind === "forms") return `${entry.species},${entry.form}`;
  if (kind === "trainers") return `[${entry.values.TrainerType},${entry.values.Name}${Number(entry.values.Version) > 0 ? `,${entry.values.Version}` : ""}]`;
  return entry.values.InternalName;
}
