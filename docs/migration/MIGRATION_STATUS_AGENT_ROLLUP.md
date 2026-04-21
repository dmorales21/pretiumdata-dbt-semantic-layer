# Migration status — agent rollup (index)

**Owner:** Alex  
**Status:** **index** — there is no separate frozen “rollup” file; status is distributed by design.

## Where to read status

| Need | Document |
|------|----------|
| **Task IDs (`T-*`) and backlog** | [MIGRATION_TASKS.md](./MIGRATION_TASKS.md) |
| **Short batch audit rows** | [MIGRATION_LOG.md](./MIGRATION_LOG.md) |
| **Verbose evidence + artifacts** | [MIGRATION_BATCH_INDEX.md](./MIGRATION_BATCH_INDEX.md) |
| **Layer-2 FEATURE priorities** | [MIGRATION_LAYER2_EXECUTION_TRACKER.md](./MIGRATION_LAYER2_EXECUTION_TRACKER.md) |
| **“Done” definition** | [CANONICAL_COMPLETION_DEFINITION.md](./CANONICAL_COMPLETION_DEFINITION.md) |

Agents should **append** to `MIGRATION_LOG.md` / `MIGRATION_BATCH_INDEX.md` instead of maintaining a duplicate rollup here.
