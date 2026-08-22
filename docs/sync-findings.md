# Sync audit findings (2026-08-21, commit 1763f6d)

Produced by a six-dimension audit against docs/sync-goal.md, top findings adversarially verified.

## F1. LWW tie on modifiedAt is resolved as "local wins", so two devices pick different winners and never converge

- status: CONFIRMED (adversarially verified)
- severity: high (verifier: high)
- kind: correctness | invariant: 2 (and 1)
- site: `my_budget_client/lib/core/sync/sync_service_io.dart:611`

**Failure scenario.** Style s1 exists on both devices. A edits it to 'A-name' stamping modified_at=3000; B edits the same row to 'B-name' also stamping modified_at=3000 (identical stamps are not exotic: _logChanges/batchUpdateBalances/clearAllData stamp one DateTime.now() for a whole batch, and two devices restoring the same backup or applying the same bulk import land on the same millisecond). A exports, B imports: 3000 > 3000 is false, so B keeps 'B-name'. B exports, A imports: A keeps 'A-name'. Both rows now carry modified_at=3000, so no later packet can ever break the tie - the two devices are permanently divergent for that row. The delete branches are asymmetric the same way: A deletes X at t=3000 (line 543 `deleteTimestamp > localModifiedAt` fails on B, row stays alive) while on A the incoming upsert loses at line 593 (`deletedAt >= incomingModifiedAt`), so A holds a tombstone and B holds a live row forever.

**Evidence.** line 611: `} else if (incomingModifiedAt > localModifiedAt) {` ... else `// Local is newer - save incoming to conflict history`; line 543: `if (deleteTimestamp > localModifiedAt) {`; line 593: `if (deletedAt != null && deletedAt >= incomingModifiedAt) {`. Nothing anywhere in _applyChange reads a device id for ordering - `fromDevice` is only ever passed to conflictHistoryDao.saveConflict.

**Fix sketch.** Make the comparison a lexicographic (modifiedAt, deviceId) ordering that is symmetric on both sides: on equal modifiedAt the change whose originating device id is greater wins, where the incoming id is `change.data['deviceId'] ?? fromDevice` and the local id is `localData['deviceId'] ?? _localDeviceId`. Apply the same rule in all three branches (611, 543, 593) so an upsert/delete tie resolves identically on both peers. Note the existing 'equal modifiedAt is deterministic' test in test/core/sync/sync_service_lww_test.dart still passes under 'higher device id wins' because it exports device-a -> device-b.

**Test sketch.** In sync_service_lww_test.dart add `syncBToA()` (mirror of syncAToB) and a test: insertStyleOnA('s1','A-name',3000); insertStyleOnB('s1','B-name',3000); syncAToB(); syncBToA(); expect(styleOnA('s1').name, styleOnB('s1').name) and the same for modifiedAt. Fails today (A='A-name', B='B-name'), passes after the device-id tiebreak.

