export const EBDX_METRICS_PATH = "PBS/EBDX/pokemon.txt";
export const EBDX_PLUGIN_MARKER = "Plugins/Elite Battle DX/meta.txt";

export const POSITION_FIELDS = [
  "BattlerEnemyX",
  "BattlerEnemyY",
  "BattlerPlayerX",
  "BattlerPlayerY",
  "BattlerAltitude",
];

const OPTIONAL_RENDER_FIELDS = ["SpriteScaleEnemy", "SpriteScalePlayer"];
const ALL_READ_FIELDS = [...POSITION_FIELDS, ...OPTIONAL_RENDER_FIELDS];

function splitText(text) {
  const source = String(text ?? "");
  const bom = source.startsWith("\uFEFF");
  const body = bom ? source.slice(1) : source;
  const newline = body.includes("\r\n") ? "\r\n" : "\n";
  const finalNewline = body.endsWith("\n");
  const lines = body.split(/\r?\n/);
  if (finalNewline) lines.pop();
  return { source, bom, newline, finalNewline, lines };
}

function joinText(document, lines) {
  const body = lines.join(document.newline) + (document.finalNewline ? document.newline : "");
  return `${document.bom ? "\uFEFF" : ""}${body}`;
}

function identityFromHeader(header) {
  const formMatch = String(header).match(/^(.+?)([,\-])(\d+)$/);
  if (!formMatch) return { species: String(header), form: 0, delimiter: "," };
  return { species: formMatch[1], form: Number(formMatch[3]), delimiter: formMatch[2] };
}

function parseInteger(rawValue) {
  const value = String(rawValue ?? "").trim().split(",")[0]?.trim();
  if (!/^[+-]?\d+$/.test(value)) return null;
  return Number(value);
}

function parseNumber(rawValue) {
  const value = String(rawValue ?? "").trim().split(",")[0]?.trim();
  if (!/^[+-]?(?:\d+(?:\.\d+)?|\.\d+)$/.test(value)) return null;
  return Number(value);
}

