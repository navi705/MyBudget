# Goal: fix and optimise synchronisation

## Objective

Make both synchronisation paths — P2P file sync (`lib/core/sync/sync_service_io.dart`,
Syncthing folder) and server sync (`lib/core/services/server_sync_service.dart` +
`my_budget_server`) — provably correct and cheap enough to run on a real budget
(hundreds of thousands of exchange-rate rows), without changing a single line of UI.

"Done" is not "it looked fine when I clicked around". Done is: every invariant below is
pinned by an automated test, and the whole suite of both packages is green.

## Scope

In scope:

- `my_budget_client/lib/core/sync/**` (P2P engine, binary format, record keys)
- `my_budget_client/lib/core/services/server_sync_service.dart`, `startup_sync_service.dart`
- `my_budget_client/lib/core/database/**` only where sync depends on it
  (`sync_log`, `sync_push_queue`, DAO queries the sync paths call, indexes)
- `my_budget_server/lib/**`, `my_budget_server/routes/**`
- tests in both packages

Out of scope (do not touch):

- `my_budget_client/lib/presentation/**` — no screens, widgets, providers or l10n strings,
  including `sync_settings_screen.dart`. If a fix needs a different value on screen, change
  what the service returns, not what the screen draws.
- feature work of any kind: no new sync features, no new settings, no protocol redesign

## Correctness invariants (each must end up with a test)

1. **Convergence.** Two devices that exchange every packet in any order, with any number of
   duplicate deliveries, end with byte-identical rows for every synced table.
2. **Deterministic conflict resolution.** Last-write-wins by `modifiedAt`; ties broken by a
   stable rule (device id), never by arrival order — so both sides pick the same winner.
3. **Deletes stay deleted.** A tombstone always beats an older write; a device that has been
   cleared does not resurrect rows or refill itself from a peer that still holds them.
4. **Replay is idempotent.** Applying the same packet or the same pull page twice changes
   nothing — no duplicated rows, no doubled balances, no queue entries left behind.
5. **No silent data loss.** A push that is not acknowledged 200 leaves its queue entries
   intact; an edit made while a push is in flight is never drained as if it had been sent.
6. **Atomic batches.** A pull page applies all-or-nothing, and the pull cursor only advances
   past a page that committed.
7. **Device-local data never leaves the device.** `local_device_id`, `sync_folder_path`,
   `server_sync_*` (token included) are never uploaded and never overwritten by a peer.
8. **Derived values are recomputed, not trusted.** Account balances are rebuilt from the
   merged transaction set on both paths; the accounts a transaction left are rebuilt too.
9. **Malformed input fails closed.** A truncated, corrupt, or hostile packet is rejected and
   quarantined without writing a partial state and without killing the sync loop.
10. **Money and dates survive the round trip.** Minor units, currency pairs, rate presets and
    day-granularity keys come back exactly as they went out, in every locale.

## Performance targets (measured, not guessed)

Baseline is captured first, on the same data, and written into this file before any change.

- Work per synced row is **O(1) statements**: applying a page of N rows must not issue N
  queries per table (bulk upserts / batched writes), and neither must exporting one.
- Push and pull are **bounded in memory**: nothing loads a whole table into a list to sync it;
  page sizes are explicit and every loop has a termination proof.
- Every hot predicate the sync paths use is **index-covered** — verified with `EXPLAIN QUERY
  PLAN` in a test, not by eye. No `SCAN` on `transactions`, `exchange_rates`,
  `sync_push_queue` or `sync_log` in the sync queries.
- **No redundant round trips**: a sync with nothing pending issues no push request and one
  pull request at most; a sync that pushes does not re-pull its own echo.
- Numeric targets (filled in after the baseline run): full pull of the seeded budget, apply
  time per 20 000-row page, idle-sync wall time. Each must not regress; the ones the baseline
  shows as pathological must improve by the factor stated there.

## Verification — the only definition of green

Run from the repository root; all four must pass, on Windows, with no skipped sync tests:

```
cd my_budget_client && flutter analyze
cd my_budget_client && flutter test
cd my_budget_server && dart analyze
cd my_budget_server && dart test
```

Plus:

- every invariant above maps to at least one named test; a fix without a test that fails
  before it and passes after it does not count as done
- no existing test is deleted, weakened or marked skip to make the suite green
- the client suite's sync files (`test/core/sync/**`, `test/core/database/sync_*`,
  `test/core/services/server_sync_*`) and the server's (`test/data/sync_repository_test.dart`,
  `test/ws/sync_controller_test.dart`, `test/routes/api/sync/**`) all run in the same pass

## Constraints

- Wire protocol stays backward compatible: an old client must keep syncing against a new
  server, and vice versa. Any format change is versioned and both branches are tested.
