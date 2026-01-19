# MyBudget Sync Architecture

## Структура проекта

```
MyBudget/
├── my_budget_client/     # Flutter app
├── my_budget_server/     # Dart Frog + PostgreSQL
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── ...
└── docs/planning/
```

---

## Таблицы для синхронизации

| Sync | Table | Reason |
|:----:|-------|--------|
| ✅ | `transactions` | User data |
| ✅ | `accounts` | User data |
| ✅ | `categories` | User data |
| ✅ | `styles` | User customization |
| ✅ | `exchange_rates` | User can add/edit |
| ✅ | `asset_entries` | User data |
| ✅ | `inflation_rates` | User can add/edit |
| ✅ | `custom_themes` | User customization |
| ✅ | `settings` | User preferences (special handling) |
| ✅ | `sms_presets` | SMS parsing rules (needs migration from SharedPrefs) |
| ✅ | `custom_apis` | Custom API configurations |
| ✅ | `api_settings` | API auto-fetch settings |
| ❌ | `languages` | System data (read-only) |
| ❌ | `currencies` | System data (read-only) |
| ❌ | `currency_designations` | System data |
| ❌ | `account_types` | System data |
| ❌ | `api_fetch_statuses` | Local cache |

### Settings Sync Strategy

```dart
// Settings синхронизируются ВСЕ, но применение — по выбору устройства
class SyncedSettings {
  Map<String, SettingValue> allDeviceSettings;  // Все настройки от всех устройств
  String activeDeviceId;                         // Чьи настройки применены
}

// UI: "Настройки с устройства: [Device A ▼]"
```

---

## Option 1: P2P via Syncthing

### Формат: Binary + Gzip

| Format | 1000 транзакций |
|--------|-----------------|
| JSON | ~100 KB |
| Binary | ~30 KB |
| Binary + Gzip | **~8 KB** |

```dart
// Структура бинарного файла
[HEADER: 4 bytes "SYNC"]
[VERSION: 1 byte]
[DEVICE_ID: 16 bytes UUID]
[TIMESTAMP: 8 bytes int64]
[CHANGE_COUNT: 4 bytes uint32]
[CHANGES: repeated]
  [TABLE_ID: 1 byte enum]
  [RECORD_ID: 16 bytes UUID]
  [ACTION: 1 byte] // 0=upsert, 1=delete
  [DATA_LEN: 2 bytes uint16]
  [DATA: variable MessagePack/CBOR]
```

### Multi-file sync

```
my_budget_sync/
├── device_abc123_1705693200.sync   # Batch 1
├── device_abc123_1705693230.sync   # Batch 2
├── device_xyz789_1705693210.sync   # From other device
└── .processed/                      # Обработанные (для очистки)
    └── device_abc123_1705693200.sync
```

### Настройки очистки (Settings)

```dart
class SyncSettings {
  Duration batchInterval = Duration(seconds: 30);
  Duration keepProcessedFor = Duration(days: 7);
  int maxConflictHistory = 100;  // Или по размеру
  String syncFolderPath;
}
```

### Логика

1. **Изменение** → запись в `sync_log`
2. **Каждые 30 сек** → экспорт накопленных изменений в `.sync` файл
3. **File watcher** → обнаружение новых файлов от других устройств
4. **Merge** → newer wins по `modifiedAt`
5. **Конфликты** → сохраняем в `conflict_history` таблицу

---

## Option 2: Server (Docker Required)

### Stack

| Component | Choice | Size |
|-----------|--------|------|
| Server | Dart Frog | ~20 MB |
| Database | PostgreSQL Alpine | ~80 MB |
| **Total** | | **~100 MB** |

### Docker Compose

```yaml
version: '3.8'

services:
  server:
    build: ./my_budget_server
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgres://budget:password@db:5432/mybudget
      - API_KEYS=key1,key2,key3
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=budget
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=mybudget
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  pgdata:
```

### API (HTTP + WebSocket)

