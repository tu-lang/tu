# examples/

面向用户的可运行演示。每个子目录一份 `main.tu`，用 `tu run` 即起。

`make tests` 会跑 [`test.sh`](./test.sh)：每个有 `main.tu` 的目录**必须**自带 `test.sh`（业务不同，验收方式各自实现）。

当前里程碑：**异步网络门面可演示**——HTTP/1.1 服务端与客户端均走 `asyncio.wrapper` 的纯动态 OOP 表面。

## 约定（代码）

| 做 | 不做 |
|----|------|
| `func` / `class` / 动态字符串 `"..."` | `mem`、类型标注局部、`x.(T)`、原生串 `*"..."` |
| 对象方法：`lis.takeConn` / `st.sendStr` / `recvStr` / `drain` / `close` | 过程式 `wrapper.drain(st, n)` |
| `use asyncio.wrapper` 或 `as asyncio`（见包知意） | `as wrap` / `as w` |

## 约定（测试）

| 做 | 不做 |
|----|------|
| 新 demo 同步加 `<name>/test.sh` | 指望顶层 `examples/test.sh` 统一压测所有业务 |
| 常驻服务：就绪 → 客户端/压测约 10s → kill → 看成功次数 | 等 `main` 自己退出 |
| 一次性客户端：拉起依赖 → 跑完断言日志/退出码 → 拆掉依赖 | 无 `test.sh` 却进仓库 |

共享编译/等端口/杀进程：[`_harness.sh`](./_harness.sh)。细则见 `.cursor/rules/examples-dynamic-facade.mdc`。

## 目录

| 路径 | 说明 | 测试形态 |
|------|------|----------|
| [`httpserver/`](./httpserver/) | 持久 HTTP/1.1（`blockOnMt` + per-conn spawn） | 常驻 + 约 10s curl/httpclient 压测后 kill |
| [`httpclient/`](./httpclient/) | HTTP/1.1 客户端 | 临时起 httpserver → 跑一次客户端 → kill |

## 快速体验

```bash
# 终端 1
tu run examples/httpserver/main.tu

# 终端 2
tu run examples/httpclient/main.tu
# 或 curl / ab
curl http://127.0.0.1:18080/
ab -c 20 -n 500 http://127.0.0.1:18080/
```

只跑 examples 门禁：

```bash
sh examples/test.sh
# 或
make examples
```

门面 TCP 冒烟测：`tests/asyncio/int_wrapper_tcp.tu`。
