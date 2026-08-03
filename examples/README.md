# examples/

Runnable demos (not CI tests). Prefer subdirs with `main.tu`.

**Pure dynamic OOP** via `asyncio.wrapper`:

```text
use asyncio.wrapper as asyncio
st.sendStr(body).await
lis.takeConn().await
```

- `func` / `class` / dynamic strings — yes
- `mem` / typed locals / type asserts / `*"..."` / `as wrap` — no

| Path | Role |
|------|------|
| `httpserver/` | HTTP/1.1 server (`blockOnCt` + sequential serve) |
| `httpclient/` | HTTP/1.1 client (`dialTo` + `Stream` methods) |

Wrapper TCP smoke: `tests/asyncio/int_wrapper_tcp.tu`.
