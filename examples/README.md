# examples/

Runnable demos (not CI tests). Prefer subdirs with `main.tu`.

Use `asyncio.wrapper` camelCase factories; await leaf futures in the demo file
with typed `ConnectFut` / `AcceptFut` / `WriteAll` / `Read` locals (compiler UX).

| Path | Role |
|------|------|
| `httpserver/` | Persistent HTTP/1.1 server (CT sequential accept; ab/wrk stable) |
| `httpclient/` | HTTP/1.1 client via `asyncio.wrapper` |
| `httpclient/` | Client against a running server (`blockOnCt`) |

HTTP framing stays in these demos (not in `asyncio.wrapper`).

Wrapper TCP smoke: `tests/asyncio/int_wrapper_tcp.tu`.
