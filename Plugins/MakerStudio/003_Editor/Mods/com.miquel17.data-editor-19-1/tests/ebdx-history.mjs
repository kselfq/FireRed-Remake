import assert from "node:assert/strict";
import { createEbdxHistoryController } from "../src/ebdx/history_controller.js";

const entry = {
  key: "BULBASAUR",
  values: { BattlerEnemyX: "0", BattlerEnemyY: "0" },
  originalValues: { BattlerEnemyX: "0", BattlerEnemyY: "0" },
  dirty: false,
};
const state = {
  ebdx: { entries: [entry], dirty: false },
  ebdxHistory: { undo: [], redo: [], transaction: null },
};
const callbacks = { save: 0, catalog: 0, render: 0 };
const root = { querySelector: () => null };

function setMetric(workspace, target, field, value) {
  if (!workspace || target.values[field] === String(value)) return false;
  target.values[field] = String(value);
  target.dirty = Object.keys(target.originalValues).some((key) => target.values[key] !== target.originalValues[key]);
  workspace.dirty = workspace.entries.some((item) => item.dirty);
  return true;
}

const history = createEbdxHistoryController({
  state,
  root,
  setMetric,
  onSaveStateChanged: () => { callbacks.save += 1; },
  onCatalogChanged: () => { callbacks.catalog += 1; },
  onRenderAll: () => { callbacks.render += 1; },
});

assert.equal(history.changeValue(entry, "BattlerEnemyX", 12, "Adjust EBDX position"), true);
assert.equal(entry.values.BattlerEnemyX, "12");
assert.equal(entry.dirty, true);
assert.equal(state.ebdxHistory.undo.length, 1);
assert.equal(callbacks.save, 1);
assert.equal(callbacks.catalog, 1);

assert.equal(history.undo(), true);
assert.equal(entry.values.BattlerEnemyX, "0");
assert.equal(entry.dirty, false);
assert.equal(state.ebdxHistory.redo.length, 1);
assert.equal(callbacks.render, 1);

assert.equal(history.redo(), true);
assert.equal(entry.values.BattlerEnemyX, "12");
assert.equal(entry.dirty, true);

history.resetEntry(entry, "Restore EBDX position");
assert.equal(entry.values.BattlerEnemyX, "0");
assert.equal(entry.dirty, false);
assert.equal(state.ebdx.dirty, false);

console.log(JSON.stringify({ ebdxHistory: "ok" }, null, 2));
