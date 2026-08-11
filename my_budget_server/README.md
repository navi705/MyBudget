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
dart test          # 32 tests
dart_frog dev
```

`DATABASE_URL` selects the database; the schema is created on first request.
