import assert from "node:assert/strict";
import { writePlansAtomically } from "../src/core/save_transaction.js";

function mockFs(initial, options = {}) {
  const files = new Map(Object.entries(initial));
  return {
    files,
    async writeProjectFile(path, value) {
      if (path === options.failWrite) throw new Error("write failed");
      files.set(path, options.corruptWrite === path && value.startsWith("new") ? `${value} corrupted` : value);
    },
    async readProjectFile(path) {
      if (path === options.failRead) throw new Error("read failed");
      return files.get(path);
    },
  };
}

const plans = [
  { path: "PBS/a.txt", backup: "PBS/a.bak", originalText: "old a", output: "new a" },
  { path: "PBS/b.txt", backup: "PBS/b.bak", originalText: "old b", output: "new b" },
];

{
  const fs = mockFs({ "PBS/a.txt": "old a", "PBS/b.txt": "old b" });
  await writePlansAtomically(fs, plans);
  assert.equal(fs.files.get("PBS/a.txt"), "new a");
  assert.equal(fs.files.get("PBS/b.txt"), "new b");
  assert.equal(fs.files.get("PBS/a.bak"), "old a");
}

{
  const fs = mockFs({ "PBS/a.txt": "old a", "PBS/b.txt": "old b" }, { failWrite: "PBS/b.txt" });
  await assert.rejects(writePlansAtomically(fs, plans), /write failed/);
  assert.equal(fs.files.get("PBS/a.txt"), "old a", "a failed multi-file write must roll back files already written");
  assert.equal(fs.files.get("PBS/b.txt"), "old b");
}

{
  const fs = mockFs({ "PBS/a.txt": "old a", "PBS/b.txt": "old b" }, { corruptWrite: "PBS/b.txt" });
  await assert.rejects(writePlansAtomically(fs, plans), /read-back verification/);
  assert.equal(fs.files.get("PBS/a.txt"), "old a", "a failed read-back check must roll back every written file");
  assert.equal(fs.files.get("PBS/b.txt"), "old b");
}

console.log("Atomic save and read-back rollback tests passed.");
