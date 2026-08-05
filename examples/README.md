# examples/

面向用户的可运行演示（不进 CI）。每个子目录一份 `main.tu`，用 `tu run` 即起。

当前里程碑：**异步网络门面可演示**——HTTP/1.1 服务端与客户端均走 `asyncio.wrapper` 的纯动态 OOP 表面。

## 约定

| 做 | 不做 |
|----|------|
| `func` / `class` / 动态字符串 `"..."` | `mem`、类型标注局部、`x.(T)`、原生串 `*"..."` |
| 对象方法：`lis.takeConn` / `st.sendStr` / `recvStr` / `drain` / `close` | 过程式 `wrapper.drain(st, n)` |
| `use asyncio.wrapper` 或 `as asyncio`（见包知意） | `as wrap` / `as w` |

```text
use asyncio.wrapper as asyncio

err, lis = asyncio.listen("127.0.0.1:18080")
aerr, st = lis.takeConn().await
st.drain(4096).await
st.sendStr(body).await
st.close()
```

## 目录

| 路径 | 说明 |
|------|------|
| [`httpserver/`](./httpserver/) | 持久 HTTP/1.1 服务（`blockOnCt` + 顺序 accept→serve；可 `ab`/`wrk` 压测） |
| [`httpclient/`](./httpclient/) | HTTP/1.1 客户端（`dialTo` + `Stream` 读写） |

## 快速体验

```bash
# 终端 1
tu run examples/httpserver

# 终端 2
tu run examples/httpclient
# 或 curl / ab
curl http://127.0.0.1:18080/
ab -c 20 -n 500 http://127.0.0.1:18080/
```

门面 TCP 冒烟测：`tests/asyncio/int_wrapper_tcp.tu`。
