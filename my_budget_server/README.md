# my_budget_server

Sync server for MyBudget. Dart Frog + PostgreSQL. Holds exactly one budget and
serves it to that budget owner's devices.

## Setup

The server needs a shared secret in `SYNC_TOKEN`. Every device presents it;
without it the server answers `503` to every `/api` and `/ws` request and
refuses to serve anyone.

Generate one:

```sh
openssl rand -hex 32
```

Put it in a `.env` file next to `docker-compose.yml`:

```
SYNC_TOKEN=<the value you just generated>
```

Then:

```sh
docker compose up -d
```

In the app: **Settings → Synchronization → Server**, enter the server URL and
the same token, and press *Test Connection*. The three failure messages are
distinct on purpose — "token rejected" means the token, "no sync token
configured" means the server, anything else means the address or the network.

## Why it refuses to run without a token

The token is the only thing standing between this database and whoever else
can reach the port. There is no user column anywhere in the schema: one token
guards everything, and anyone holding it can read and overwrite the whole
budget. That is the intended shape for a personal server, and it is also why
starting without a token is treated as a misconfiguration rather than as
"authentication off".

Notes on the implementation, if you are changing it:

- The check runs *before* schema initialisation, so an unauthenticated caller
  cannot make the server open connections or run DDL.
- Tokens are compared in constant time. A short-circuiting `==` leaks the
  length of the matching prefix through response timing.
- HTTP routes accept the token in an `Authorization: Bearer` header only. The
  WebSocket route also accepts `?token=`, because a browser's WebSocket API
  cannot set request headers and the web build has no other way in. On the HTTP
  routes a token in the URL would be copied into every access and proxy log.
- `/` stays open as a liveness probe. It returns a fixed string and reads
  nothing.

## Exchange rates

The server fetches the published exchange rates itself and serves them to the
devices, instead of every device fetching the same day from the same public CDN
and storing its own copy. A background refresher pulls whatever days are
missing (newest first, so today's quote is in before the backfill), writes them
into `exchange_rates`, and the app reads them on demand:

```
GET /api/rates?from=EUR&to=USD,JPY&date_from=2026-01-01&date_to=2026-03-14
GET /api/rates/latest?from=EUR&to=USD,JPY[&date=2026-03-14]
```

Both take the shared token like every other `/api` route, return
`{"rates": [...], "has_more": bool}`, and quote the app's own field names so a
row can go straight into the device's database. `/api/rates/latest` gives one
quote per pair at or before the date, falling back to the last published one,
so a Sunday reads as Friday's rate.

Fetched rows are marked with the device id `server:rates` and are deliberately
**excluded from the sync pull**. A full backfill is hundreds of thousands of
rows; handed to every device through the ordinary sync it would cost exactly
what moving the fetch here was meant to save. Rates a device pushes up itself —
entered by hand or imported — still sync normally.

| Variable | Default | What it does |
| --- | --- | --- |
| `RATES_ENABLED` | `true` | Off stops the fetching. Whatever is already stored is still served. |
| `RATES_BASE` | `EUR` | Currency every quote is expressed against. |
| `RATES_BACKFILL_FROM` | `2024-04-01` | Oldest day the backfill reaches for. |
| `RATES_REFRESH_MINUTES` | `360` | Gap between runs. |
| `RATES_REQUEST_DELAY_MS` | `200` | Pause between two upstream requests. The provider publishes no rate limit, which is a reason to be careful with it rather than a licence. |
| `RATES_MAX_DAYS_PER_RUN` | `400` | Upper bound on days fetched per run, so a first backfill always ends. |
| `RATES_MAX_GAP_ATTEMPTS` | `3` | How often a day with nothing published is asked for again before it is left alone. |

A first run on an empty database is roughly one request per day of history, so
a backfill to 2024-04-01 takes a few minutes and is spread over several runs.

## Exposure

`dart_frog` binds `0.0.0.0` by default, which is what you want behind a reverse
proxy and not what you want on a machine directly on the internet without one.
For a local-only server:

```sh
HOST=127.0.0.1 dart_frog dev
```

`docker-compose.yml` publishes PostgreSQL on `127.0.0.1:5432` only. It still
uses the default `postgres`/`postgres` credentials, so if you ever widen that
mapping, change the password first.

Put TLS in front of the server before using it across the internet. The token
travels in a header (and, for the WebSocket, in a query string); over plain
HTTP both are readable by anything on the path.

## Development

```sh
dart pub get
dart test          # 192 tests
dart_frog dev
```

`DATABASE_URL` selects the database; the schema is created on first request.