export function parseEbdxMetrics(text) {
  const base = splitText(text);
  const records = [];
  const byIdentity = new Map();
  const issues = [];
  let current = null;
  let subsection = "__pk__";

  base.lines.forEach((rawLine, lineIndex) => {
    const header = rawLine.trim().match(/^\[([^\]]+)\]$/);
    if (header) {
      if (current) current.endIndex = lineIndex;
      const identity = identityFromHeader(header[1]);
      current = {
        ...identity,
        header: header[1],
        key: `${identity.species},${identity.form}`,
        startIndex: lineIndex,
        endIndex: base.lines.length,
        rootEndIndex: null,
        assignments: new Map(),
        values: {},
      };
      records.push(current);
      if (byIdentity.has(current.key)) issues.push(`La métrica EBDX ${current.header} está duplicada.`);
      else byIdentity.set(current.key, current);
      subsection = "__pk__";
      return;
    }
    if (!current) return;
    const uncommented = rawLine.split("#", 1)[0].trim();
    if (!uncommented) return;
    const assignment = uncommented.match(/^([A-Za-z][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (!assignment || !assignment[2].trim()) {
      subsection = assignment?.[1] || uncommented;
      if (current.rootEndIndex === null) current.rootEndIndex = lineIndex;
      return;
    }
    if (subsection !== "__pk__" || !ALL_READ_FIELDS.includes(assignment[1])) return;
    const number = POSITION_FIELDS.includes(assignment[1]) ? parseInteger(assignment[2]) : parseNumber(assignment[2]);
    if (number === null) {
      issues.push(`La métrica ${assignment[1]} de [${current.header}] debe ser un número entero.`);
      return;
    }
    current.assignments.set(assignment[1], lineIndex);
    current.values[assignment[1]] = number;
  });
  if (current) current.endIndex = base.lines.length;
  for (const record of records) if (record.rootEndIndex === null) record.rootEndIndex = record.endIndex;
  return { ...base, records, byIdentity, issues };
}

function speciesCatalog(documents) {
  const formsBySpecies = new Map();
  for (const form of documents.forms.entries) {
    const list = formsBySpecies.get(form.species) || [];
    list.push(form);
    formsBySpecies.set(form.species, list);
  }
  const entries = [];
  for (const pokemon of documents.pokemon.entries) {
    const species = pokemon.values.InternalName;
    entries.push({
      species,
      form: 0,
      idNumber: Number(pokemon.idNumber),
      name: pokemon.values.Name || species,
      formName: "",
    });
    for (const form of (formsBySpecies.get(species) || []).sort((a, b) => Number(a.form) - Number(b.form))) {
      entries.push({
        species,
        form: Number(form.form),
        idNumber: Number(pokemon.idNumber),
        name: pokemon.values.Name || species,
        formName: form.values.FormName || `Form ${form.form}`,
      });
    }
  }
  return entries;
}

export function buildEbdxWorkspace(text, documents, exists = true) {
  const parsed = parseEbdxMetrics(text);
  const entries = speciesCatalog(documents).map((catalogEntry) => {
    const key = `${catalogEntry.species},${catalogEntry.form}`;
    const source = parsed.byIdentity.get(key);
    const values = Object.fromEntries(POSITION_FIELDS.map((field) => [field, source?.values[field] ?? 0]));
    return {
      kind: "ebdx",
      key,
      ...catalogEntry,
      header: source?.header || `${catalogEntry.species}${catalogEntry.form ? `,${catalogEntry.form}` : ""}`,
      values,
      renderValues: {
        SpriteScaleEnemy: source?.values.SpriteScaleEnemy ?? 2,
        SpriteScalePlayer: source?.values.SpriteScalePlayer ?? 2,
      },
      originalValues: { ...values },
      dirty: false,
    };
  });
  return {
    installed: true,
    exists,
    path: EBDX_METRICS_PATH,
    originalText: String(text ?? ""),
    parsed,
    entries,
    dirty: false,
  };
}

export async function detectEbdx(ctx) {
  try {
    return await ctx.fs.projectExists(EBDX_PLUGIN_MARKER);
  } catch {
    return false;
  }
}

export async function loadEbdxWorkspace(ctx, documents) {
  if (!(await detectEbdx(ctx))) return null;
  let text = "";
  let exists = false;
  try {
    exists = await ctx.fs.projectExists(EBDX_METRICS_PATH);
    if (exists) text = await ctx.fs.readProjectFile(EBDX_METRICS_PATH);
  } catch (error) {
    throw new Error(`No se pudo leer ${EBDX_METRICS_PATH}: ${error?.message || error}`);
  }
  return buildEbdxWorkspace(text, documents, exists);
}

function formattedAssignment(field, value) {
  return `${field.padEnd(24, " ")}= ${Number(value)}`;
}

function replaceAssignment(line, field, value) {
  const pattern = new RegExp(`^(\\s*${field}\\s*=\\s*)([^#]*?)(\\s*(?:#.*)?)$`);
  const match = line.match(pattern);
  return match ? `${match[1]}${Number(value)}${match[3]}` : formattedAssignment(field, value);
}

export function serializeEbdxWorkspace(workspace) {
  const parsed = parseEbdxMetrics(workspace.originalText);
  const lines = [...parsed.lines];
  const existingChanges = [];
  const newEntries = [];

  for (const entry of workspace.entries.filter((item) => item.dirty)) {
    const record = parsed.byIdentity.get(entry.key);
    if (!record) {
      newEntries.push(entry);
      continue;
    }
    existingChanges.push({ entry, record });
  }

  existingChanges.sort((a, b) => b.record.startIndex - a.record.startIndex);
  for (const { entry, record } of existingChanges) {
    const missing = [];
    for (const field of POSITION_FIELDS) {
      const lineIndex = record.assignments.get(field);
      if (lineIndex === undefined) missing.push(formattedAssignment(field, entry.values[field]));
      else lines[lineIndex] = replaceAssignment(lines[lineIndex], field, entry.values[field]);
    }
    if (missing.length) lines.splice(record.rootEndIndex, 0, ...missing);
  }

  for (const entry of newEntries) {
    if (lines.length && lines.at(-1) !== "") lines.push("");
    lines.push("#-------------------------------", `[${entry.header}]`);
    for (const field of POSITION_FIELDS) lines.push(formattedAssignment(field, entry.values[field]));
  }
  return joinText(parsed, lines);
}

export function verifyEbdxSerialization(workspace, output) {
  const reparsed = parseEbdxMetrics(output);
  if (reparsed.issues.length) throw new Error(`La comprobación EBDX falló: ${reparsed.issues.join(" ")}`);
  for (const entry of workspace.entries.filter((item) => item.dirty)) {
    const record = reparsed.byIdentity.get(entry.key);
    if (!record) throw new Error(`La entrada EBDX [${entry.header}] desapareció al volver a leer el archivo.`);
    for (const field of POSITION_FIELDS) {
      if (record.values[field] !== Number(entry.values[field])) {
        throw new Error(`La métrica ${field} de [${entry.header}] no sobrevivió a la comprobación.`);
      }
    }
  }
  return reparsed;
}

export function setEbdxValue(workspace, entry, field, value) {
  if (!POSITION_FIELDS.includes(field)) throw new Error(`Métrica EBDX no editable: ${field}`);
  const next = Math.round(Number(value));
  if (!Number.isFinite(next) || entry.values[field] === next) return false;
  entry.values[field] = next;
  entry.dirty = POSITION_FIELDS.some((key) => entry.values[key] !== entry.originalValues[key]);
  workspace.dirty = workspace.entries.some((item) => item.dirty);
  return true;
}

export function ebdxBackupPath(path = EBDX_METRICS_PATH) {
  return path.replace(/\.txt$/i, ".maker-studio.bak");
}
