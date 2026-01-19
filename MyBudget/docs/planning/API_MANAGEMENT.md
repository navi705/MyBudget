# API Management System

## Обзор

Переработка API экрана для гибкого управления внешними данными.

---

## Функции

### 1. Auto-fetch

| Триггер | Логика |
|---------|--------|
| При запуске | Если enabled + lastFetch < today |
| Каждые 24ч | Timer.periodic, проверка lastFetch |
| Вручную | Кнопка + date range picker |

```dart
// Проверка перед fetch
bool shouldFetch(DateTime lastFetch) {
  final today = DateTime.now();
  return lastFetch.day != today.day || lastFetch.month != today.month;
}
```

### 2. UI

```
┌─────────────────────────────────────────┐
│ Built-in APIs                           │
├─────────────────────────────────────────┤
│ Exchange Rates                    [ON]  │
│ └── Auto-fetch: [✓]                    │
│ └── Last: 2026-01-19 12:00             │
│ └── [Fetch Now]                        │
├─────────────────────────────────────────┤
│ Inflation                        [OFF]  │
├─────────────────────────────────────────┤
│ Custom Data Sources                     │
├─────────────────────────────────────────┤
│ [+] Add Source                          │
│                                          │
│ ┌── My Stock Server ──────────────────┐ │
│ │ URL: https://my-server.com/prices   │ │
│ │ Type: Asset Prices    [✓] [Edit] ✕  │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Manual Fetch                            │
├─────────────────────────────────────────┤
│ Source: [Exchange Rates ▼]              │
│ From:   [2026-01-01]                    │
│ To:     [2026-01-19]                    │
│ [Fetch]                                 │
└─────────────────────────────────────────┘
```

### 3. Custom Data Source (Упрощённый)

**Без field mapping!** Сервер должен возвращать стандартный формат:

```json
// Exchange Rates
{"type": "exchange_rates", "data": [
  {"date": "2026-01-19", "base": "EUR", "code": "USD", "rate": 1.08}
]}

// Inflation
{"type": "inflation", "data": [
  {"date": "2026-01-19", "country": "RS", "rate": 5.2}
]}

// Asset Prices
{"type": "asset_prices", "data": [
  {"date": "2026-01-19", "code": "AAPL", "price": 185.50}
]}
```

### 4. Initial Fetch

При первом запуске — загрузка данных с даты деплоя:

```dart
const DEPLOYMENT_DATE = DateTime(2026, 1, 1);

Future<void> initialDataLoad() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('initial_fetch_done') == true) return;
  
  await fetchExchangeRates(from: DEPLOYMENT_DATE, to: DateTime.now());
  await fetchInflation(from: DEPLOYMENT_DATE, to: DateTime.now());
  
  await prefs.setBool('initial_fetch_done', true);
}
```

---

## Database

```sql
-- Custom data sources
CREATE TABLE custom_data_sources (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  data_type INTEGER NOT NULL,  -- 0=exchange, 1=inflation, 2=asset
  enabled INTEGER DEFAULT 1,
  auto_fetch INTEGER DEFAULT 0,
  last_fetch_at INTEGER,
  
  -- Sync fields
  modified_at INTEGER,
  device_id TEXT,
  is_deleted INTEGER DEFAULT 0
);

-- API settings (for built-in APIs)
CREATE TABLE api_settings (
  id TEXT PRIMARY KEY,  -- "exchange_rates", "inflation", "assets"
  enabled INTEGER DEFAULT 1,
  auto_fetch INTEGER DEFAULT 0,
  last_fetch_at INTEGER,
  
  modified_at INTEGER,
  device_id TEXT
);

-- SMS presets (migrate from SharedPreferences)
CREATE TABLE sms_presets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  sender_filter TEXT NOT NULL,
  is_built_in INTEGER DEFAULT 0,
  is_enabled INTEGER DEFAULT 1,
  default_account_id TEXT,
  default_category_id TEXT,
  rules_json TEXT,  -- JSON array of parsing rules
  
  modified_at INTEGER,
  device_id TEXT,
  is_deleted INTEGER DEFAULT 0
);
```

---

## Implementation Plan

### Phase 1: DB Migration
- [ ] Добавить sync fields ко всем существующим таблицам
- [ ] Создать `sync_log`, `conflict_history`
- [ ] Создать `custom_data_sources`, `api_settings`
- [ ] Мигрировать `sms_presets` из SharedPrefs в SQLite
- [ ] Генерация `deviceId`

### Phase 2: API Settings UI
- [ ] Переделать `ApiSettingsScreen` с toggles
- [ ] Добавить date range picker
- [ ] Показывать last fetch time

### Phase 3: Auto-fetch Logic
- [ ] Fetch в Isolate (background)
- [ ] Timer.periodic каждые 24ч
- [ ] Проверка дубликатов перед записью

### Phase 4: Custom Data Sources
- [ ] Add/Edit/Delete источников
- [ ] Test connection button
- [ ] Парсинг стандартного формата

### Phase 5: Initial Fetch
- [ ] Логика первого запуска
- [ ] Backfill missing data
