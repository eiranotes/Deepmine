# DeepMine Persistence Migration

## Ownership and location

- The product store is `DeepMine.store` inside App Group `group.com.eiraworks.deepmine`.
- `GameRepository` in the app process is the only production SwiftData writer.
- Extensions may read product state and append file-backed commands, but must not open a write transaction against the product store. The retained P0 probe write remains diagnostic-only and is not part of product state.
- Tests use an in-memory container or a temporary-directory store and never touch the App Group.

## Schema v1 — current

Every model carries `schemaVersion = 1`; the repository accepts exactly the current version and fails closed for every unsupported value.

| Model | Persisted responsibility |
| --- | --- |
| `PlayerStateEntity` | Resources, focus totals, session/depth progress, bore history, per-run equipment modifications, streak summary, world unlocks, selected theme, vein state, prestige, permanent levels, onboarding/demo receipts, permission outcomes, last expedition choice, and idempotency sets |
| `EquipmentStateEntity` | Drill, cart, and lamp levels |
| `SessionRecordEntity` | Ordered session history and completion outcomes |
| `DailyRecordEntity` | Ordered daily focus, goal, streak, rest-day, and finalization history |
| `PurchaseStateEntity` | Applied equipment and permanent-upgrade purchase command IDs |

The repository reconstructs a complete `DeepMineCore.PlayerState`; derived values such as current depth and region remain Core-owned calculations.

The unreleased v1 schema now includes onboarding stage, demo timestamps and receipt IDs, three neutral permission outcomes, last plan/duration, daily goal and streak records, run/lifetime focus, regions/themes/decorations, vein miss/effect state, prestige and permanent upgrades, active session origin command IDs, the selected per-run equipment modifications, the encoded `BoreRecord` history, and a persisted return report. Both new data fields default to empty data and decode legacy saves as `.empty`/`[]`. Required attributes carry explicit defaults while optional timestamps and receipts remain absent. This is a pre-release schema consolidation, not a substitute for the versioned migration procedure required after release. Full-state round-trip, temporary-store reopen, defaults, unsupported-version, corruption, session, and return-report tests cover it.

## Cross-process command queue

Extensions never mutate `DeepMine.store`. The shared-target `GameCommandEnqueuer` depends only on Foundation, `DeepMineCore`, and the existing process lock; extensions encode a Core `GameCommand` and call that enqueue boundary only. The foreground app drains pending commands whenever its scene becomes active. The App Group files are:

- `GameCommands.jsonl` — pending command envelopes.
- `GameCommands.lock` — the existing process-wide `flock` owner for every queue read/write/drain.
- `AppliedCommands.json` — bounded pending/applying/applied state mirrored for diagnostics and cross-process visibility.
- `GameCommands.quarantine.jsonl` — malformed lines plus a bounded reason/timestamp record.

The app drains valid lines independently, so one malformed line is quarantined without blocking later commands. Equipment, permanent-upgrade, and prestige commands are applied by the app repository. Start and abandon commands are delegated to the app-owned `GameStore`. A start command that loses a race with an already active session is recorded as a resolved conflict rather than retried forever; a matching origin command is idempotent. Abandon without an active session records its receipt without creating a new session. `open` is intentionally not a repository mutation and remains a navigation/open-app concern.

For every repository command, the app writes the mutated `PlayerState` and command ID into `PurchaseStateEntity.appliedGameCommandIDsData` in one SwiftData `ModelContext.save()`. That SwiftData receipt is authoritative. The JSON receipt moves to `applying` before the transaction and `applied` afterward. If the process stops after the repository commit but before JSON update or queue compaction, replay finds the SwiftData ID, performs no second mutation, marks the mirror applied, and removes the pending line.

Queue, receipt, and quarantine retention preserve at most the most recent 500 records; JSONL files are additionally capped at 256KB. This bounds App Group growth while keeping the newest extension intent. Cross-process behavior is simulator-tested through the same filesystem contract; real Widget/App process scheduling remains a physical-device release gate.

UI fixtures set an isolated store ID and deterministic coordinator. They do not drain the product App Group queue, so a command from an extension or another test run cannot alter a screenshot or show a false recovery warning.

The quarantine file is synced before malformed source lines are removed from the pending file; replay deduplicates an already quarantined raw line. `AppliedCommands.json` is not authoritative: if it is malformed, it moves to `CorruptCommandReceipts/AppliedCommands-<uuid>.json`, then the app rebuilds current receipt state while consulting the SwiftData command IDs during drain.

The retained `ProbeShared.store` and `WriteProbeRecordIntent` belong only to the P0 diagnostic harness. They do not contain product state and are not the production extension-write path; all product commands use `GameCommandEnqueuer` and are applied to `DeepMine.store` only by the foreground app.

## Future schema procedure

1. Add the next explicit model version without editing the v1 model definition in place.
2. Define a `VersionedSchema` and a `SchemaMigrationPlan` with a tested v1-to-next stage.
3. Transform every field explicitly, including enum raw values, ordered history, and idempotency sets. Do not silently default data that existed in the previous version.
4. Bump `GameRepository.currentSchemaVersion` only after migration fixtures pass both forward migration and full `PlayerState` round-trip tests.
5. Keep unknown newer versions fail-closed: do not delete, quarantine, or rewrite a store solely because its `schemaVersion` is unsupported.
6. Record the schema change, rollback limit, and release verification evidence in this document.

## Corruption recovery

Opening the repository includes a real fetch of the complete v1 graph. If container creation or that initial load fails for a reason other than an unsupported schema version:

1. Close the failed open attempt.
2. Create `CorruptStores/<timestamp>/` next to `DeepMine.store`.
3. Move `DeepMine.store`, `DeepMine.store-wal`, and `DeepMine.store-shm` together when present. If any move fails, already moved files are returned to their original locations.
4. Create a fresh v1 store and persist `PlayerState()` defaults.
5. Expose `GameRecoveryNotice`; the app presents a Korean recovery alert on launch.

The quarantined source is never overwritten or automatically deleted. Unsupported schema versions bypass this recovery path so a newer valid store cannot be mistaken for corruption.