- No new runtime dependencies in either package.
- Schema changes only additive, with a migration and a migration test.
- Behaviour visible to the user changes only where it was a bug; anything else is refactoring
  and must leave observable output identical.

## Working order

1. Capture the baseline: full test run of both packages, and timings of pull/push/apply.
2. Write the failing tests for the invariants that are currently violated.
3. Fix, smallest change first, correctness before speed.
4. Optimise against the measured baseline; re-measure and record the numbers here.
5. Final gate: the four commands above, green.

## Baseline — 2026-08-21, commit 1763f6d

- `my_budget_server`: `dart test` — 82 passed, 0 failed.
- `my_budget_client`: `flutter test` — 1421 passed, 1 failed.
  - The failure is `test/presentation/widgets/data_tab_localisation_test.dart`,
    "the account delete confirmation is readable in ru". It passes when the file is run on its
    own, so it is cross-suite state leaking in the full run, not a sync defect. It is
    pre-existing and blocks the "green" gate, so it is fixed as part of this work — without
    touching `lib/presentation/**`.
- Sync timings: not yet measured.

## Progress — 2026-08-21

### Landed

Round 1 (server + schema + test hygiene):

- **F7 / F25** — a pull page no longer re-sends untruncated tables: `getChanges` computes
  `nextCursor` first, then trims every table's slice to it.
- **F26 (server half)** — an absent JSON key is now omitted from the INSERT columns, the params
  and the `SET` list, so a sender that does not carry a column cannot erase it.
- **F11** — `api_settings.is_deleted` exists on the server, so a deleted provider stays deleted.
- **F12 (server half)** — a zone-less date string binds as wall clock instead of shifting by the
  server's UTC offset.
- **Server LWW** — `_lastWriteWins` now breaks a `modified_at` tie on `device_id`, the same rule
  the client adopted in round 1b.
- **F6 / F9** — `idx_<table>_push_key` expression indexes, schema v13 → v14 with a migration and a
  migration test; `EXPLAIN QUERY PLAN` is pinned by `test/core/database/sync_index_plan_test.dart`
  so a future edit that reintroduces a `SCAN` fails a test.

Round 1b (P2P engine + the client half of server sync):

- **F1** — the LWW tie is broken by `(modifiedAt, deviceId)` on both peers, so two devices that
  edit in the same millisecond converge instead of diverging permanently.
- **F2** — `sync_processed_files` markers are pruned by whether the packet they name is still in
  the folder, not by a 7-day clock; the folder no longer replays itself weekly. Name-based skips
  were also hoisted above `readAsBytes`/gunzip/decode, so a rescan is one indexed read per file.
- **F3 / F13** — a packet applies inside one transaction with per-change error isolation:
  all-or-nothing overall, and one unconvertible change costs only itself.
- **F28 / F29** — an out-of-range enum index and a zero-length payload are skipped rather than
  thrown, so a peer on a newer build cannot kill a packet.
- **F17** — the P2P importer recomputes account balances instead of trusting the peer's scalar;
  `openingBalance` now travels on the wire (additive, absent-tolerant).
- **F18** — imports are serialised through one chain, so two packets cannot interleave around the
  connection-global `PRAGMA foreign_keys`.
- **F4** — `sync()`'s re-entrancy guard latches synchronously, before the first `await`.
- **F5 / F10** — a pull no longer bounces its own page back: the queue rows the pull's own
  transaction created are deleted by id inside that transaction.
- **F8** — a pulled page applies in chunked multi-row upserts (5 000 rows: 41 statements, not
  5 000) with the LWW predicate and the per-payload `SET` list preserved byte-for-byte.
- **F20** — reconnect backoff resets only after the connection has stayed up for 30 s.
- **F34** — a rate below 5e-9 is no longer rounded to exactly zero.

### Gate status

- `my_budget_server`: `dart analyze` — 0 errors, 0 warnings (103 style infos, all pre-existing).
  `dart test` — 110 passed, 0 failed.
- `my_budget_client`: full run pending; the toolchain is held by the UI critique's render pass.

### Still open

- **F35** — the `trg_push_queue_<table>_update` triggers carry
  `WHEN NEW.modified_at IS NOT OLD.modified_at`, so a row edited in the millisecond it was last
  written is never queued for push. Now unblocked: F5's echo suppression has landed, so the
  trigger can be made unconditional without the pull re-uploading its own page.
- Order-dependent test `test/data/local_inflation_repository_test.dart:628`.
- The `data_tab_localisation_test.dart` ru flake: not reproducible in six full runs, still
  recorded here because it blocks the green gate when it does fire.
- Sync timings: still not measured end-to-end.