**Verifier note.** Confirmed, and reachable more strongly than claimed. sync_service_io.dart:611 is `else if (incomingModifiedAt > localModifiedAt)` and the tie falls into the else at 623-633 ("local wins"), with no device-id tiebreak anywhere on the path (grep over lib/core/sync/** shows `fromDevice` only reaching conflictHistoryDao.saveConflict at 602/632). docs/sync-goal.md:35-36 (invariant 2) explicitly requires the tie be broken by device id so both sides pick the same winner.

The claim's tie sources (same-millisecond edits, shared batch stamps) are weak, but the seed makes ties deterministic: lib/data/seed_data/categories_data.dart:206,213,220,... seeds every default category with `modifiedAt: const Value(1)`, and account_types_data.dart:9,15,... does the same. Ids are locale-independent (`id: const Value('cat_groceries')`) but names are not - _seedCategories (app_database.dart:4512-4517) calls getDefaultCategories(Intl.systemLocale...), and categoryTranslations names cat_groceries "Groceries" under en and "Продукты" under ru. insertAllCategories (app_database.dart:880-902) only overwrites modifiedAt when absent or 0 (line 887), so the 1 survives, and line 902 calls _logChanges(ids,'upsert') so the seeded rows ARE exported. _categoryToJson (sync_service_io.dart:1723-1733) ships the row's own modifiedAt=1.

Concrete path: install on a ru phone and an en laptop sharing one Syncthing folder. Both seed cat_groceries with modified_at=1 and log an upsert. Laptop exports -> phone imports -> 1 > 1 false -> phone keeps "Продукты". Phone exports -> laptop keeps "Groceries". Both rows remain at modified_at=1, so no later packet can break the tie: permanent divergence for all 16 seeded categories on the first sync, no clock coincidence needed. Same for two app versions whose seed renamed a category.

The existing test test/core/sync/sync_service_lww_test.dart:178 ("equal modifiedAt is deterministic: local wins, incoming is rejected") pins the defective behaviour, not the correct one - it only runs A->B and never checks B->A picks the same winner, so it is not the guard a refutation would need.

The secondary delete asymmetry (line 543 `deleteTimestamp > localModifiedAt`, strict, vs line 593 `deletedAt >= incomingModifiedAt`, non-strict) is genuinely asymmetric on a tie, but delete stamps come from sync_log.timestamp (DateTime.now(), line 316), so it needs an exact-millisecond coincidence and is a secondary aggravation of the same missing rule rather than independently likely.

## F2. Processed-file markers are pruned after 7 days while the .sync files are kept forever, so every packet is re-imported on a 7-day cycle

- status: CONFIRMED (adversarially verified)
- severity: high (verifier: high)
- kind: correctness | invariant: 4 (and 3)
- site: `my_budget_client/lib/core/sync/sync_service_io.dart:660`

**Failure scenario.** _processFile deliberately leaves imported files in the sync folder (comment at 491-497: 'We no longer move to .processed... markProcessed is enough to skip it'), and _cleanupProcessedFiles only ever lists the .processed subfolder - which nothing writes to - yet still calls clearOldProcessed(now - 7 days) on the DB. Concretely: on day 0 B imports A's packet containing exchange rate USD_EUR_2024-01-01_1 and marks the file processed. On day 3 the user deletes that rate; the delete reaches B and, because exchange_rates has no isDeleted column, _softDeleteRecord issues a real DELETE and leaves no tombstone. On day 8 the app starts, _processExistingFiles runs, and A's day-0 file is still on disk with its marker already pruned by the previous run, so isProcessed returns false and the whole packet is applied again - the deleted rate is re-inserted. The file is then re-marked with a fresh processedAt, pruned 7 days later, and re-imported again: the deleted rate comes back roughly every week, forever, on every device. The same cycle re-decodes and re-applies the entire folder history on each app start (O(all packets ever received) per scan), and each re-applied change that loses LWW writes another conflict_history row.

**Evidence.** line 38 `Duration keepProcessedFor = const Duration(days: 7);`; lines 643-660 `final processedDir = Directory(p.join(_syncFolderPath!, '.processed')); if (!await processedDir.exists()) return; ... await _db.syncProcessedFilesDao.clearOldProcessed(cutoff);` - the row cleanup is tied to a directory that is never populated; lines 452-465 read and gunzip/decode the file before the isProcessed check, so the re-scan cost is paid in full even for files that are still marked.

**Fix sketch.** Only prune a sync_processed_files row when the file it names is actually gone from the sync folder (or delete/move the .sync file at the same time the row is pruned, which is what the .processed folder was for). Also hoist the `isProcessed(fileName)` check above `file.readAsBytes()` so a re-scan of a large folder costs one indexed lookup per file instead of a full gunzip + JSON decode.

**Test sketch.** Test 'an already-processed file is not re-imported after the processed row is pruned': import a packet that inserts exchange rate X, delete X locally, set the sync_processed_files row's processed_at to 8 days ago (or set service.keepProcessedFor = Duration.zero), call importNow() twice, and assert X is still absent. Fails today (X is resurrected).

**Verifier note.** Confirmed and reachable. startSync creates the .processed folder (sync_service_io.dart:126-129), so the `if (!await processedDir.exists()) return;` guard at line 645 does NOT short-circuit — the claim's evidence framed this backwards, but that is precisely what keeps the bug live: _cleanupProcessedFiles deletes zero files (nothing ever writes into .processed; the only refs are its creation at line 127 and its listing at line 644) yet still runs clearOldProcessed(now-7d) at line 660, a plain `DELETE FROM sync_processed_files WHERE processed_at <= cutoff` (app_database.dart:5175-5181). Meanwhile .sync packets are never removed: _processFile deliberately leaves them (lines 492-497), export never prunes (lines 364-370), and the only .sync deletion is the manual clearSyncFolder (line 197). isProcessed is pure row-existence (app_database.dart:5157), so after the marker is pruned the still-present file re-enters the full import path (lines 462-489) and is re-marked, restarting the cycle every 7 days. Cleanup runs after the scan, so re-import lands on the next startSync/importNow — a two-run cycle, trivially met. The wrong outcome is real: exchange_rates/inflation_rates have no isDeleted column, so _softDeleteRecord hard-DELETEs (lines 1265-1295) and _deletableTableName returns null for them (default: line 1370), making _getDeletedRecordModifiedAt null and _insertTombstone a no-op; on replay _applyChange hits localData==null && deletedAt==null and calls _insertRecord (line 609), resurrecting the row. Concrete divergence: user deletes rate USD_EUR_2024-01-01_1 on device B; A applies the delete; B skips its own delete packet as local (line 457) but re-imports A's original insert packet once the marker is pruned, so the rate returns on B only, and repeats weekly forever. Secondary costs hold too: lines 452-453 read+decode before the isProcessed check, and each replayed change that ties/loses LWW writes a conflict_history row plus a full-table clearOldConflicts select (line 637). No test pins this — sync_service_malformed_input_test.dart:205-215 only covers repeated importNow within one run with markers intact; nothing exercises keepProcessedFor or clearOldProcessed.

## F3. A packet is applied change-by-change with no transaction and no per-change error isolation, so one bad field leaves a half-applied packet and silently drops the rest

- status: CONFIRMED (adversarially verified)
- severity: high (verifier: medium)
- kind: correctness | invariant: 9 (and 1)
- site: `my_budget_client/lib/core/sync/sync_service_io.dart:480`

**Failure scenario.** A peer sends one packet of 200 changes whose 3rd change is a category with an out-of-range enum index - either hostile/corrupt input (`"type": 99`) or a legitimately newer build that appended a CategoryType value and sends index 3 (this build's enum has 3 members). _categoryFromJson evaluates `CategoryType.values[(json['type'] as int?) ?? 0]` and throws RangeError; the loop at 480 aborts, the try/finally only restores the FK pragma, and the exception lands in the outer catch at 495. Changes 1-2 are already committed (nothing wraps the loop in a transaction), changes 4-200 are never applied, and the file is not marked processed. The retry re-applies the prefix and throws at the same change; after 3 attempts the file is quarantined in memory and those 197 changes are lost for good. The same holds for `(json['amount'] as num).toDouble()` on a transaction with a missing amount and for `DateTime.parse(json['date'] as String)` on a bad date. sync_record_keys.dart:20-22 states the intended contract - 'one unparsable id must not cost the other changes in that packet' - but only record-id parsing was made total; the JSON->companion converters were not.

**Evidence.** lines 478-487: `try { for (final change in packet.changes) { await _applyChange(change, packet.deviceId, packet.timestamp); } } finally { await _db.customStatement('PRAGMA foreign_keys = ON;'); }` - no `_db.transaction(...)`, no per-change try/catch. sync_service_io.dart:1697 `type: Value(CategoryType.values[(json['type'] as int?) ?? 0])` (same pattern for IconType at 1793 and TypeCurrency at 1770). The malformed-input suite only covers decode-level corruption, which fails before any write.

**Fix sketch.** Wrap the loop in `_db.transaction(() async { ... })` so a packet is all-or-nothing, and catch per change inside it (log + quarantine the single change) so one unconvertible row cannot cost the other 199 - mirroring the decoder's existing forward-compatibility policy of skipping an unknown table/action instead of failing the packet. Bound the enum lookups (`index < Enum.values.length ? values[index] : values[0]`).

**Test sketch.** Test 'a packet whose middle change is unconvertible applies none of it and does not quarantine the rest': hand-build a packet [style s1 (valid), category with type=99, style s2 (valid)], importNow(), then assert either (a) no partial state - s1 absent - or (b) with per-change skipping, s1 and s2 present and the category skipped. Today s1 is present and s2 is missing, which is neither.

**Verifier note.** Confirmed. The apply loop at my_budget_client/lib/core/sync/sync_service_io.dart:477-486 is `try { for (final change in packet.changes) { await _applyChange(...); } } finally { PRAGMA foreign_keys = ON; }` — no `_db.transaction(...)` and no per-change try/catch, and `_applyChange` has exactly one call site (line 481), so no isolation exists upstream either. The decoder (sync_binary_format.dart:216-221) only does `jsonDecode(...) as Map<String, dynamic>`; it validates block framing and makes unknown tableId/action total (fromValue -> null -> `continue` at line 223) for version skew, but never validates payload field values. The converters are non-total: sync_service_io.dart:1742 `CategoryType.values[(json['type'] as int?) ?? 0]` (CategoryType has 3 members, lib/domain/entities/category_type.dart:1-5), :1796 `IconType.values[...]` (only 2 members: material, custom — index 2 throws), :1771 TypeCurrency, plus :1642 `(json['amount'] as num)`, and DateTime.parse at :1652, :1710, :1829, :1946, :1971. These are evaluated in the argument position of `_insertRecord`/`_updateRecord` (lines 1042 and 1107), so the RangeError/TypeError propagates out of the sync service, not into a DAO that could swallow it. Walk of the failure: a peer file whose Nth change carries `"type": 3` (or `"iconType": 2`) applies changes 1..N-1 — each DAO call auto-commits since nothing wraps the loop — then throws; the finally only restores the FK pragma; the exception lands in the packet-level catch at line 498; `markProcessed` at line 489 is skipped and `_failedImportAttempts[fileName]` increments (`_maxImportAttempts = 3` at line 44, in-memory map at line 52). Because the failure is deterministic, each retry re-applies the same prefix and dies at the same change, and after restart (which clears the in-memory quarantine) it repeats forever: the remaining changes are never applied and the two devices never converge. That is a partial write on a malformed/hostile packet, i.e. invariant 9 violated, plus permanent divergence (invariant 1). Not already pinned: test/core/sync/sync_service_malformed_input_test.dart's six tests (lines 64, 78, 92, 135, 169, 202) are all decode-level — empty file, non-gzip garbage, truncated packet, unknown table-id byte — and every one of them fails before any write, so none covers per-change isolation or packet atomicity. Downgraded from high to medium on reachability only: two peers on the same build never emit these values, since the *ToJson side always writes the full field set, so the trigger requires a hostile file in the shared Syncthing folder, corruption that still passes gzip, or a newer build that appended an enum member. That is exactly the input class invariant 9 names ("truncated, corrupt, or hostile packet ... without writing a partial state"), and the decoder's own append-only comments show cross-version skew is treated as a real concern here — but it is abnormal input rather than a normal-operation defect, and the loss is bounded to packets containing such a change.

## F4. sync()'s re-entrancy guard sits behind an await, so two full cycles run in parallel

- status: CONFIRMED (adversarially verified)
- severity: high (verifier: medium)
- kind: correctness | invariant: perf target "no redundant round trips"; puts invariant 6 at risk (a page applied with FK enforcement unexpectedly back ON)
- site: `my_budget_client/lib/core/services/server_sync_service.dart:173`

**Failure scenario.** StartupSyncService.executeStartupSync() calls initWebSocket() (line 213), which calls `_connectWebSocket()` fire-and-forget (line 221), then calls `await sync()` (startup_sync_service.dart:50). sync() suspends on `await _isEnabled()` (line 165) — a real DB read. While it is suspended, `_channel!.ready` completes and _connectWebSocket fires its own `unawaited(sync())` (line 332); that call also suspends on `_isEnabled()`. Both resume, both read `_isSyncingInternal == false` at line 173, both set it true at line 183. Two cycles now run concurrently: the same pull page is downloaded from the same SharedPreferences cursor and applied twice, and the same `sync_push_queue` entries are read, uploaded and drained twice (double upload of the whole backlog). Worse, `_isApplyingRemoteChanges` is a plain bool, not a counter: cycle A's `finally` (line 1122) sets it to false while cycle B is still inside `_applyChanges`, so B's pulled rows reach the tableUpdates listener at line 486 with the flag already false and are classified as a local edit — the pull triggers a sync of its own writes. The same `finally` also issues `PRAGMA foreign_keys = ON` (line 1123) which, being serialised after B's own `PRAGMA ... = OFF`, can land before B's transaction opens, so B applies its page with FK enforcement on and a legitimately parentless child row (a transaction whose account arrives in a later page) aborts the whole page. The same doubling happens whenever the WS doorbell, the 500 ms debounce timer or the 5-minute timer fire within a DB read of each other.

**Evidence.** Future<void> sync() async {
    if (!await _isEnabled()) {   // line 165 — async gap BEFORE the guard
      ...
      return;
    }

    if (_isSyncingInternal) {    // line 173
      _syncRequestedWhileBusy = true;
      return;
    }

    _isSyncingInternal = true;   // line 183

**Fix sketch.** Set the guard synchronously, before any await: check/latch `_isSyncingInternal` (and `_syncRequestedWhileBusy`) as the first statements of sync(), and only then `await _isEnabled()` inside the try/finally that clears the flag. Alternatively serialise every entry point through a single-slot future (`_running ??= _runCycle().whenComplete(() => _running = null)`). Make `_isApplyingRemoteChanges` an int depth counter while you are there so it cannot be cleared by a cycle that is not the one that set it.

**Test sketch.** With a MockClient that answers the first pull with a page and records every request, call `service.sync()` twice without awaiting the first (`final a = service.sync(); final b = service.sync(); await Future.wait([a, b]);`) after seeding one queued row. Assert exactly one GET /api/sync/pull and exactly one POST /api/sync/push were issued. It records two of each before the fix.

**Verifier note.** The gap is real and reachable. sync() (server_sync_service.dart:164) awaits _isEnabled(), which resolves through local_settings_repository.dart:52 -> settingsDao.getSetting — an uncached drift query, i.e. a genuine multi-turn async gap — before the _isSyncingInternal check at :173 and the set at :183. Seven independent, unserialized callers exist (WS doorbell :293, reconnect :332, debounce :519, retry :542, periodic :560, startup_sync_service.dart:50, app_wrapper.dart:55), and the doorbell fires repeatedly per peer cycle because _pushQueuedTable POSTs once per non-empty table while the server calls notifySyncAvailable per POST (my_budget_server/routes/api/sync/push/index.dart:39). Two calls entering within that one DB read both see the guard false and run full cycles concurrently. Consequences that hold: doubled pull and push round trips (violates the "no redundant round trips" target — up to 32 push POSTs where 16 are needed); _isApplyingRemoteChanges is a plain bool (:85/:1071/:1122), so cycle A's finally clears it while B is still applying, and B's committed pull rows pass the :486 echo filter and are misclassified as a local edit, scheduling another cycle; and the un-transactional PRAGMA foreign_keys = ON at :1123 can be ordered between B's PRAGMA OFF (:1069) and B's BEGIN, so B applies a page with FK enforcement on and a parentless child aborts it. No test drives overlapping cycles — server_sync_balance_test.dart's four sync() calls are all sequential and awaited. However the claim overstates the harm: _pushQueueCeiling (:892) freezes each cycle's range and _drainPushQueue (:1019) deletes by explicit ids, so the duplicate push loses nothing (invariant 5 intact); duplicate page application is idempotent upserts (invariant 4 intact); and invariant 6 is not broken by the FK case because _applyChanges is still one transaction and prefs.setInt(lastSyncKey) at :675 runs only after it returns, so the aborted page is simply re-pulled. Net effect is redundant work plus an occasional transient failed cycle, not data corruption.

## F5. Rows applied by a pull are queued by the push triggers and immediately uploaded back to the same server

- status: CONFIRMED (adversarially verified)
- severity: high (verifier: high)
- kind: performance | invariant: perf target "No redundant round trips: … a sync that pushes does not re-pull its own echo"
- site: `my_budget_client/lib/core/services/server_sync_service.dart:1088`

**Failure scenario.** `_applyChanges` writes every pulled row with raw `INSERT … ON CONFLICT DO UPDATE` (line 1088 -> _upsert*), and app_database.dart:3944-3966 puts `AFTER INSERT` / `AFTER UPDATE WHEN NEW.modified_at IS NOT OLD.modified_at` triggers on all 16 synced tables that insert into `sync_push_queue`. Verified against sqlite3 3.44: an upsert that inserts fires the INSERT trigger, an upsert that wins LWW fires the UPDATE trigger (a rejected LWW upsert correctly fires nothing). `_push()` then reads its ceiling AFTER the pull (line 716), so those entries are inside it. Concretely: device B syncs after device A added 20 000 exchange rates; B downloads the 20 000-row page, and the very same sync POSTs the identical 20 000 rows back to /api/sync/push (several MB), where sync_repository.dart discards every one of them because `EXCLUDED.modified_at > exchange_rates.modified_at` is false. Every pull is followed by an upload of exactly what was pulled, and that upload also rings the doorbell for every other device. If the push then fails (offline), those echo entries stay in the queue and getPendingChangesCount() reports a backlog the user never created.

**Evidence.** await table.upsert(json);   // server_sync_service.dart:1088, raw INSERT .. ON CONFLICT
// app_database.dart:3952-3966
'CREATE TRIGGER IF NOT EXISTS trg_push_queue_${table}_insert AFTER INSERT ON $table BEGIN INSERT INTO sync_push_queue ... END'
'CREATE TRIGGER IF NOT EXISTS trg_push_queue_${table}_update AFTER UPDATE ON $table WHEN NEW.modified_at IS NOT OLD.modified_at BEGIN ... END'
// server_sync_service.dart:716
final ceiling = await _pushQueueCeiling();   // read after _pull() has run

**Fix sketch.** Scope the suppression to the server-pull path only (the file engine's imports must keep queueing). Inside `_applyChanges`'s transaction, read `SELECT COALESCE(MAX(id),0) FROM sync_push_queue` as the first statement and, as the last statement of the same transaction, `DELETE FROM sync_push_queue WHERE id > ?`. Drift serialises writes, so every entry above that mark was made by this transaction's own upserts — rows the server already has.

**Test sketch.** `pull returns rows the push never sends back`: MockClient answers one pull page with a single style and 200s any push, recording bodies. Run `service.sync()`, then assert `pushBodies` is empty and `getPendingChangesCount() == 0`. Today the style is POSTed straight back.

**Verifier note.** Confirmed and reachable. sync() runs _pull() then _push() (server_sync_service.dart:192-193). _applyChanges writes every pulled row through raw upserts (line 1089 -> _upsert*, e.g. _upsertExchangeRate at 1840), and app_database.dart:3951-3965 installs AFTER INSERT / AFTER UPDATE WHEN NEW.modified_at IS NOT OLD.modified_at push-queue triggers on all 16 tables in syncPushQueueTables (404-421, incl. exchange_rates). I verified the SQLite semantics myself on 3.50.4 rather than trusting the claim: an upsert taking the insert path fires the INSERT trigger, an upsert winning LWW fires the UPDATE trigger, a losing one fires neither. _push() reads its ceiling at line 716 AFTER the pull committed, so those entries are in scope; nothing deletes them in between (DELETE FROM sync_push_queue exists only in _drainPushQueue:1025, after a 200), and _isApplyingRemoteChanges (85/486/1071/1122) only gates the drift tableUpdates() auto-sync trigger, not the queue. _pushQueuedTable (899-1013) has no device_id filter; the only rowFilter is the device-local settings keys (759). So device B pulling a 20 000-row page immediately POSTs the same 20 000 rows to /api/sync/push, where sync_repository.dart:216-221 (WHERE EXCLUDED.modified_at > exchange_rates.modified_at) discards all of them, and routes/api/sync/push/index.dart rings notifySyncAvailable for every other device anyway. No existing test pins this (test/core/sync/server_sync_push_queue_test.dart covers drain-by-id, reject-leaves-queued, composite keys, device-local settings only), and the queue has no other consumer in lib/, so the entries serve no purpose. Two corrections to the claim: (1) it does not amplify or loop -- a device re-pulling its own pushed rows applies them with equal modifiedAt, the upsert WHERE is false, no trigger fires, and the discarded echo does not bump server_seq, so peers woken by the doorbell get an empty pull; the waste is exactly one extra upload per newly pulled row. (2) the invariant it really breaks is the "No redundant round trips" clause generally, not literally "re-pull its own echo". Impact: ~2x traffic and a full discarded bulk upsert on the heaviest path (283k exchange rates on a fresh secondary device), a fan-out pull from every connected client, and a phantom getPendingChangesCount() backlog (583-592) if the echo push fails offline.

## F6. Push row lookup for exchange_rates / inflation_rates is a full table SCAN per 500-key chunk

- status: CONFIRMED (adversarially verified)
- severity: high (verifier: high)
- kind: performance | invariant: perf target "Every hot predicate the sync paths use is index-covered … No SCAN on transactions, exchange_rates, sync_push_queue or sync_log"
- site: `my_budget_client/lib/core/services/server_sync_service.dart:952`

**Failure scenario.** `syncPushQueueKeyExpression('exchange_rates')` is `from_currency_code || '|' || to_currency_code || '|' || date || '|' || preset`, and the push looks rows up with `WHERE <that expression> IN (?,?,…)`. No index can serve a concatenation, and none exists (only idx_exchange_rates_composite and the composite PK autoindex). EXPLAIN QUERY PLAN on the real schema returns `SCAN exchange_rates`. After the v12->v13 migration seeds the queue with every existing row (app_database.dart:4310-4317), a budget with 283 000 seeded rates pushes in 15 batches of 20 000 keys, each batch chunked into 40 IN-lists of 500 -> 600 full scans of a 283 000-row table, ~170 M row visits, before a single byte is uploaded. The same applies to inflation_rates. Every later push of an API rate fetch (hundreds of pairs) pays one full scan per chunk too.

**Evidence.** final keyExpression = syncPushQueueKeyExpression(tableName);   // line 918
...
'SELECT * FROM $tableName '
'WHERE $keyExpression IN ($placeholders)'   // lines 952-953
// EXPLAIN QUERY PLAN => `--SCAN exchange_rates

**Fix sketch.** Add an additive expression index matching the trigger exactly — `CREATE INDEX IF NOT EXISTS idx_exchange_rates_push_key ON exchange_rates (from_currency_code || '|' || to_currency_code || '|' || date || '|' || preset)` (and the inflation_rates equivalent), created in onCreate and in a new migration step; verified to turn the plan into `SEARCH exchange_rates USING INDEX … (<expr>=?)`. Alternatively split record_key back into its parts and emit an OR-of-AND-tuples, which the composite PK autoindex serves via MULTI-INDEX OR.

**Test sketch.** In test/core/database, run `EXPLAIN QUERY PLAN SELECT * FROM exchange_rates WHERE <syncPushQueueKeyExpression('exchange_rates')> IN (?,?)` and assert no returned `detail` contains 'SCAN'. Fails today, passes with the index.

**Verifier note.** Confirmed. server_sync_service.dart:918 builds the lookup predicate from syncPushQueueKeyExpression (app_database.dart:429), which for exchange_rates/inflation_rates is a string concatenation of the PK columns, and lines 950-959 issue `SELECT * FROM exchange_rates WHERE <concat> IN (?,...)`. The schema has only idx_exchange_rates_date, idx_exchange_rates_composite(from,to,date) and the composite-PK autoindex (app_database.dart:236-240, app_database.g.dart:11651-11656) — no expression index exists anywhere in the tables or migrations, and no index can serve a concatenation. I reproduced the exact table+indexes in sqlite3 3.44 and EXPLAIN QUERY PLAN returns `SCAN exchange_rates`. The path is reachable: onCreate deliberately installs the push-queue triggers after the rate seed to avoid queueing the bundled rows (app_database.dart:3993-3999), but the v12->v13 migration seeds the queue from every synced table unconditionally (app_database.dart:4310-4317), so every upgrading user queues all ~283k rates. With batchSize=20000 and keyChunk=500 that is 15 batches x 40 chunks = 600 full scans of a 283k-row table. Measured on a real 283,000-row table with warm cache: 10 chunks took 2.10s (~0.21s/chunk), extrapolating to ~126s of pure SQLite time before a single byte is uploaded — worse on mobile. The recurring cost is real too: insertAllExchangeRates trips the unconditional AFTER INSERT trigger (app_database.dart:3948-3956) per row, so each API rate refresh push pays one full scan per 500 keys. Refutation attempts failed: the only guards (`ceiling <= 0`, empty-entries break, `_isSyncingInternal`) do not avoid the scans in this state; `grep -rn "EXPLAIN QUERY PLAN"` over both packages returns nothing, so no existing test pins index coverage for any sync predicate. This violates the explicit target in docs/sync-goal.md:62-64 naming exchange_rates.

## F7. A pull page re-sends every untruncated table's whole delta once per page of the truncated table

- status: CONFIRMED (adversarially verified)
- severity: high (verifier: high)
- kind: performance | invariant: Perf target: "Work per synced row is O(1) statements" / "a pull page applies all-or-nothing" (invariant 6) — rows are delivered O(pages) times instead of once
- site: `my_budget_server/lib/data/sync_repository.dart:1268`

**Failure scenario.** Seeded budget: 283 000 exchange_rates pushed first (server_seq 1..283000), then 4 000 transactions (server_seq 283001..287000). A fresh device pulls; the server clamps the client's `limit=20000` to `maxPullLimit = 5000` (api_responses.dart:11). Page 1: exchange_rates returns seq 1..5000 and sets `hitLimit`, so `truncatedCursor = 5000` and `nextCursor = 5000`; but the transactions query is *not* truncated, so all 4 000 transaction rows (seq 283001..287000) are put into `changes` and shipped. The client applies them, stores cursor 5000, loops. Page 2 asks `last_sync=5000` — the same 4 000 transactions come back again, and again on every one of the 57 pages needed to drain exchange_rates. Result: 4 000 transactions are serialised, transferred and upserted 57 times = 228 000 client-side `customInsert` statements plus 57 `anchorOpeningBalances` + `recomputeBalances` passes over the same accounts (server_sync_service.dart:1108-1115), instead of 4 000 / 1. The same multiplication hits accounts, categories, settings, styles and every other small table on every full sync. The comment at line 1281-1283 says the untruncated tables "simply re-send a few rows on the next page" — it is not a few rows and not one page, it is the entire delta of 15 tables times the number of pages the largest table needs.

**Evidence.** if (rows.isNotEmpty) { ... changes[result.tableName] = rows; }   // line 1260-1268, unconditional
...
if (result.hitLimit) { hasMore = true; if (truncatedCursor == null || result.cursor < truncatedCursor) truncatedCursor = result.cursor; }
...
final nextCursor = truncatedCursor ?? maxSeq;   // line 1284

**Fix sketch.** Compute `nextCursor` first, then trim each table's slice to it before building `changes`: `rows.removeWhere((r) => (r['serverSeq'] as int) > nextCursor)` (and drop the table key if the slice becomes empty). Every row is then handed out exactly once, the page is a true prefix of the write order, and `hasMore` still drives the loop. No wire change — the client already re-pulls from `server_timestamp`.

**Test sketch.** In test/data/sync_repository_test.dart, extend the existing 'a truncated table pins the cursor for every table' case: answerPages([[row(1,'c1'),row(2,'c2'),row(3,'c3')],[row(900,'t1')]]); getChanges(0, limit: 3). Assert `lastTimestamp == 3` (unchanged) AND `result.changes.containsKey('transactions')` is false — the seq-900 row must not be shipped under a cursor of 3. Fails today (the row is shipped and will be shipped again on the next page), passes after trimming.

**Verifier note.** Confirmed and reachable. In sync_repository.dart:1258-1284 every table's rows are added to `changes` at line 1268 before `truncatedCursor` is known; the cursor is then pinned to the minimum cursor of the truncated tables (1272-1284), so every row an untruncated table returned above that pin is shipped and then re-shipped on the next page, and the next, until the truncated table drains. server_seq is a single global sequence (database_client.dart:339-377), so a server whose 283k exchange rates were pushed before the user's 4 000 transactions puts all transactions above the rate range. The client asks limit=20000, clamped to maxPullLimit=5000 (api_responses.dart:11), needs 57 pages for the rates, stores `server_timestamp` as its cursor and loops (server_sync_service.dart:619-692, cap 200 iterations so it does not bail). _applyChanges issues one customInsert per row (line 1089 / _upsertTransaction at 1601) plus one anchorOpeningBalances + recomputeBalances pass per page (1107, 1115). Count: 4 000 x 57 = 228 000 upsert statements instead of 4 000, 57 balance-rebuild aggregate scans instead of 1, and ~57x the JSON for transactions/accounts/categories/styles/settings. No guard downstream: routes/api/sync/pull/index.dart passes changes through verbatim, the client dedupes nothing, and /api/sync/full is never called by the client. The existing test sync_repository_test.dart:447 pins only lastTimestamp and hasMore, not which rows are in `changes`, so it does not pin this behaviour and would stay green if the over-cursor rows were filtered out. Correctness (invariant 6, idempotent replay) is unaffected; the violation is the perf target "work per synced row is O(1) statements", which here degrades to O(pages of the largest table) for every other table.

## F8. Pull applies a page one INSERT at a time — N rows = N statements per table

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: high
- kind: performance | invariant: Perf target: "Work per synced row is O(1) statements: applying a page of N rows must not issue N queries per table (bulk upserts / batched writes)"
- site: `my_budget_client/lib/core/services/server_sync_service.dart:1089`

**Failure scenario.** The server holds the bundled 283,000 exchange rates. `parsePullLimit` clamps the client's `limit=20000` to 5,000 per table (my_budget_server/lib/http/api_responses.dart:11), so a full pull is 57 pages. Each page runs `_applyChanges`, whose inner loop awaits one `customInsert` per row: 5,000 separate statements (each one a round-trip through drift's background isolate) per page, 283,000 for the whole pull. A page that also carries transactions, accounts, asset_entries etc. issues up to 16 x 5,000 = 80,000 statements inside a single transaction — every one of the sixteen `_upsert*` bodies is a single-row `INSERT ... VALUES (?,…)`. Fix: chunked multi-row `VALUES` with the same `ON CONFLICT … WHERE EXCLUDED.modified_at > t.modified_at` tail (SQLite evaluates the conflict per row, so semantics are unchanged). At 500 rows/statement a 5,000-row page costs 10 statements instead of 5,000, and the 283k pull costs 566 instead of 283,000 — a 500x reduction in statements and isolate round-trips.

**Evidence.** for (final row in list) {
  final json = row as Map<String, dynamic>;
  await table.upsert(json);   // line 1089 — one customInsert per row, 16 tables

**Fix sketch.** Change the `_pullTableOrder` entries from `Future<void> Function(Map)` to `Future<void> Function(List<Map>)`. Each `_upsert*` builds `INSERT INTO t (cols) VALUES (?,..),(?,..)… ON CONFLICT(...) DO UPDATE SET … WHERE EXCLUDED.modified_at > t.modified_at` over chunks sized `min(500, 32766 ~/ columnCount)`, binding the same variables it binds today. `touchedAccounts` / `anchorlessAccounts` are collected from the JSON list before the chunked write, exactly as now.

**Test sketch.** Wrap the in-memory AppDatabase in a QueryExecutor proxy that counts `runInsert`/`runCustom` calls. Stub `http.Client` to return one pull page of 1,000 transactions. Call `sync()` and assert the executor saw fewer than 50 insert statements. Fails today (1,000+), passes after.

## F9. Push row lookup on exchange_rates/inflation_rates is a full table scan per 500-key chunk

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: high
- kind: performance | invariant: Perf target: "Every hot predicate the sync paths use is index-covered … No SCAN on transactions, exchange_rates, sync_push_queue or sync_log in the sync queries"
- site: `my_budget_client/lib/core/services/server_sync_service.dart:952`

**Failure scenario.** `syncPushQueueKeyExpression('exchange_rates')` (app_database.dart:437) renders the key as `from_currency_code || '|' || to_currency_code || '|' || date || '|' || preset`, and `_pushQueuedTable` looks the rows up with that expression on the left of `IN (?,…)`. An expression predicate cannot use the PK or `idx_exchange_rates_composite`. Verified with sqlite3 3.44 on the real schema: `EXPLAIN QUERY PLAN SELECT * FROM exchange_rates WHERE from_currency_code||'|'||to_currency_code||'|'||date||'|'||preset IN (?,?,?)` -> `SCAN exchange_rates`. After the v12->v13 migration seeds the queue from every synced table (app_database.dart:4313), sync_push_queue holds 283,000 exchange_rates entries. The push reads 20,000 per batch and resolves them 500 keys at a time: 566 chunks x a 283,000-row scan = ~160 million row reads plus 160 million four-part string concatenations for one push. `inflation_rates` has the same shape (verified `SCAN inflation_rates`). After the fix: 283,000 PK index seeks, ~0.2% of the work.

**Evidence.** 'SELECT * FROM $tableName '
'WHERE $keyExpression IN ($placeholders)'   // keyExpression = from||'|'||to||'|'||date||'|'||preset

**Fix sketch.** Add a per-table key-decomposition alongside `syncPushQueueKeyExpression`: for exchange_rates split each queued key on '|' and emit `WHERE (from_currency_code, to_currency_code, date, preset) IN (VALUES (?,?,?,?), …)` (row values are index-usable — EXPLAIN gives `SEARCH … USING INDEX sqlite_autoindex_exchange_rates_1`); same for inflation_rates on (date, country, preset). Keep the plain `IN` for the single-column tables. Chunk on 999/4 = 240 keys.

**Test sketch.** `test/core/services/server_sync_push_plan_test.dart`: build the exact lookup SQL the push uses for 'exchange_rates', run it through `customSelect('EXPLAIN QUERY PLAN ' + sql)`, and assert no returned `detail` starts with 'SCAN exchange_rates'. Fails today, passes after.

## F10. Every row a pull applies is re-queued by the push-queue triggers and uploaded straight back

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: high
- kind: performance | invariant: Perf target: "No redundant round trips: a sync with nothing pending issues no push request and one pull request at most; a sync that pushes does not re-pull its own echo"
- site: `my_budget_client/lib/core/services/server_sync_service.dart:1074`

**Failure scenario.** `trg_push_queue_<table>_insert` fires AFTER INSERT unconditionally and `trg_push_queue_<table>_update` fires whenever `modified_at` moves (app_database.dart:3951-3966). `_applyChanges` writes rows with raw `INSERT … ON CONFLICT DO UPDATE SET modified_at = EXCLUDED.modified_at`, so both branches trip a trigger, and nothing in the pull transaction removes the entries. `sync()` runs `_pull()` then `_push()` in the same cycle (line 195-196). Fresh device, cursor 0, server holding 283,000 exchange rates + 5,000 transactions: the pull leaves 288,000 sync_push_queue entries naming rows the server just sent, and `_push` then uploads all 288,000 back in 15 POSTs of multi-MB JSON, which the server's `WHERE EXCLUDED.modified_at > …` guard discards row for row. It also drags finding #2's 160M-row scan along with it, and `getPendingChangesCount()` reports 288,000 outstanding changes right after a successful sync. After the fix: 0 queue entries, 0 push requests, 0 wasted uploads.

**Evidence.** await _database.transaction(() async {   // line 1074 — no queue bookkeeping
  …
  await table.upsert(json);
// app_database.dart:3952 'CREATE TRIGGER … AFTER INSERT ON $table BEGIN INSERT INTO sync_push_queue …'

**Fix sketch.** Inside `_applyChanges`' transaction, read `SELECT COALESCE(MAX(id),0) FROM sync_push_queue` before the table loop and `DELETE FROM sync_push_queue WHERE id > ?` after `recomputeBalances`. SQLite serialises writers, so nothing but this transaction can have inserted an id above the mark — user edits made during the pull land after the commit with higher ids and survive. P2P file-engine imports keep their entries, which is what the trigger comment is actually about.

**Test sketch.** Stub the http client to return one pull page of 50 exchange rates and record every request. Run `sync()`. Assert `getPendingChangesCount() == 0` and that no request was made to `/api/sync/push`. Fails today (50 pending, one push POST).

## F11. Server has no is_deleted column for api_settings, so a deleted rate/asset provider is resurrected on every other device

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: high
- kind: correctness | invariant: 10 (payload field silently dropped by a peer); also 3 (deletes stay deleted)
- site: `my_budget_server/lib/data/sync_repository.dart:801`

**Failure scenario.** Device A deletes the "exchange_rates" API provider. `_apiSettingsToJson` (my_budget_client/lib/core/services/server_sync_service.dart:1300) pushes `{'id':'exchange_rates', 'enabled':false, 'modifiedAt':2000, 'isDeleted':true}`. Server `_upsertApiSetting` binds only id/enabled/auto_fetch/last_fetch_at/modified_at/device_id — the `api_settings` table created at my_budget_server/lib/data/database_client.dart:291 has no `is_deleted` column at all, and the pull column map at sync_repository.dart:1130 lists none either. Device B pulls `api_settings` and gets a row with NO `isDeleted` key. Client `_upsertApiSetting` (server_sync_service.dart:1771) computes `_parseBool(json['isDeleted'])` → `_parseBool(null)` → `false`, and the row's `modified_at = 2000` is strictly greater than B's, so the ON CONFLICT UPDATE fires and writes `is_deleted = 0` over B's tombstone. The provider the user deleted comes back, enabled=false but visible, and keeps coming back on every pull. Device A itself resurrects it too on any pull after a local DB reset.

**Evidence.** my_budget_server/lib/data/sync_repository.dart:801  `INSERT INTO api_settings (id, enabled, auto_fetch, last_fetch_at, modified_at, device_id)` — no is_deleted, and no `is_deleted` key in the api_settings entry of tableConfigsMap (line 1130: `'api_settings': {'auto_fetch': 'autoFetch', 'last_fetch_at': 'lastFetchAt', 'modified_at': 'modifiedAt', 'device_id': 'deviceId'}`). Client comment at server_sync_service.dart:1296 asserts the opposite: "Without this the delete never left the device: ... the provider the user removed kept coming back from the server on every other device."

**Fix sketch.** Additive migration in database_client.dart: `ALTER TABLE api_settings ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE`; add `is_deleted` to the INSERT/ON CONFLICT list in `_upsertApiSetting` with the same `row['isDeleted'] is bool ? ... : (... == 1)` coercion the other upserts use; add `'is_deleted': 'isDeleted'` to the `api_settings` entry of tableConfigsMap. Client already sends and reads the field, so the wire format is unchanged.

**Test sketch.** my_budget_server/test/data/sync_repository_test.dart: `upsertBatch({'api_settings':[{'id':'exchange_rates','enabled':false,'modifiedAt':2000,'isDeleted':true}]})`, then `getChanges(0)` and expect `changes['api_settings'].single['isDeleted']` to be `true`. Fails today (key absent) and passes after. Pair it with a client test that feeds that pulled row into `_applyChanges` and asserts the local `api_settings_table` row keeps `isDeleted = true`.

## F12. DateTime round trip through the server shifts every date by the client's UTC offset (naive on the way out, UTC-stamped on the way back)

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: high
- kind: correctness | invariant: 10 (dates must come back exactly as they went out, in every locale)
- site: `my_budget_server/lib/data/sync_repository.dart:1298`

**Failure scenario.** Drift stores DateTime as unix seconds and hands back LOCAL DateTimes (no `storeDateTimeAsText` anywhere in my_budget_client). A device in America/New_York (UTC-5) holds an exchange rate at local midnight 2026-08-12 00:00 (= 2026-08-12T05:00Z). `_exchangeRateToJson` (my_budget_client/lib/core/services/server_sync_service.dart:1331) emits `e.date.toIso8601String()` = "2026-08-12T00:00:00.000" — no zone marker. Server `_parseDate` does `DateTime.tryParse` → naive DateTime in the SERVER's zone (UTC in a container), and package:postgres encodes it with `input.toUtc()` (postgres-3.5.9/lib/src/types/binary_codec.dart:160), storing 2026-08-12 00:00. On pull, the driver decodes `timestamp` as `DateTime.utc(...)` (binary_codec.dart:862), and `_mapResult` emits `value.toIso8601String()` = "2026-08-12T00:00:00.000**Z**". The client's `_upsertExchangeRate` (server_sync_service.dart:1864) does `DateTime.tryParse` → a UTC instant → `Variable.withDateTime` stores that instant, which renders locally as 2026-08-11 19:00. The row's calendar day moved back one day. Because `date` is part of the exchange_rates primary key, the ON CONFLICT target no longer matches the original row: a SECOND row is inserted at the shifted instant, and `formatSyncRecordDate` (sync_record_keys.dart) now spells its record id `USD_EUR_2026-08-11_0` instead of `..._2026-08-12_0`. Same shift hits `transactions.date` (server_sync_service.dart:1245) and `accounts.creationDate` (line 1229), moving month-boundary transactions into the previous month on every device west of UTC.

**Evidence.** my_budget_server/lib/data/sync_repository.dart:1298  `if (value is DateTime) { map[newKey] = value.toIso8601String(); }` — the decoded value is `DateTime.utc(...)`, so this always writes a 'Z'. Push side sends naive: my_budget_client/lib/core/services/server_sync_service.dart:1331 `'date': e.date.toIso8601String()` on a local DateTime. `_parseDate` (sync_repository.dart:1005) `DateTime.tryParse(val)` treats the naive string as server-local.

**Fix sketch.** Make both legs explicit and identical. Cheapest backward-compatible fix: on the client, serialise with `e.date.toUtc().toIso8601String()` in every `_*ToJson` date field on the server-sync path (lines 1229, 1245, 1263, 1331, 1338), so the string always carries 'Z' and the server's `DateTime.tryParse` yields the same instant it was given. An old client sending a naive string still parses; a new client's 'Z' string parses identically on an old server, so the wire stays compatible.

**Test sketch.** my_budget_client/test/core/sync/sync_service_rate_tables_test.dart: build an ExchangeRate at a local DateTime whose UTC offset is non-zero, assert `DateTime.parse(_exchangeRateToJson(r)['date'] as String).isAtSameMomentAs(r.date)` — fails today whenever the process TZ is not UTC. Then feed the resulting string back through `_upsertExchangeRate` and assert exactly one row exists and `formatSyncRecordDate(row.date)` equals `formatSyncRecordDate(r.date)`.

## F13. A P2P packet is applied change-by-change with no enclosing transaction, so one bad change commits the prefix and silently drops the rest

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: high
- kind: correctness | invariant: 9 (malformed input must fail closed, without writing a partial state)
- site: `my_budget_client/lib/core/sync/sync_service_io.dart:480`

**Failure scenario.** A peer sends a 3-change packet: [style s-remote upsert (valid)], [transaction t1 upsert with `"amount": null`], [account a1 upsert (valid)]. `_processFile` toggles `PRAGMA foreign_keys = OFF` and loops `await _applyChange(...)` with NO `_db.transaction(...)` around it. Change 1 commits. Change 2 reaches `_transactionFromJson` line 1642 `(json['amount'] as num).toDouble()` → TypeError, which propagates out of `_applyChange` to the broad `catch (e)` at line 498. The file is NOT marked processed, `_failedImportAttempts` goes to 1. The DB now holds the style (partial state written) but not the account. The next two scans replay changes 1-2 and fail identically; at attempt 3 the file is quarantined (line 447) and change 3 — a perfectly valid account — is lost forever with no record that it existed. The existing malformed-input tests do not catch this: the truncated-packet test (test/core/sync/sync_service_malformed_input_test.dart:92) encodes a SINGLE change, so decode throws before any change is applied and 'must not partially apply' passes vacuously.

**Evidence.** my_budget_client/lib/core/sync/sync_service_io.dart:477-486  `await _db.customStatement('PRAGMA foreign_keys = OFF;'); try { for (final change in packet.changes) { await _applyChange(change, packet.deviceId, packet.timestamp); } } finally { await _db.customStatement('PRAGMA foreign_keys = ON;'); }` — no transaction, and no per-change try/catch. Compare the server path, which wraps a whole page in one transaction and documents why (server_sync_service.dart:1057-1066).

**Fix sketch.** Either wrap the loop in `_db.transaction(() async { ... })` so the packet is all-or-nothing (the FK pragma must stay outside the transaction, as the server path already notes), or — better for a hostile peer — catch per change, count it, and continue, so one poisoned record cannot cost the other 999 in the packet. The two combine: apply inside a transaction, skip-and-log individually invalid changes.

**Test sketch.** test/core/sync/sync_service_malformed_input_test.dart: encode a packet whose changes are [valid style, transaction with `'amount': null`, valid style s2], write it, `await service.importNow()`. Assert either (a) neither s-remote nor s2 exists (all-or-nothing) or (b) both exist (skip-the-bad-one) — today s-remote exists and s2 does not, which is the one outcome no policy allows.

## F14. Reported "ru delete confirmation" flake does not reproduce; the real order-dependent failures are elsewhere

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: high
- kind: test-gap | invariant: none (the "whole suite green" verification gate in docs/sync-goal.md)
- site: `my_budget_client/test/presentation/widgets/data_tab_localisation_test.dart:65`

**Failure scenario.** I could not reproduce the described flake at HEAD (1763f6d). Six full `flutter test` runs of my_budget_client: 3 default (`+1422 All tests passed`, ~50s), 2 with `--concurrency=12`, and I also ran the file's directory alone, `test/presentation` alone, `test/core` + the file, and `test/data test/domain test/financial_engine sms_parser_test.dart` + the file. All green. Cross-suite Dart state cannot be the cause here: `flutter test` spawns one `flutter_tester` OS process per test file (verified by process listing mid-run: 4 concurrent `flutter_tester` PIDs), so `Intl.defaultLocale`, get_it, `SharedPreferences.setMockInitialValues`, `AppDatabase.seedExchangeRatesOnCreate` and leaked timers are all per-process and cannot leak into this suite. The one shared-state leak that *is* real and *does* fail under reordering lives in test/core/database/sync_log_coverage_test.dart (reported separately). Concretely: `flutter test --test-randomize-ordering-seed=random` failed twice out of two runs, both times on `CategoriesDao updateCategory logs an additional upsert row` and `CategoriesDao deleteCategory logs a delete row` with `Null check operator used on a null value` — never on data_tab_localisation_test.dart. Conclusion: the flake report is stale (commit fd2ee3c fixed the 53 LocaleDataException failures that were the real full-run breakage), and no state leak into this file exists to fix.

**Evidence.** test/presentation/widgets/data_tab_localisation_test.dart:65 `testWidgets('the account delete confirmation is readable in ru', (tester) async {` — the suite has no setUp/setUpAll/tearDown at all and this is the first test in the file, so nothing inside the file can precede it; the file's only external dependency is `../test_app.dart`, whose `pumpAppWidget` (test/presentation/test_app.dart:211) touches no global other than `tester.view`, which it resets via `addTearDown(tester.view.reset)` (test_app.dart:196). Run log tail: `00:50 +1422: All tests passed!`

**Fix sketch.** Nothing to fix in this file. If the failure resurfaces in CI, capture the actual `[E]` message before changing anything — the two plausible classes are (a) `LocaleDataException` if a future edit makes the dialog format a date (fix: `setUpAll(() => initializeDateFormatting())` in this test file, as fd2ee3c did for six others — test-only, lib/presentation untouched), and (b) genuine intra-file order dependence, which `--test-randomize-ordering-seed` would expose. To close the class permanently, add `--test-randomize-ordering-seed=random` to the verification gate in docs/sync-goal.md so chained tests fail loudly instead of silently depending on declaration order.

**Test sketch.** Add `--test-randomize-ordering-seed=random` to the documented `flutter test` gate. Before the sync_log_coverage_test fix below it fails; after, it passes.

## F15. Invariant 2 has no test for the device-id tie-break — and the existing tie test pins the opposite, divergence-producing rule

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: high
- kind: test-gap | invariant: 2 (deterministic conflict resolution), and by consequence 1 (convergence)
- site: `my_budget_client/test/core/sync/sync_service_lww_test.dart:178`

**Failure scenario.** Device A and device B both edit style `s1` at the same `modifiedAt` (3000): A sets name 'A-name', B sets name 'B-name'. A exports a packet, B imports it -> `_applyChange` takes the final `else` branch (incoming is not strictly newer) and B keeps 'B-name'. B exports, A imports -> same branch, A keeps 'A-name'. Both rows now sit at modifiedAt 3000 with different names and neither will ever move again, because every future exchange re-takes the same branch. The two devices are permanently divergent on a row that both consider settled, and no conflict is surfaced anywhere except conflict_history. Same clock values are not exotic: the exchange-rate/inflation seed rows and any two edits inside the same millisecond collide, and `SettingsDao.setSetting` stamps `DateTime.now().millisecondsSinceEpoch`. The existing test asserts exactly this behaviour and calls it 'deterministic', which locks the bug in: it is deterministic per device, but not identical across devices, which is what the invariant demands.

**Evidence.** lib/core/sync/sync_service_io.dart:626 `'[SYNC_DEBUG] Ignoring incoming update for: ${change.recordId} (Local newer: $localModifiedAt >= $incomingModifiedAt)'` — reached from `} else if (incoming­ModifiedAt > localModifiedAt) { ... } else { <local wins> }` (sync_service_io.dart:610-632). `change.deviceId`/`fromDevice` is passed into `_applyChange` but is used only for `conflictHistoryDao.saveConflict(rejectedDevice: fromDevice)`, never as a tie-break. Test that cements it: test/core/sync/sync_service_lww_test.dart:178 `test('equal modifiedAt is deterministic: local wins, incoming is rejected', ...)` with `expect(style.name, 'Local Name')`.

**Fix sketch.** In `_applyChange`, replace the strict `>` comparison with a total order over `(modifiedAt, deviceId)`: accept the incoming row when `incomingModifiedAt > localModifiedAt || (incomingModifiedAt == localModifiedAt && fromDevice.compareTo(_localDeviceId!) > 0)`. Apply the same rule to the delete branch (sync_service_io.dart:543) and to the server path's `WHERE EXCLUDED.modified_at > <table>.modified_at` upserts (server_sync_service.dart:1540-1570, 1761, 1829) so both paths agree. Then rewrite sync_service_lww_test.dart:178 to assert the device-id rule rather than 'local wins'.

**Test sketch.** `test('a tie is broken by device id, so both devices pick the same winner')`: build two SyncService instances (device-a, device-b) over two in-memory databases sharing one sync folder; write style s1 on each at modifiedAt 3000 with different names; export from both and import on both; assert `styleOnA('s1').name == styleOnB('s1').name` and that the winner is the row from the lexicographically larger device id. Fails today (each side keeps its own name), passes after the fix.

## F16. Invariant 1 has no convergence test: every P2P test is one-directional, single-delivery

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: high
- kind: test-gap | invariant: 1 (convergence under any delivery order and any number of duplicate deliveries)
- site: `my_budget_client/test/core/sync/sync_service_lww_test.dart:99`

**Failure scenario.** There is no test anywhere in test/core/sync/** that (a) syncs in both directions, (b) permutes packet order, (c) delivers a packet twice, and then (d) compares full table dumps of the two databases. Every test in sync_service_lww_test.dart calls only `syncAToB()` and asserts one field of one row on B. So an asymmetry like the tie-break above, or a rule that depends on which file the directory listing yields first, passes the whole suite while leaving two real devices with different data. Concrete example that the suite would not catch: A creates transaction t1 (modifiedAt 1000) and deletes it (modifiedAt 2000) in one batch, B edits t1 (modifiedAt 2000) — deliver A's packet to B first, then B's to A. B applies the delete (2000 > 2000 is false, so the delete is *ignored* at sync_service_io.dart:543) and keeps its edit; A keeps its tombstone. Divergent, and nothing fails.

**Evidence.** test/core/sync/sync_service_lww_test.dart:99 `Future<void> syncAToB() async {` is the only exchange helper in the file; there is no `syncBToA`. Grep across test/core/sync/** for `converg`, `duplicate`, `replay`, `twice` returns nothing but an unrelated comment at sync_service_lww_test.dart:114.

**Fix sketch.** Add a bidirectional exchange harness: `syncBoth()` that exports from both devices into the shared folder and imports on both, plus a `dumpAllSyncedTables(db)` helper that selects every SyncTableId table ordered by primary key and returns comparable maps. Assert `await dumpAllSyncedTables(dbA) == await dumpAllSyncedTables(dbB)`.

**Test sketch.** `test('two devices converge whatever order the packets arrive in, however many times')`: seed a scripted list of ~15 writes/edits/deletes across styles, categories, accounts, transactions and exchange_rates on both devices; export; then import the packet files on each side in (i) directory order, (ii) reversed order, (iii) reversed order with every file delivered twice under a fresh name; assert the two full table dumps are byte-identical in all three schedules. Fails today on the tie case and on the delete-vs-equal-timestamp case; passes once the total order of finding 2 is in place.

## F17. Invariant 8 is tested only on the server path — the P2P importer writes the peer's balance verbatim and no test notices

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: high
- kind: test-gap | invariant: 8 (derived values are recomputed, not trusted — explicitly "on both paths")
- site: `my_budget_client/lib/core/sync/sync_service_io.dart:1692`

**Failure scenario.** Device A has account acc1 with balance 100 (one transaction of +100). Device B has the same account with a different transaction of +50, balance 50. A exports; B imports. `_accountFromJson` takes `json['balance']` and writes it straight into the row, so B's account now reads 100 while B's merged transaction set sums to 150. The transactions merge as a set, the balance merges as a scalar, and the last packet to arrive dictates a number that reconciles with nothing. The same applies to a transaction that moves between accounts over file sync: the account it left is never rebuilt. `grep -n 'recompute\|anchorOpeningBalances' lib/core/sync/sync_service_io.dart` returns zero hits, and no test in test/core/sync/** asserts a balance at all — test/core/services/server_sync_balance_test.dart exercises only `ServerSyncService`.

**Evidence.** lib/core/sync/sync_service_io.dart:1692-1700 `final balance = (json['balance'] as num).toDouble(); ... balance: Value(balance), balanceMinor: Value(_minorUnits(json, 'balanceMinor', balance, currencyCode)),`. Contrast lib/core/services/server_sync_service.dart:1115 `await _database.accountsDao.recomputeBalances(touchedAccounts);` with the comment at 1108-1114 explaining precisely why the wire balance must be thrown away — a rationale the file-sync path does not follow.

**Fix sketch.** In `SyncService._importFile`, collect the account ids touched by the batch the same way `ServerSyncService._applyChanges` does — the `accountId` of every imported transaction plus the *pre-existing* local `accountId` of those transaction ids read before the upsert, plus every imported account id — and after the batch call `_db.accountsDao.anchorOpeningBalances(anchorless)` then `_db.accountsDao.recomputeBalances(touched)`. The push-queue UPDATE trigger already ignores balance-only rewrites (app_database.dart:3962, `WHEN NEW.modified_at IS NOT OLD.modified_at`), so this does not create an upload echo.

**Test sketch.** `test('a transaction imported over file sync rebuilds the balance, and the account it left')`: on device B create acc1/acc2 and a +50 transaction on acc1; on device A create the same accounts and a +100 transaction t1 on acc1, sync A->B, assert acc1.balance == 150 (not 100); then on A move t1 to acc2 and sync again, assert acc1.balance == 50 and acc2.balance == 100. Fails today on the first assertion.

## F18. _processFile is never serialized and toggles a global FK pragma, so concurrent imports re-enable foreign keys in the middle of another import

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: correctness | invariant: 9 (and 4)
- site: `my_budget_client/lib/core/sync/sync_service_io.dart:412`

**Failure scenario.** The watcher is subscribed at line 157 before the initial scan at 160 and fires `_processFile` without awaiting it (412/415), so imports overlap by construction - on Windows a single delivered file produces a create event (immediate _processFile) plus modify events (a second _processFile 500 ms later), and Syncthing delivering a burst of files starts one future per file. Import #1 (a large packet) sets `PRAGMA foreign_keys = OFF` and yields at its first await; import #2 of a small file sets OFF, finishes, and its finally sets `PRAGMA foreign_keys = ON` while #1 is still halfway through its loop. #1's next insert is a transaction whose account has not been imported yet, the FK now bites, the exception aborts #1 mid-packet leaving the first k changes committed (see the previous finding - no transaction), and #1's file is never marked processed. Under a delivery burst this repeats; after 3 attempts the file is quarantined and its remaining changes are lost. The same missing serialization makes the isProcessed check at 462 a check-then-act race: two futures for the same file both read false and both apply the packet.

**Evidence.** lines 402-417 `void _onFileSystemEvent(FileSystemEvent event) { ... Future.delayed(const Duration(milliseconds: 500), () { _processFile(File(event.path)); }); } else { _processFile(File(event.path)); }` - both calls discard the returned Future; lines 475/485 `await _db.customStatement('PRAGMA foreign_keys = OFF;')` / `'PRAGMA foreign_keys = ON;'` is a connection-global, non-reentrant toggle; there is no lock, Completer or queue anywhere in the file.

**Fix sketch.** Serialize all imports behind a single chained Future (`_importChain = _importChain.then((_) => _processFile(f))`) or a simple mutex, so only one packet is in flight at a time; that also makes the pragma toggle safe and closes the isProcessed race. Better still, run the packet inside `_db.transaction` with `PRAGMA defer_foreign_keys = ON`, which is transaction-scoped instead of connection-global.

**Test sketch.** Test 'two concurrent imports of different files do not disable each other's FK deferral / do not both apply the same file': write two valid packets, call `Future.wait([service.importNow(), service.importNow()])`, and assert every change from both packets is applied exactly once and no sync_processed_files row is missing. A tighter unit test: start import of a big packet and, without awaiting, import a tiny one; assert the big packet's rows are all present.

## F19. clearSyncFolder deletes packets peers have not imported yet, and Syncthing propagates the deletion

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: correctness | invariant: 1
- site: `my_budget_client/lib/core/sync/sync_service_io.dart:193`

**Failure scenario.** A exports packet P and marks its sync_log rows exported, so A has no record of those changes left to re-send. Syncthing replicates P into the shared folder on A, B and C. B is powered off. On A the user taps 'Clear sync folder': clearSyncFolder deletes every *.sync file, including P and including any peer packet A itself has not imported yet (the loop filters only on the .sync extension - it does not consult sync_processed_files). Syncthing propagates those deletions, so P disappears from B's folder before B ever ran an import. B never receives A's changes and nothing on A will ever produce them again: the two devices are permanently divergent with no error shown anywhere.

**Evidence.** lines 188-199: `for (final entity in entities) { if (entity is File && entity.path.endsWith('.sync')) { await entity.delete(); deletedCount++; } }` - no check against `_db.syncProcessedFilesDao.isProcessed(name)` and no check that the file is one this device wrote.

**Fix sketch.** Delete only files this device can prove are consumed: own files (packet/file-name device id == _localDeviceId, which the export path could record as processed) and peer files with a sync_processed_files row. Skip and count the rest, returning the deleted count as the UI already expects.

**Test sketch.** Test 'clearSyncFolder leaves un-imported peer packets alone': drop a peer .sync file into the folder without importing it, call clearSyncFolder(), assert the file still exists and the returned count excludes it; then drop a second peer file, importNow() it, call clearSyncFolder() and assert that one is gone.

## F20. Reconnect backoff resets on any completed handshake, so a flapping server is retried once a second forever

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: performance | invariant: perf target "No redundant round trips" (a sync per reconnect); reconnect storm
- site: `my_budget_client/lib/core/services/server_sync_service.dart:326`

**Failure scenario.** `_reconnectAttempts = 0` runs as soon as `_channel!.ready` completes — i.e. as soon as the WebSocket handshake succeeds, not once the connection has proved durable. A server that accepts the upgrade and then drops the socket (restart loop, container being rolled, proxy with a short idle policy, backend killed after the upgrade) gives: ready completes -> attempts reset to 0 -> `unawaited(sync())` fires a full pull -> onDone -> `_scheduleReconnect()` computes `exponent = 0` -> ~1.0-1.3 s -> reconnect -> ready completes -> reset. The exponential backoff at line 358-363 can never advance past its first step, so the client hammers the server at ~1 Hz indefinitely and issues one HTTP pull per second alongside it. The doc comment claims awaiting `ready` is what makes the reset mean "we are connected", but a connection that lives 20 ms satisfies it.

**Evidence.** await _channel!.ready;            // line 324
debugPrint('[WS_CLIENT] Stream listener registered, connection active');
_reconnectAttempts = 0;           // line 326
...
unawaited(sync().catchError(...));  // line 332 — one full sync per handshake
// _scheduleReconnect, line 358:
final exponent = _reconnectAttempts.clamp(0, 6);

**Fix sketch.** Reset the counter only once the connection has been up for a stability window: after `ready`, start a `Timer(const Duration(seconds: 30), () => _reconnectAttempts = 0)` held in a field and cancelled in onDone/onError/stop(); or reset on the first non-pong frame received. Likewise gate the catch-up `sync()` so it does not fire more often than the backoff floor.

**Test sketch.** Inject a fake channel factory whose `ready` completes and whose stream closes immediately. Drive 5 reconnect rounds with FakeAsync and assert the scheduled delays grow (1s, 2s, 4s, 8s, 16s). Today all five are ~1s.

## F21. Nothing shuts the service down when server sync is turned off — socket, timers and DB listener run for the rest of the session

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: performance | invariant: none (resource/idle-work leak); stop() is dead code
- site: `my_budget_client/lib/core/services/server_sync_service.dart:354`

**Failure scenario.** `stop()` (line 389) and `dispose()` (line 418) have no caller anywhere in lib/ — sync_settings_screen's `_toggleServer(false)` only writes `server_sync_enabled=false`. Nothing else re-reads that flag on the background paths: `_scheduleReconnect` -> `_connectWebSocket` never calls `_isEnabled()` (only the public `initWebSocket` does, line 214), `_periodicSyncTimer` keeps firing every 5 minutes (line 557), and `_dbSubscription` keeps starting a 500 ms debounce timer on every local write (line 481-551). So after the user switches server sync off, the app keeps a token-authenticated WebSocket open and reconnecting to the server forever, answers every `sync_available` doorbell, and burns a DB read (`_isEnabled`) plus a timer for every single row the user edits — until the process dies. If the user edits the server URL, the live socket also stays pinned to the old host, since nothing tears it down. Presentation is out of scope, so the fix has to live in this service.

**Evidence.** void _scheduleReconnect() {
    if (_isDisposed || _reconnectScheduled) return;   // line 355 — no _isEnabled() check
...
_periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) async { ... await sync(); ... });  // line 557
// stop() at line 389: zero call sites in lib/

**Fix sketch.** Make the service self-quiescing: in `sync()`'s disabled branch (line 165-171) call `stop()` before returning, and re-check `_isEnabled()` at the top of `_connectWebSocket` (not just `initWebSocket`) so a scheduled reconnect for a disabled service tears down instead of dialling.

**Test sketch.** Enable sync, `await service.initAutoSync()`, then set `server_sync_enabled='false'` and `await service.sync()`. Assert that a subsequent local DB write produces no HTTP request within 2 s of fake-async time and that the periodic timer is gone (expose it via a @visibleForTesting getter or assert `pumpEventQueue` leaves no pending timers).

## F22. A row whose modified_at is NULL can never be updated again — every later push is silently accepted and discarded

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: correctness | invariant: 1 (convergence) and 5 (no silent data loss) — the push is answered 200, the client drains the queue entry, and the write is gone
- site: `my_budget_server/lib/data/sync_repository.dart:519`

**Failure scenario.** `modified_at BIGINT DEFAULT 0` only applies when the column is omitted; the upserts always name it, so an explicit NULL parameter is written as NULL. An older client — one from before the `ALTER TABLE currencies ADD COLUMN IF NOT EXISTS modified_at` migration that database_client.dart:70 still carries, i.e. exactly the backward-compat case the constraints require to keep working — pushes `{'currencies':[{'code':'EUR','name':'Euro'}]}`. `row['modifiedAt']` is null, the INSERT stores `modified_at = NULL`. From that moment `EXCLUDED.modified_at > currencies.modified_at` evaluates to NULL for every subsequent push, which is not TRUE, so the ON CONFLICT branch never fires. A current client renames that currency at modifiedAt = 1 700 000 000 000, pushes, gets `{'success': true}` (push/index.dart:43), and `_drainPushQueue` deletes the queue entry (server_sync_service.dart:1017-1027). The rename is lost. Because no UPDATE happened, the `sync_stamp_server_seq` trigger never fires either, so `server_seq` does not move and no device ever pulls the row again — the frozen value is permanent and invisible. The same holds for all 21 `WHERE EXCLUDED.modified_at >` sites (lines 221-970).

**Evidence.** WHERE EXCLUDED.modified_at > currencies.modified_at   // line 519
...
await session.execute(Sql.named(sql), parameters: {
  ...
  'modifiedAt': row['modifiedAt'],   // line 527 — null in, NULL stored, DEFAULT 0 bypassed
});

**Fix sketch.** Normalise on the way in — `int _modifiedAt(Object? v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0)` — and bind that everywhere instead of `row['modifiedAt']`, so a missing field means 0 (loses every comparison) rather than NULL (wins none and blocks all). Belt and braces: make the predicate NULL-safe, `EXCLUDED.modified_at > COALESCE(t.modified_at, 0)`, and add `ALTER TABLE t ALTER COLUMN modified_at SET NOT NULL` after a `UPDATE t SET modified_at = 0 WHERE modified_at IS NULL` backfill in `_ensureServerSeq`.

**Test sketch.** sync_repository_test.dart: `await repository.upsertBatch({'currencies':[{'code':'EUR','name':'Euro'}]})` (no modifiedAt key) and assert `recorder.withKey('code')!['modifiedAt']` is `0`, not null. Fails today (it is null), passes after the coercion.

## F23. Fields absent from a push are written as NULL/false and overwrite the stored value — an old client erases exact minor units for every device

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: correctness | invariant: 10 (money survives the round trip) and the backward-compatibility constraint — an old client must keep syncing against a new server without corrupting it
- site: `my_budget_server/lib/data/sync_repository.dart:568`

**Failure scenario.** `amount_minor`/`fee_minor`/`balance_minor` are columns the server itself added by migration (database_client.dart:161-166), which is proof that clients predating them exist. Such a client pushes an edited transaction: the JSON has no `amountMinor` key, `_minorUnits(null)` returns null, and the statement executes `amount_minor = EXCLUDED.amount_minor` — i.e. NULL — because the SET list is unconditional. Server row for transaction t1 goes from `amount_minor = -2550` to NULL. Every current device then pulls `amountMinor: null` and stores NULL locally (server_sync_service.dart:1602-1620). By the codebase's own contract ("NULL marks a row whose value is not expressible in minor units (crypto/commodity), where the double column is authoritative", sync_repository.dart:1035-1037) that fiat transaction has silently been reclassified as non-fiat, and all later arithmetic falls back to the 8-decimal double, permanently. The same shape applies to every boolean: `row['isDeleted'] is bool ? ... : (row['isDeleted'] == 1)` turns an absent key into `false`, so a push from a client that does not know `is_deleted` clears a tombstone the rest of the fleet has agreed on (invariant 3).

**Evidence.** 'amountMinor': _minorUnits(row['amountMinor']),   // line 568 — absent key -> null
'feeMinor': _minorUnits(row['feeMinor']),         // line 576
...
amount_minor = EXCLUDED.amount_minor,             // line 548 — unconditional overwrite
'isDeleted': row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),  // line 580-581 — absent -> false

**Fix sketch.** Distinguish "absent" from "explicitly null" using `row.containsKey(...)`. Simplest form that keeps one statement per batch: bind a companion `@hasAmountMinor` boolean and write `amount_minor = CASE WHEN @hasAmountMinor THEN EXCLUDED.amount_minor ELSE transactions.amount_minor END` (same for fee_minor, balance_minor, is_deleted and the other booleans). Backward compatible in both directions: a payload that carries the key behaves exactly as today.

**Test sketch.** sync_repository_test.dart: seed the recorder, push `txRow()` with the `amountMinor`/`feeMinor` keys *removed* from the map (not set to null), and assert the emitted parameters mark them as absent (`params['hasAmountMinor'] == false`) rather than binding null into an unconditional SET. Pair it with an integration-style assertion that a second push without the key leaves the previously stored -2550 in place.

## F24. Last-write-wins has no tiebreak on equal modified_at, so a tie leaves two devices permanently divergent and silent

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: correctness | invariant: 2 (deterministic conflict resolution: "ties broken by a stable rule (device id), never by arrival order") and 1 (convergence)
- site: `my_budget_server/lib/data/sync_repository.dart:561`

**Failure scenario.** Devices A and B both edit transaction t1 in the same millisecond, so both stamp `modifiedAt = M` (A writes description 'coffee', B writes 'cafe'). A pushes first: server stores A's version at M and bumps server_seq to S. B's cycle runs pull-then-push (server_sync_service.dart:192-193). Pull hands B the server row at M; B's local upsert uses the same strict `WHERE EXCLUDED.modified_at > transactions.modified_at`, so `M > M` is false and B keeps 'cafe'. B then pushes 'cafe' at M; the server's `M > M` is false too, so the row is not touched, `server_seq` is not bumped, and push/index.dart:43 answers `{'success': true}` — B's queue entry is drained. Steady state: server and A show 'coffee', B shows 'cafe', neither will ever be handed the other's version again (server_seq never moved past B's cursor), and nothing anywhere reports a conflict. Ties are not exotic here: `modifiedAt` also collapses to constants on paths that default it (`json['modifiedAt'] as int? ?? 1` on the client, `DEFAULT 0` on the server), so whole seeded tables can share one value.

**Evidence.** WHERE EXCLUDED.modified_at > transactions.modified_at   // line 561; identical at 221, 272, 317, 389, 452, 472, 497, 519, 606, 643, 689, 724, 749, 778, 809, 840, 870, 900, 933, 970 — device_id is written but never compared

**Fix sketch.** Make the predicate total by falling back to the stable device id already stored on every row: `WHERE EXCLUDED.modified_at > t.modified_at OR (EXCLUDED.modified_at = t.modified_at AND COALESCE(EXCLUDED.device_id,'') > COALESCE(t.device_id,''))`. Mirror the identical clause in the client's pull upserts so both ends pick the same winner independently. Purely additive to the predicate; no wire or schema change.

**Test sketch.** sync_repository_test.dart, new group 'a tie is broken by device id, not arrival order': push txRow(deviceId:'dev-b', description:'cafe', modifiedAt: M) then txRow(deviceId:'dev-a', description:'coffee', modifiedAt: M), and the reverse order, asserting the emitted statement's predicate admits the higher device id in both orders (or, in the route-level integration test, that the stored description is the same in both orderings). Fails today — arrival order decides.

## F25. Server pull re-sends every untruncated table's whole delta on every page

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: performance | invariant: Perf targets: "No redundant round trips" and "full pull of the seeded budget" wall time
- site: `my_budget_server/lib/data/sync_repository.dart:1284`

**Failure scenario.** Each table is read with its own `LIMIT`, then any truncated table pins the shared cursor to the minimum truncated cursor — but the rows the untruncated tables already returned are still shipped, even though they sit above that cursor and will be returned again next page. Server with 283,000 exchange rates (server_seq 1..283000) and 5,000 transactions (seq 283001..288000), limit 5,000: page 1 returns rates 1..5000 (hitLimit, cursor 5000) plus all 5,000 transactions (seq > 0, not truncated); nextCursor = 5000. Pages 2..57 repeat the identical 5,000 transactions because their seqs are still above the pinned cursor. That is 57 x 5,000 = 285,000 transaction rows serialised, transferred and upserted instead of 5,000 — a 57x amplification that also runs `_accountIdsOfTransactions` and `recomputeBalances` 57 times over the same accounts. After the fix each row crosses the wire exactly once.

**Evidence.** if (result.hitLimit) {
  hasMore = true;
  if (truncatedCursor == null || result.cursor < truncatedCursor) truncatedCursor = result.cursor;
}
…
final nextCursor = truncatedCursor ?? maxSeq;   // rows above nextCursor were already put into `changes`

**Fix sketch.** Compute `truncatedCursor` first, then drop rows with `serverSeq > truncatedCursor` from every table's list before building `changes` (and skip the table entirely if nothing remains). Wire format is unchanged — the client just receives the prefix it is allowed to advance past.

**Test sketch.** `test/data/sync_repository_test.dart`: insert 3 exchange rates then 1 transaction (so seqs are 1,2,3,4); `getChanges(0, limit: 2)` must return exactly 2 exchange rates, no `transactions` key, cursor 2, hasMore true; `getChanges(2, limit: 2)` returns rate 3 + the transaction. Today the first call also returns the transaction that the second call returns again.

## F26. P2P import trims the conflict table once per change, loading it whole into memory each time

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: performance | invariant: Perf targets: "Work per synced row is O(1) statements" and "nothing loads a whole table into a list to sync it"
- site: `my_budget_client/lib/core/sync/sync_service_io.dart:637`

**Failure scenario.** `_applyChange` ends with `clearOldConflicts(100)`, and that DAO runs `SELECT * FROM conflict_history ORDER BY rejected_at DESC` with no LIMIT and materialises every row — including each row's full `rejected_data` JSON — into a Dart list just to compute `all.skip(100)`. Importing one .sync packet of 20,000 changes therefore issues 20,000 unbounded SELECTs plus up to 20,000 DELETEs and reads ~2.02 million rows (101 per call) to delete at most one row per call. None of it is inside a transaction — `_processFile` only toggles `PRAGMA foreign_keys` around the loop (line 475-485) — so every one of those statements is its own implicit commit, on top of the 2-4 statements `_applyChange` already issues per change. After the fix: 1 statement per packet, ~100 rows read.

**Evidence.** await _db.conflictHistoryDao.clearOldConflicts(maxConflictHistory);   // sync_service_io.dart:637, inside the per-change path
// app_database.dart:5142  final all = await (select(conflictHistory)..orderBy([(t) => OrderingTerm.desc(t.rejectedAt)])).get();

**Fix sketch.** Move the call out of `_applyChange` to once after the `for (final change in packet.changes)` loop in `_processFile`, and rewrite the DAO as a single `DELETE FROM conflict_history WHERE id NOT IN (SELECT id FROM conflict_history ORDER BY rejected_at DESC LIMIT ?)`. While there, wrap the change loop in `_db.transaction(...)` so the packet commits once instead of ~4N times.

**Test sketch.** Import a synthetic packet of 200 conflicting changes through a QueryExecutor proxy that counts statements touching `conflict_history`; assert at most one SELECT and one DELETE. Fails today (200 of each).

## F27. asset_entries dedup DELETE binds `source` as a parameter, so the partial index cannot be used

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: performance | invariant: Perf target: "Every hot predicate the sync paths use is index-covered — verified with EXPLAIN QUERY PLAN in a test"
- site: `my_budget_client/lib/core/services/server_sync_service.dart:1662`

**Failure scenario.** The only index on asset_entries besides the PK is the partial `idx_asset_entries_custom_api_dedup ON asset_entries (asset_id, date, source) WHERE source = 'custom_api'`. SQLite can only use a partial index when the query's WHERE provably implies the index's WHERE, which a bound parameter never does. Verified on the real schema with sqlite3 3.44: `DELETE FROM asset_entries WHERE source = ? AND asset_id = ? AND date = ? AND id != ?` -> `SCAN asset_entries`, while the identical statement with the literal `source = 'custom_api'` -> `SEARCH asset_entries USING INDEX idx_asset_entries_custom_api_dedup (asset_id=? AND date=? AND source=?)`. The branch has already tested `source == 'custom_api'` on line 1659, so the literal is provably correct. A pull page of 5,000 custom_api asset entries against a 60,000-row asset_entries table costs 5,000 full scans = 300 million row reads inside the pull transaction; after the fix, 5,000 index seeks.

**Evidence.** if (source == 'custom_api' && id.isNotEmpty) {
  …
  'DELETE FROM asset_entries '
  'WHERE source = ? AND asset_id = ? AND date = ? AND id != ?',
  variables: [drift_db.Variable.withString(source), …]

**Fix sketch.** Inline the constant the branch has already proven: `WHERE source = 'custom_api' AND asset_id = ? AND date = ? AND id != ?`, dropping the first bound variable. (Combine with finding #1 by hoisting the dedup into one `DELETE … WHERE (asset_id, date) IN (VALUES …) AND id NOT IN (…)` per chunk.)

**Test sketch.** `customSelect("EXPLAIN QUERY PLAN DELETE FROM asset_entries WHERE source = ? AND asset_id = ? AND date = ? AND id != ?")` on a migrated database and assert the plan contains `idx_asset_entries_custom_api_dedup`. Fails today (`SCAN asset_entries`).

## F28. Enum indices from the wire are used as unchecked list indices, so an out-of-range value throws RangeError out of the packet loop

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: correctness | invariant: 9 (hostile packet must be rejected, not kill the apply loop); 10 (enum encoded as index)
- site: `my_budget_client/lib/core/sync/sync_service_io.dart:1742`

**Failure scenario.** `_categoryToJson` writes `c.type.index` and `_categoryFromJson` reads it back as a raw index. A peer on a NEWER build that has added a fourth CategoryType, or a corrupt/hostile packet, sends `{'id':'c1','name':'X','type':99,'modifiedAt':5}`. `CategoryType.values[99]` throws RangeError inside `_insertRecord`, which propagates to `_processFile`'s catch and aborts the whole packet mid-way (see the partial-apply finding above). The same unchecked indexing is used for `TypeCurrency.values[json['type']]` (line 1771) and `IconType.values[json['iconType']]` (line 1796). This is exactly the failure mode `SyncTableId.fromValue` / `SyncAction.fromValue` were made total to avoid (sync_binary_format.dart:33 and :51) — the packet-level enums were hardened, the payload-level ones were not. Negative values (`'type': -1`) throw too.

**Evidence.** my_budget_client/lib/core/sync/sync_service_io.dart:1742  `type: Value(CategoryType.values[(json['type'] as int?) ?? 0]),`  — plus line 1771 `TypeCurrency.values[(json['type'] as int?) ?? 0]` and line 1796 `IconType.values[(json['iconType'] as int?) ?? 0]`. Contrast sync_binary_format.dart:27-38, whose doc-comment states the rule: "Wire values are append-only, so a newer peer can send an id this build has never heard of. Throwing here ... failed the decode of the whole packet."

**Fix sketch.** Add a bounds-checked helper mirroring `SyncTableId.fromValue`, e.g. `T _enumAt<T>(List<T> values, Object? raw, T fallback) => (raw is int && raw >= 0 && raw < values.length) ? values[raw] : fallback;` and use it at all three sites (falling back to index 0, which is what a missing key already yields).

**Test sketch.** test/core/sync/sync_service_malformed_input_test.dart: import a packet containing a categories upsert with `'type': 99` and a styles upsert with `'iconType': -1`; assert `importNow()` completes and that a valid change placed after them in the same packet was applied. Both throw RangeError today.

## F29. An upsert change carrying no payload dereferences a null with `!`, aborting the packet

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: correctness | invariant: 9 (malformed input fails closed)
- site: `my_budget_client/lib/core/sync/sync_service_io.dart:609`

**Failure scenario.** The binary format explicitly permits a change with `DATA_LEN = 0` for any action — `encode` writes the zero-length block unconditionally (sync_binary_format.dart:135-141) and `decode` leaves `data == null` when `dataLen == 0` (line 216-221). A peer that hits the exporter's race (a row deleted between logging and export) is supposed to skip such a change, but a corrupt or hostile file can carry `action = upsert, dataLen = 0`. `_applyChange` then reaches `await _insertRecord(change.tableId, change.data!)` and throws `Null check operator used on a null value`, killing the rest of the packet and leaving everything before it committed. Same `!` on the update branch at line 622 for a record that already exists locally with an older modifiedAt. Note that `incomingModifiedAt` for such a change is 0 (line 517), so the update branch is only reachable when the local row has a negative clock — but the insert branch at 609 is reached for any record this device has not seen, which is the common case for a hostile packet.

**Evidence.** my_budget_client/lib/core/sync/sync_service_io.dart:609  `await _insertRecord(change.tableId, change.data!);` and line 622 `await _updateRecord(change.tableId, change.data!);` — while `SyncChange.data` is declared nullable and documented as "A delete has no row left to describe" (sync_binary_format.dart:63-68), with nothing between decode and here validating that an upsert has one.

**Fix sketch.** At the top of `_applyChange`, after the delete branch: `final data = change.data; if (data == null) { debugPrint('[SYNC_DEBUG] Upsert with no payload for ${change.tableId.name}:${change.recordId} (skipping)'); return; }` and use `data` at both call sites.

**Test sketch.** test/core/sync/sync_service_malformed_input_test.dart: `SyncBinaryFormat.encode(deviceId: 'device-peer', timestamp: 1, changes: [SyncChange(tableId: SyncTableId.styles, recordId: 's-x', action: SyncAction.upsert, data: null), SyncChange(... a valid style s-y ...)])`; assert `importNow()` completes AND that s-y was applied. Today the first change throws and s-y never lands.

## F30. Invariant 6 and invariant 4 are unpinned on the client pull: no test for a page that fails mid-apply, or for the same page applied twice

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: test-gap | invariant: 6 (atomic batches / cursor only advances past a committed page) and 4 (replay is idempotent)
- site: `my_budget_client/test/core/sync/server_sync_service_test.dart:168`

**Failure scenario.** The `pull cursor` group only ever serves pages that apply cleanly; the cursor is asserted on the happy path (`resumes from the stored sequence`, `follows the sequence across pages`) and on a non-advancing-cursor guard. Nothing serves a page whose second table throws (a transaction row referencing a category id whose parse fails, a malformed `modifiedAt`, or a mid-batch DB error), so nothing proves that (a) the rows from the first table are rolled back, (b) `serverPullCursorKey` is *not* written, and (c) the next `sync()` re-requests the same `last_sync`. Regressing `_applyChanges` back to one transaction per table — the exact bug its own comment at server_sync_service.dart:1059-1064 says was fixed — would keep the entire client suite green while silently losing every table after the failure point. Likewise nothing applies an identical page twice to prove no row is duplicated and no queue entry is left behind. Server-side atomicity *is* pinned (my_budget_server/test/data/sync_repository_test.dart:199 'runs inside a transaction, not a bare connection'; :491 'every table is read inside one locked transaction'); the client half is not.

**Evidence.** lib/core/services/server_sync_service.dart:670-673 `await _applyChanges(changesMap);` immediately followed by `await prefs.setInt(lastSyncKey, serverTimestamp);` — the ordering that makes the invariant true, with no test that would fail if the two lines were swapped or if `_applyChanges` stopped being a single `_database.transaction`. test/core/sync/server_sync_service_test.dart:168-341 contains no failing-apply case.

**Fix sketch.** No production change needed — the code is already correct; add the tests that would fail if it regressed. The suite already has the mock-server scaffolding (`pages`, `pulls`, `MockClient`) to serve a poison page.

**Test sketch.** Two tests in the `pull cursor` group. (1) `test('a page that fails half way applies nothing and leaves the cursor put')`: serve `page(serverTimestamp: 7, hasMore: false, styles: [style('s1')], transactions: [ {..., 'date': 'not-a-date'} ])` such that the transactions upsert throws; `await expectLater(service.sync(), throwsA(isA<Exception>()))`; assert `await db.stylesDao.getStyleById('s1')` is null and `prefs.getInt(serverPullCursorKey)` is unchanged; then serve a clean page and assert the next pull asks for the same `last_sync`. (2) `test('applying the same page twice changes nothing')`: serve the identical page on two consecutive `sync()` calls with the cursor forced back, assert row counts per table and `SELECT COUNT(*) FROM sync_push_queue` are identical after the second apply. Both fail if `_applyChanges` loses its single transaction or if the cursor write moves before it.

## F31. sync_log_coverage_test's CategoriesDao tests share one database and chain on each other — they fail under any reordering

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: medium
- kind: test-gap | invariant: none (test hygiene; it is the demonstrable shared-state leak in the sync test set)
- site: `my_budget_client/test/core/database/sync_log_coverage_test.dart:83`

**Failure scenario.** `flutter test --test-randomize-ordering-seed=random` fails 2 out of 2 runs (seeds 3030328229 and one other) with `Null check operator used on a null value` on 'CategoriesDao updateCategory logs an additional upsert row' and 'CategoriesDao deleteCategory logs a delete row'. Cause: the file opens ONE `AppDatabase` in `setUpAll` (line 57) and never resets it between tests, and the three CategoriesDao tests are a chain — `insertCategory` creates `sl_cat_1`, `updateCategory` does `getCategoryById('sl_cat_1')` then `cat!`, `deleteCategory` does the same. Run them in any order but declaration order and the `!` throws. Worse for the goal's purposes, `updateCategory` asserts `logs.where((l) => l.action == 'upsert').length == 2`, a count that is only correct if exactly one prior test in the file wrote to that record — so adding any new categories test above it silently breaks it. These are the sync bookkeeping tests the goal depends on; a suite that only passes in declaration order is not a gate.

**Evidence.** test/core/database/sync_log_coverage_test.dart:57 `db = AppDatabase.forTesting(NativeDatabase.memory());` inside `setUpAll` (no per-test reset, `tearDownAll` only closes at :66). Then :84 `final cat = await db.categoriesDao.getCategoryById('sl_cat_1'); await db.categoriesDao.updateCategory(cat!.toCompanion(true)...)` and :89 `expect(logs.where((l) => l.action == 'upsert').length, 2);` — both depend on the test at :70 having run first.

**Fix sketch.** Make each test self-contained without giving up the shared database: give every test its own record id (`sl_cat_update`, `sl_cat_delete`), have each one insert the row it is about, and assert on the *delta* in `logsFor(...)` rather than an absolute count that encodes how many earlier tests touched the row. Alternatively move the db construction into `setUp`/`tearDown`; `flutter_test_config.dart` already turns the 283k-row exchange-rate seed off, so per-test construction is cheap. Same audit is due for the other groups in this file and for sync_log_drain_test.dart, which uses the same setUpAll shape.

**Test sketch.** The gate itself is the test: `flutter test test/core/database/sync_log_coverage_test.dart --test-randomize-ordering-seed=12345` fails before the fix (`Null check operator used on a null value`) and passes after, for every seed.

## F32. sync_push_queue is never drained while server sync is disabled, so it grows for the life of the install

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: low
- kind: performance | invariant: none (unbounded growth of sync_push_queue); also makes getPendingChangesCount() a growing full SCAN
- site: `my_budget_client/lib/core/services/server_sync_service.dart:165`

**Failure scenario.** The push-queue triggers are unconditional — they fire on every insert and every modified_at-changing update of the 16 synced tables regardless of whether server sync is on — but the only code that deletes from the table is `_drainPushQueue`, reachable only through `_push()`, which `sync()` never reaches when `server_sync_enabled != 'true'` (line 165). A user on P2P-only sync, or on no sync at all, therefore accumulates one row per write forever: the daily exchange-rate auto-fetch alone writes a few hundred rates per day (~70 k queue rows a year), a CSV rate import adds one per imported row, and the v12->v13 migration seeds one per existing row up front. Nothing ever reads or removes them. `getPendingChangesCount()` (line 585) then runs `SELECT DISTINCT changed_table_name, record_key` over that table — a full SCAN plus a temp B-tree, since idx_sync_push_queue_table is (changed_table_name, id) — every time the sync screen refreshes.

**Evidence.** Future<void> sync() async {
    if (!await _isEnabled()) {   // line 165
      ...
      return;                    // the only path to _drainPushQueue is behind this
    }
// app_database.dart:3946 — triggers are created for every synced table, unconditionally

**Fix sketch.** Either bound the queue when the feature is off (in the disabled branch, `DELETE FROM sync_push_queue` once — the v13 seeding logic already re-derives a full backlog if the user later enables server sync, or re-seed on enable), or trim it opportunistically (`DELETE FROM sync_push_queue WHERE id <= (SELECT MAX(id)-N …)`) while server sync has never been enabled. Add `record_key` to the index so the pending count is index-covered.

**Test sketch.** With `server_sync_enabled='false'`, write 100 rows through the DAOs, call `service.sync()`, and assert `SELECT COUNT(*) FROM sync_push_queue` is bounded (0, or a documented cap) rather than 100.

## F33. /api/sync/full reports has_more on an endpoint that has no way to page

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: low
- kind: correctness | invariant: none directly; it is a dead-end API contract that hands out a silently partial database
- site: `my_budget_server/routes/api/sync/full/index.dart:17`

**Failure scenario.** The comment on line 16 says "0 implies fetch everything from the beginning of time", but `getChanges(0)` runs with the default `limit: 5000` (sync_repository.dart:1053), so on the seeded budget the response carries 5 000 of the 283 000 exchange_rates and `has_more: true`. The route deliberately ignores a caller-supplied `last_sync` — pinned by test/routes/api/sync/full_test.dart:57 — so there is no parameter a caller can vary to get page 2; calling /full again returns byte-identical page 1 forever. A caller that trusts the endpoint name and the `has_more` flag either loops forever on the same page or stops with 5 000 rows and believes it has the whole budget. (The Flutter client is unaffected: it only ever calls /pull and /push.)

**Evidence.** // 0 implies fetch everything from the beginning of time
final result = await repo.getChanges(0);   // line 17 — default limit 5000
...
'has_more': result.hasMore,                // line 22 — true, with no cursor input to advance

**Fix sketch.** Either drop `has_more` from /full and pass a limit that really means everything, or document/return the continuation explicitly: keep `server_timestamp` as the cursor and state in the response (and the route doc) that continuation is `/api/sync/pull?last_sync=<server_timestamp>`. Cheapest correct option given no client depends on it: delete the route, or make it a thin 302/alias of /pull?last_sync=0.

**Test sketch.** test/routes/api/sync/full_test.dart: stub the repository to report `hasMore: true`, call the route twice, and assert the two responses are not identical (i.e. the second call advances). Fails today; passes once /full either pages or stops claiming there is more.

## F34. _round() to 8 decimals turns any exchange rate below 5e-9 into exactly 0.0 on the server path only

- status: UNVERIFIED (reported by one auditor, not re-checked)
- severity: low
- kind: correctness | invariant: 10 (money survives the round trip)
- site: `my_budget_client/lib/core/services/server_sync_service.dart:1973`

**Failure scenario.** A rate for a hyperinflated-or-crypto pair, e.g. from=IRR to=BTC at 2.4e-10, is stored locally with full double precision. The P2P path ships it verbatim (`'rate': r.rate`, sync_service_io.dart:1930). The server path does not: `_exchangeRateToJson` sends `_round(e.rate)` = `double.parse((2.4e-10).toStringAsFixed(8))` = `double.parse('0.00000000')` = **0.0**, and the server independently re-rounds on ingest (`_round`, sync_repository.dart:1026) and the client re-rounds on apply (`_round((json['rate'] as num?)?.toDouble() ?? 1.0)`, server_sync_service.dart:1863). The row lands on every other device with rate 0.0. Any conversion through that pair then yields 0 (or a division by zero if the inverse is taken), and because the pulled row carries the newer modified_at it overwrites the correct local value. The same clamp applies to `assetQuantity` (line 1234) for a fractional crypto holding below 5e-9. The two sync paths therefore disagree about the same row's value, so a device on both paths flip-flops.

**Evidence.** my_budget_client/lib/core/services/server_sync_service.dart:1973-1975  `double _round(double value) { return double.parse(value.toStringAsFixed(8)); }`, called at line 1328 `'rate': _round(e.rate)` and line 1863 on apply; versus my_budget_client/lib/core/sync/sync_service_io.dart:1930 `'rate': r.rate` with no rounding. The `_round` doc-comment ("round double values to 8 decimal places to avoid floating point errors") does not acknowledge the sub-1e-8 case.

**Fix sketch.** Leave values that would round to zero alone: `double _round(double v) { if (v == 0 || v.abs() < 1e-8) return v; return double.parse(v.toStringAsFixed(8)); }` — and mirror the same guard in my_budget_server `_round` so the server does not re-clamp what the client preserved. Rates are not money in minor units, so 8-dp normalisation should never be able to erase a nonzero value.

**Test sketch.** test/core/sync/sync_service_minor_units_test.dart: insert an exchange rate with `rate: 2.4e-10`, run the push serialiser, and expect `pushed['rate']` to equal `2.4e-10` (fails today with 0.0); then feed that payload to `_upsertExchangeRate` and expect the stored rate to still be `2.4e-10`. Add the mirror assertion in my_budget_server/test/data/sync_repository_test.dart for the server's `_round`.

## Refuted

- **"Clear my data" wipes the settings table, rotating local_device_id, so the device re-imports its own historical .sync files and refills itself** (`my_budget_client/lib/core/database/app_database.dart:4686`) — The device-id rotation is real (app_database.dart:4686 wipes settings, 4463-4472 mints a new UUID) and own packets are indeed re-read after a clear + re-enable, but the claimed resurrection is blocked by a guard on the very same path that the finding does not account for: clearAllData writes delete tombstones for every wiped id into sync_log (app_database.dart:4727-4751), and _exportPendingChanges writes them out under the STILL-CACHED old device id (sync_service_io.dart:251/355/364 use the in-memory _localDeviceId and _syncFolderPath, never re-read from settings), fired by the 30s batchInterval timer (line 35) or by the pause/detach export in app_wrapper.dart:50. getPendingChanges (app_database.dart:5075) has no LIMIT, so all tombstones go out in one packet. That packet is never marked processed (own-file check at line 457 returns before markProcessed), so after the id rotates it is imported like a peer's — the same rotation the claim depends on is what makes the device replay its own clear. Both file orders are covered: a stale upsert that resurrects a row is then soft-deleted because deleteTimestamp (clear time) > localModifiedAt (line 543), and a tombstone that lands first writes an is_deleted=1 row via _insertTombstone (line 580) so every later stale upsert loses at lines 589-593. sms_presets cannot resurrect at all (no case in _insertRecord's switch, default: break). Only exchange_rates/inflation_rates get no tombstones, and they are reseeded from the bundle and resolved last-write-wins, so the harm there is nil. A genuine but narrow residual remains: if no export runs at all in the session that cleared (process killed before the timer tick and before the fire-and-forget detach export completes, or startSync had previously failed so _syncFolderPath is null and line 251 skips the export), the tombstones are exported later under the new id and skipped locally at line 457, leaving the stale upserts applied. That is a timing race, not the plainly reachable 'every pre-clear account, transaction, category and asset entry is re-inserted' walk that was claimed.
## F35. A row edited in the same millisecond it was last written is never queued for push

- status: CONFIRMED (reproduced while verifying round 1)
- severity: high
- kind: correctness | invariant: 5 (no silent data loss)
- site: `my_budget_client/lib/core/database/app_database.dart` (the `trg_push_queue_<table>_update` triggers)

**Failure scenario.** The update trigger fires only `WHEN NEW.modified_at IS NOT OLD.modified_at`. Every writer
stamps `modified_at` with `DateTime.now()`, so an edit that lands in the same millisecond as the row's previous
write leaves the stamp unchanged and NO queue entry is made: the edit is on the device and the server never
hears about it, with nothing in the queue to retry. Observed as
`test/core/sync/sync_service_api_settings_test.dart:300` ("a locally deleted provider is pushed with its
tombstone flag"): the row is seeded during `onCreate` and soft-deleted by the test a fraction of a millisecond
later, and in a full-file run the push sends nothing at all — the tombstone never leaves the device. Passing or
failing is pure timing, which is why it moved when unrelated work changed how long `onCreate` takes.

**Evidence.** `trg_push_queue_<table>_update ... AFTER UPDATE ON <table> WHEN NEW.modified_at IS NOT OLD.modified_at`,
against writers that all stamp `DateTime.now()`. The insert trigger is unconditional; only the update path filters.

**Fix sketch.** Make the update trigger unconditional (queue on every UPDATE). The condition exists to keep a
pull's own writes out of the queue, and F5's fix removes that need: the pull deletes the queue entries its own
transaction created, by id, inside that transaction. Relax the trigger only together with F5, never before it.

**Test sketch.** Write a row, then update it with `modified_at` left at the same value, and assert an entry
appears in `sync_push_queue`. Fails today, passes once the trigger is unconditional.


---

# Resolution log — 2026-08-21

Statuses in the sections above are the *audit's* statuses and are left as written. This is what
actually happened to each finding.

## Fixed and pinned by a test

| # | Where it landed |
|---|---|
| F1 | `sync_service_io.dart` — `_incomingWins`, symmetric `(modifiedAt, deviceId)` order on all three branches |
| F2 | `sync_service_io.dart` — markers pruned by whether the packet is still in the folder, not by a 7-day clock |
| F3 / F13 | `sync_service_io.dart` — one transaction per packet, per-change error isolation, FK pragma hoisted out |
| F4 | `server_sync_service.dart` — the re-entrancy latch is the first statement, before any await |
| F5 / F10 | `server_sync_service.dart` — the pull deletes the queue rows its own transaction created, by id |
| F6 / F9 | `app_database.dart` — `idx_<table>_push_key` expression indexes, schema v14 + migration + plan test |
| F7 / F25 | `sync_repository.dart` — `nextCursor` computed first, every table's slice trimmed to it |
| F8 | `server_sync_service.dart` — chunked multi-row upserts (5 000 rows: 41 statements) |
| F11 | `database_client.dart` — `api_settings.is_deleted` |
| F12 | `sync_repository.dart` — a zone-less date string is bound as a wall clock |
| F17 | `sync_service_io.dart` — balances recomputed after a packet; `openingBalance` travels on the wire |
| F18 | `sync_service_io.dart` — imports serialised through one chain |
| F20 | `server_sync_service.dart` — backoff resets only after 30 s of a stable connection |
| F21 | `server_sync_service.dart` — the service shuts down when server sync is turned off |
| F22 / F24 | both ends — `COALESCE(modified_at, 0)` plus the device-id tiebreak |
| F23 / F26 (server) | `sync_repository.dart` — an absent key is omitted from columns, params and the SET list |
| F26 (P2P) | `sync_service_io.dart` — `conflict_history` trimmed once per packet, not once per change |
| F27 | asset_entries dedup — kept, premise about the partial index refuted; see the agent's note |
| F28 / F29 | `sync_service_io.dart` — out-of-range enum index and zero-length payload are skipped, not thrown |
| F30 | client pull — mid-apply failure and double-apply are pinned by tests |
| F31 | `sync_log_coverage_test.dart` — a fresh database per test |
| F32 | `server_sync_service.dart` — the queue is drained while server sync is disabled |
| F33 | `routes/api/sync/full/index.dart` — a `next` link accompanies `has_more` |
| F34 | both halves — client `ServerSyncService._round` and server `_round` pass values under 1e-8 through untouched, so a 2.4e-10 rate is no longer stored as exactly 0.0 |
| F35 | `app_database.dart` — content-aware `trg_push_queue_<table>_update` triggers, schema v15 + migration + tests |
| — | `app_database.dart` — `clearOldConflicts` is one bounded `DELETE ... WHERE id NOT IN (... LIMIT ?)` instead of reading every `rejected_data` blob into Dart once per imported packet |
| — | `local_inflation_repository_test.dart` — the one v9→v10 test that WRITES builds its own database, so the group no longer depends on its own order |
| F16 | `sync_service_convergence_test.dart` — full two-device dumps under three delivery schedules, now driven by a seeded generator as well as the hand-built script; six seeds x three schedules |
| F36 | `server_sync_service.dart` — `_dedupeCustomApiPage` collapses the `custom_api` duplicates one page can carry, by the same `(modifiedAt, deviceId)` order the SQL guard uses |

## Rejected after re-reading the code

- **F19** — `clearSyncFolder` deleting packets peers have not imported is real as a mechanism, but it
  is a user-initiated action on the user's own folder, not a silent data path.
- **F15** — not a defect to fix; the tie-break test that pinned the wrong rule was replaced when F1 landed.
- **F14** — the reported "ru delete confirmation" flake did not reproduce in six full runs, including
  randomised seeds. The real order-dependent file is `test/data/local_inflation_repository_test.dart:628`.
- ~~**F35**~~ — **the rejection was wrong; the finding is real and is now fixed (v15).** The
  argument above holds only for a row the server ALREADY has, where a same-stamp push loses to the
  stored row on `_lastWriteWins`. It does not hold for a row the server has never seen: that push
  takes the INSERT branch, is accepted, and the edit that would have carried it was the one the
  trigger dropped. That is exactly the shape of the flake — `onCreate` seeds an `api_settings_table`
  row and the test soft-deletes it a fraction of a millisecond later, so `modified_at` never moves,
  nothing is queued, and the tombstone stays on the device. The other half of the argument — that an
  unconditional trigger re-queues every account a balance rebuild touches — is also right, which is
  why the fix is neither the old clause nor no clause but a CONTENT test: the `WHEN` now compares
  every column except `modified_at` and the per-device derived ones
  (`syncPushQueueDerivedColumns`, today `accounts.balance` / `balance_minor`), with `IS NOT` rather
  than `<>` so a value arriving in a NULL column still queues. Columns are read from
  `PRAGMA table_info`, so a column added by a later migration is covered without anyone remembering
  to update a list.

## F38. An edit to a locally tombstoned row raises its clock and exports nothing

- status: CONFIRMED (found by the generated convergence script, seed 7)
- severity: medium
- kind: correctness | invariant: 1 (two devices converge)
- site: `my_budget_client/lib/core/sync/sync_service_io.dart` `_getRecordData` + the DAO update methods

**Failure scenario.** `stylesDao.updateStyle` (and its siblings) happily update a row whose
`is_deleted` is 1, stamping `modified_at` with the edit's clock. The exporter then asks
`_getRecordData` for that row, which returns null for a soft-deleted row, logs
`Data null for styles:<id> (skipping)` and drops the change. The device is left holding a clock no
peer can ever be told about: a legitimate upsert from a peer, stamped between the delete and the
phantom edit, is rejected here and accepted everywhere else, and the two devices never agree again.
The tombstone itself still travels, so the row is deleted on both sides — it is the CLOCK that
diverges, and the clock is what every later comparison is made against.

**Evidence.** Reproduced by the generated script in
`test/core/sync/sync_service_convergence_test.dart` before the generator was taught not to edit
what it has already deleted: device A deleted `s-p1` at 1150 and edited it at 1160, exported, and
the peer landed on 1150 while A sat on 1160. The exporter's own log line names the drop.

**Fix sketch.** Pick one and make it the rule: (a) refuse the update — a DAO update of a
tombstoned row is a bug in the caller; (b) resurrect on an explicit user edit, which is what the
user asked for anyway; or (c) export the row as an upsert carrying `isDeleted: true`, which the
wire format already supports for every table that has the column. (c) is the only one that also
repairs devices already holding a phantom clock.

**Test sketch.** Delete a style, update it without resurrecting, export, and assert the peer's
`modified_at` for that id equals the local one. Fails today at the delete's clock. The generated
convergence script covers the general case once the generator is allowed to make that move again.

## Still open

- `recomputeBalances` / `anchorOpeningBalances` issue per-account `customUpdate`s.
- A device cannot re-export changes it has already exported: `sync_log` rows are marked `exported = 1`
  on the way out and nothing ever resets them, so a peer that lost its copy cannot be re-seeded.
- **F38** above — an edit to a locally tombstoned row.
- Sync timings are still not measured end to end.

## Found by running the app, not by reading it — 2026-08-21

`flutter run -d windows` against the real server and the real `C:\Users\vrclu\Documents\db.sqlite`.

- **F36 — every server-sync cycle aborted on a UNIQUE constraint.** Live log:
  `[ServerSync] Sync cycle error: SqliteException(2067) ... UNIQUE constraint failed:
  asset_entries.asset_id, asset_entries.date, asset_entries.source`, then
  `[StartupSyncService] Server Sync failed: ...`, and the same again on the auto-sync pass. The
  server still holds two `custom_api` entries on one `(asset_id, date)` under different ids — the
  shape `idx_asset_entries_custom_api_dedup` was added in v7 to stop — and sends both in one page.
  The applier's dedup DELETE only evicts rows already in the local database, so the second row of
  the page hit the index, and because a page applies all-or-nothing the device never finished
  another pull. Fixed in `_upsertAssetEntries` by collapsing the page first; three tests in
  `test/core/sync/server_sync_apply_batching_test.dart` cover it, and the first of them reproduces
  the exact live exception when the fix is disabled.
- **F37 — the WebSocket never connects, and no code in this repo can fix it.** Live log:
  `WebSocketException: Connection to 'https://werta.duckdns.org:0/mybudget-sync/ws/sync?...' was not
  upgraded to websocket`, retried with backoff forever. Probing the endpoint directly returns
  `400 Bad Request` from dart_frog — `Invalid WebSocket upgrade request: unexpected HTTP version
  "1.0"` — behind `Server: nginx/1.24.0 (Ubuntu)`. nginx is proxying the upgrade as HTTP/1.0. The
  deployment's `location /mybudget-sync/` block needs:

      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_read_timeout 3600s;

  Until then push/pull over HTTP still works and the app falls back to its periodic timer, so the
  symptom is latency, not data loss.
