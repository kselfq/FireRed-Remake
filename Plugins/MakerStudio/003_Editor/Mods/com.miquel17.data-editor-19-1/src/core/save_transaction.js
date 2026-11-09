export async function writePlansAtomically(fs, plans) {
  for (const plan of plans) await fs.writeProjectFile(plan.backup, plan.originalText);

  const written = [];
  try {
    for (const plan of plans) {
      await fs.writeProjectFile(plan.path, plan.output);
      written.push(plan);
    }
    for (const plan of plans) {
      const actual = await fs.readProjectFile(plan.path);
      if (actual !== plan.output) throw new Error(`${plan.path} failed read-back verification.`);
    }
  } catch (error) {
    const rollbackFailures = [];
    for (const plan of written.reverse()) {
      try {
        await fs.writeProjectFile(plan.path, plan.originalText);
      } catch (rollbackError) {
        rollbackFailures.push(`${plan.path}: ${rollbackError?.message || rollbackError}`);
      }
    }
    if (rollbackFailures.length) {
      const transactionError = new Error(`The save failed and rollback was incomplete. Backups are available. ${rollbackFailures.join(" ")}`);
      transactionError.partialSave = true;
      transactionError.cause = error;
      throw transactionError;
    }
    throw error;
  }
}