```
# HTTP REST
POST   /api/sync/push          # Push changes (binary)
GET    /api/sync/pull?since=   # Pull changes (binary)
GET    /api/sync/full          # Full dump (binary)

# WebSocket
WS     /ws/sync                # Real-time notifications

Headers: X-API-Key: your-key
```

### WebSocket Messages

```dart
// Client → Server
{"type": "auth", "apiKey": "..."}
{"type": "push", "data": "<base64 binary>"}

// Server → Client
{"type": "change", "data": "<base64 binary>"}
{"type": "conflict", "id": "...", "yours": {...}, "theirs": {...}}
```

---

## Conflict Resolution

### Стратегия

```dart
if (serverModifiedAt > clientModifiedAt) {
  // Server wins, сохраняем клиентскую версию в conflict_history
} else {
  // Client wins, сохраняем серверную версию в conflict_history
}
```

### Conflict History

```sql
CREATE TABLE conflict_history (
  id TEXT PRIMARY KEY,
  table_name TEXT,
  record_id TEXT,
  rejected_data BLOB,  -- MessagePack
  rejected_at INTEGER,
  rejected_device TEXT
);
```

Очистка по настройкам: `keepConflictsFor` или `maxConflictCount`

---

## First Sync (Initial Merge)

### Сценарии

| Device A | Device B | Action |
|----------|----------|--------|
| Empty | Has data | Full import from B |
| Has data | Empty | Full export to B |
| Has data | Has data | **Merge** |

### Merge Logic

```dart
for (record in incomingRecords) {
  final local = await db.getById(record.id);
  
  if (local == null) {
    // Новая запись → добавляем
    await db.insert(record);
  } else if (record.modifiedAt > local.modifiedAt) {
    // Входящая новее → обновляем, сохраняем старую в history
    await conflictHistory.save(local);
    await db.update(record);
  } else {
    // Локальная новее → сохраняем входящую в history
    await conflictHistory.save(record);
  }
}
```

---

## DB Schema Changes

```sql
-- Добавить ко ВСЕМ таблицам
ALTER TABLE transactions ADD COLUMN modified_at INTEGER NOT NULL DEFAULT 0;
ALTER TABLE transactions ADD COLUMN device_id TEXT;
ALTER TABLE transactions ADD COLUMN is_deleted INTEGER DEFAULT 0;

-- Sync log (очередь изменений)
CREATE TABLE sync_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  action TEXT NOT NULL,  -- upsert, delete
  timestamp INTEGER NOT NULL
);

-- Conflict history
CREATE TABLE conflict_history (
  id TEXT PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  rejected_data BLOB,
  rejected_at INTEGER NOT NULL,
  rejected_device TEXT
);
```

---

## Implementation Plan

### Phase 1: DB Migration
- [ ] Добавить `modified_at`, `device_id`, `is_deleted` ко всем таблицам
- [ ] Создать `sync_log` и `conflict_history` таблицы
- [ ] Генерация уникального `deviceId` при первом запуске
- [ ] Автоматическое обновление `modified_at` при изменениях

### Phase 2: Binary Export/Import
- [ ] Binary writer (аналог `CurrencyHistoryBinaryIO`)
- [ ] Binary reader + Gzip compression
- [ ] Unit tests для сериализации

### Phase 3: P2P Sync
- [ ] File watcher для папки Syncthing
- [ ] Export service (каждые 30 сек)
- [ ] Import service (merge + conflicts)
- [ ] UI: выбор папки, статус синхронизации
- [ ] UI: просмотр/разрешение конфликтов
- [ ] Settings: interval, cleanup, etc.

### Phase 4: Server
- [ ] Создать `my_budget_server` (Dart Frog)
- [ ] PostgreSQL schema
- [ ] HTTP REST: push/pull/full
- [ ] WebSocket: real-time
- [ ] API key middleware
- [ ] Dockerfile + docker-compose
- [ ] Client: SyncService для сервера

### Phase 5: Testing
- [ ] Unit tests: binary format, merge logic
- [ ] Integration tests: P2P sync
- [ ] Integration tests: server sync
- [ ] Conflict resolution tests
