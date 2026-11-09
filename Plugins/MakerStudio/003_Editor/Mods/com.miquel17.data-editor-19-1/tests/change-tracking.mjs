import assert from "node:assert/strict";
import {
  captureEntryBeforeDeletion,
  collectDocumentChanges,
  initializeDocumentTracking,
  refreshDocumentDirty,
  restoreAllDocumentChanges,
  restoreDocumentChange,
  trackNewEntry,
} from "../src/core/change_tracking.js";
import { removeDocumentEntry } from "../src/core/document_ops.js";

const saved = { kind: "moves", key: "1", idNumber: 1, lineIndex: 3, values: { IdNumber: "1", InternalName: "TACKLE", Name: "Tackle", Power: "40" }, dirty: false };
const document = { kind: "moves", entries: [saved], deletedEntries: [], dirty: false };
const documents = { moves: document };

initializeDocumentTracking(documents);
saved.values.Power = "50";
refreshDocumentDirty(document);
let changes = collectDocumentChanges(documents);
assert.equal(changes.length, 1);
assert.deepEqual(changes[0].fields, ["Power"]);
restoreDocumentChange(changes[0]);
assert.equal(saved.values.Power, "40");
assert.equal(document.dirty, false);

const created = { kind: "moves", key: "2", idNumber: 2, lineIndex: null, values: { IdNumber: "2", InternalName: "NEW_MOVE", Name: "New move" }, dirty: true, isNew: true };
document.entries.push(created);
trackNewEntry(document, created);
changes = collectDocumentChanges(documents);
assert.equal(changes[0].status, "created");
restoreDocumentChange(changes[0]);
assert.equal(document.entries.includes(created), false);

saved.values.Name = "Edited tackle";
refreshDocumentDirty(document);
captureEntryBeforeDeletion(saved);
removeDocumentEntry(document, saved);
changes = collectDocumentChanges(documents);
assert.equal(changes[0].status, "deleted");
restoreDocumentChange(changes[0]);
assert.equal(document.entries.includes(saved), true);
assert.equal(saved.values.Name, "Edited tackle");
assert.equal(saved.dirty, true);

restoreDocumentChange(collectDocumentChanges(documents)[0]);
assert.equal(saved.values.Name, "Tackle");
assert.equal(document.dirty, false);

saved.values.Name = "Edited and deleted";
refreshDocumentDirty(document);
captureEntryBeforeDeletion(saved);
removeDocumentEntry(document, saved);
restoreAllDocumentChanges(documents);
assert.equal(document.entries.includes(saved), true, "discarding all must restore a deleted entry");
assert.equal(saved.values.Name, "Tackle", "discarding all must restore the last saved value, not the value immediately before deletion");
assert.equal(document.deletedEntries.length, 0);
assert.equal(document.dirty, false);

console.log(JSON.stringify({ changeTracking: "ok" }, null, 2));
