function snapshotEntries(entries) {
  return entries.map((entry) => ({ key: entry.key, values: { ...entry.values } }));
}

export function createEbdxHistoryController({ state, root, setMetric, onSaveStateChanged, onCatalogChanged, onRenderAll }) {
  const workspace = () => state.ebdx;
  const history = () => state.ebdxHistory;

  function refreshControls() {
    const undo = root.querySelector("#pepbs-ebdx-undo");
    const redo = root.querySelector("#pepbs-ebdx-redo");
    if (undo) undo.disabled = history().undo.length === 0;
    if (redo) redo.disabled = history().redo.length === 0;
  }

  function begin(entries, label) {
    if (!workspace() || history().transaction) return false;
    const unique = [...new Map(entries.map((entry) => [entry.key, entry])).values()];
    history().transaction = { label, keys: unique.map((entry) => entry.key), before: snapshotEntries(unique) };
    return true;
  }

  function cancel() {
    history().transaction = null;
  }

  function commit() {
    const transaction = history().transaction;
    if (!transaction || !workspace()) return false;
    history().transaction = null;
    const entries = transaction.keys.map((key) => workspace().entries.find((entry) => entry.key === key)).filter(Boolean);
    const after = snapshotEntries(entries);
    if (JSON.stringify(transaction.before) === JSON.stringify(after)) {
      refreshControls();
      return false;
    }
    history().undo.push({ label: transaction.label, before: transaction.before, after });
    if (history().undo.length > 100) history().undo.shift();
    history().redo = [];
    refreshControls();
    return true;
  }

  function applySnapshot(snapshot) {
    for (const saved of snapshot) {
      const entry = workspace().entries.find((candidate) => candidate.key === saved.key);
      if (!entry) continue;
      entry.values = { ...saved.values };
      entry.dirty = Object.keys(entry.originalValues).some((field) => entry.values[field] !== entry.originalValues[field]);
    }
    workspace().dirty = workspace().entries.some((entry) => entry.dirty);
  }

  function undo() {
    commit();
    const command = history().undo.pop();
    if (!command) { refreshControls(); return false; }
    applySnapshot(command.before);
    history().redo.push(command);
    refreshControls();
    onRenderAll();
    return true;
  }

  function redo() {
    commit();
    const command = history().redo.pop();
    if (!command) { refreshControls(); return false; }
    applySnapshot(command.after);
    history().undo.push(command);
    refreshControls();
    onRenderAll();
    return true;
  }

  function changeValue(entry, field, value, label) {
    const implicitTransaction = !history().transaction;
    if (implicitTransaction) begin([entry], label);
    const wasDirty = entry.dirty;
    if (!setMetric(workspace(), entry, field, value)) {
      if (implicitTransaction) cancel();
      return false;
    }
    onSaveStateChanged();
    if (wasDirty !== entry.dirty) onCatalogChanged();
    if (implicitTransaction) commit();
    return true;
  }

  function resetEntry(entry, label) {
    begin([entry], label);
    for (const field of Object.keys(entry.originalValues)) entry.values[field] = entry.originalValues[field];
    entry.dirty = false;
    workspace().dirty = workspace().entries.some((item) => item.dirty);
    commit();
    onRenderAll();
  }

  return { begin, cancel, changeValue, commit, redo, resetEntry, undo };
}
