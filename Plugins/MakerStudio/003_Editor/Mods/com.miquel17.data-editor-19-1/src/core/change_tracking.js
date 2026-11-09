let changeSequence = 0;

function clone(value) {
  return value == null ? value : JSON.parse(JSON.stringify(value));
}

export function snapshotEntry(entry) {
  const snapshot = {
    values: clone(entry.values ?? {}),
    key: entry.key,
  };
  for (const property of ["pokemon", "idNumber", "species", "form"]) {
    if (Object.prototype.hasOwnProperty.call(entry, property)) snapshot[property] = clone(entry[property]);
  }
  return snapshot;
}

function restoreSnapshot(entry, snapshot) {
  entry.values = clone(snapshot.values ?? {});
  entry.key = snapshot.key;
  for (const property of ["pokemon", "idNumber", "species", "form"]) {
    if (Object.prototype.hasOwnProperty.call(snapshot, property)) entry[property] = clone(snapshot[property]);
    else delete entry[property];
  }
  delete entry.renamedFrom;
  delete entry.renamedIdentity;
}

function same(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

export function changedEntryFields(entry) {
  const saved = entry._savedSnapshot;
  if (!saved || entry.isNew) return [];
  const fields = [];
  const keys = new Set([...Object.keys(saved.values ?? {}), ...Object.keys(entry.values ?? {})]);
  for (const key of keys) {
    if (!same(saved.values?.[key] ?? "", entry.values?.[key] ?? "")) fields.push(key);
  }
  if (!same(saved.pokemon ?? [], entry.pokemon ?? [])) fields.push("pokemon");
  return fields;
}

export function refreshDocumentDirty(document) {
  for (const entry of document.entries) {
    entry.dirty = Boolean(entry.isNew || changedEntryFields(entry).length);
  }
  document.dirty = document.entries.some((entry) => entry.dirty)
    || Boolean(document.deletedEntries?.length);
  return document.dirty;
}

export function refreshDocumentsDirty(documents) {
  for (const document of Object.values(documents ?? {})) refreshDocumentDirty(document);
}

function identifyEntry(entry, kind, order, saved) {
  entry._changeId ||= `${kind}:${saved ? "saved" : "new"}:${++changeSequence}`;
  entry._savedOrder ??= order;
  if (saved) entry._savedSnapshot = snapshotEntry(entry);
}

export function initializeDocumentTracking(documents) {
  changeSequence = 0;
  for (const [kind, document] of Object.entries(documents ?? {})) {
    document.deletedEntries ||= [];
    document.entries.forEach((entry, order) => identifyEntry(entry, kind, order, true));
    refreshDocumentDirty(document);
  }
}

export function trackNewEntry(document, entry) {
  identifyEntry(entry, document.kind, Number.MAX_SAFE_INTEGER, false);
  entry.dirty = true;
  document.dirty = true;
  return entry;
}

export function captureEntryBeforeDeletion(entry) {
  entry._beforeDeletionSnapshot = snapshotEntry(entry);
}

export function collectDocumentChanges(documents) {
  const changes = [];
  for (const [kind, document] of Object.entries(documents ?? {})) {
    for (const entry of document.entries) {
      if (!entry.dirty) continue;
      changes.push({ kind, document, entry, status: entry.isNew ? "created" : "modified", fields: changedEntryFields(entry) });
    }
    for (const entry of document.deletedEntries ?? []) {
      changes.push({ kind, document, entry, status: "deleted", fields: [] });
    }
  }
  return changes;
}

export function restoreDocumentChange(change) {
  const { document, entry, status } = change;
  if (status === "created") {
    const index = document.entries.indexOf(entry);
    if (index >= 0) document.entries.splice(index, 1);
  } else if (status === "deleted") {
    const deletedIndex = document.deletedEntries?.indexOf(entry) ?? -1;
    if (deletedIndex >= 0) document.deletedEntries.splice(deletedIndex, 1);
    restoreSnapshot(entry, entry._beforeDeletionSnapshot ?? entry._savedSnapshot);
    delete entry._beforeDeletionSnapshot;
    if (!document.entries.includes(entry)) document.entries.push(entry);
    document.entries.sort((left, right) => (left._savedOrder ?? Number.MAX_SAFE_INTEGER) - (right._savedOrder ?? Number.MAX_SAFE_INTEGER));
  } else if (entry._savedSnapshot) {
    restoreSnapshot(entry, entry._savedSnapshot);
  }
  refreshDocumentDirty(document);
}

export function restoreAllDocumentChanges(documents) {
  for (const document of Object.values(documents ?? {})) {
    const savedEntries = document.entries.filter((entry) => !entry.isNew);
    for (const entry of document.deletedEntries ?? []) {
      if (!entry.isNew && !savedEntries.includes(entry)) savedEntries.push(entry);
    }
    for (const entry of savedEntries) {
      if (entry._savedSnapshot) restoreSnapshot(entry, entry._savedSnapshot);
      delete entry._beforeDeletionSnapshot;
      entry.dirty = false;
    }
    document.entries = savedEntries.sort((left, right) => (left._savedOrder ?? Number.MAX_SAFE_INTEGER) - (right._savedOrder ?? Number.MAX_SAFE_INTEGER));
    document.deletedEntries = [];
    refreshDocumentDirty(document);
  }
}
