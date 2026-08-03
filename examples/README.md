# examples/

Runnable demos (not CI tests). Prefer subdirs with `main.tu`.

**Pure dynamic only** via `asyncio.wrapper` camelCase APIs:

- `func` / `class` / dynamic strings — yes
- `mem` / typed locals / type asserts / `*"..."` / engine `asyncio.net.tcp` — no

| Path | Role |
|------|------|
| `httpserver/` | HTTP/1.1 server (`blockOnMt` + per-conn `spawn`) |
| `httpclient/` | HTTP/1.1 client (`blockOnCt` + `dialTo`/`sendStr`/`recvStr`) |

HTTP framing stays in these demos (not in `asyncio.wrapper`).

Wrapper TCP smoke: `tests/asyncio/int_wrapper_tcp.tu`.
