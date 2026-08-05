<div align="center">
<h1>The Tu Programming Language</h1>

[文档手册 · 筹备中](https://tu-lang.cn)

<p>
<img alt="GitHub code size in bytes" src="https://img.shields.io/github/languages/code-size/tu-lang/tu">
<img alt="GitHub release (latest by date including pre-releases)" src="https://img.shields.io/github/v/release/tu-lang/tu?include_prereleases">
<img alt="GitHub top language" src="https://img.shields.io/github/languages/top/tu-lang/tu">
</p>

![logo](./assets/logo.svg)

**零依赖 · 动静同构 · 全静态链接 · 已自举**

`compiler` 纯动态 · `asmer` 纯静态 · `linker` 动静混合 —— 整条工具链用 Tu 自己写成。

</div>

---

Tu（凸）是一门面向系统与应用的编译型语言：没有强制 runtime 绑架，动态语法写起来像脚本，静态 `mem` / 原生类型又能落到可预测的机器码。一份源码里两种气质可以并肩出现；异步侧原生支持多线程协程调度。

```
Usage: tu <command|option> [arguments]

Commands:
  run   <file.tu> [args...]  编译、链接并运行
  build <file.tu>            编译并链接生成可执行文件

Options:
  -s   <file.tu|dir>         编译为 amd64 汇编（.s）
  -c   <file.s|dir>          汇编为可重定位目标文件（.o）
  -o   <file.o|dir>          链接目标文件生成可执行程序
  -d                         开启 trace 日志
  -g                         带 debug 段（支持栈回溯）
  -gcc                       使用 gcc 链接
  -std                       同时编译 runtime/std 内置库
  --workdir DIR              中间产物写到 DIR（.s/.o/a.out）
  --workdir-cwd              中间产物写当前目录（旧行为）
  --work                     保留中间产物
  -v                         打印版本

Default workdir: $TMPDIR/tu-build-<stem>-...
```

一行跑起来：

```bash
tu run hello.tu
```

## Demo

![gif](./assets/tulang.gif)

## Install

```bash
git clone https://github.com/tu-lang/tu.git
cd tu
sudo make install
```

## Tests

语法与运行时用例都在 `tests/`（数据结构、运算符、GC、async、asyncio 集成等）。

```bash
sudo make install
make tests
```

## Language surface

| 层 | 能力 |
|----|------|
| 动态 | `int` `float` `string` `bool` `null` `array` `map` `closure` `object` |
| 静态 | `i8`…`u64` `f32` `f64` `pointer` `mem` |
| 控制与模块 | `func`/`fn` `goto` `class` `return` `type` `use` `if` `while` `for`/`range` `loop` `match` |
| 现代抽象 | `async`/`await` · `api`/`impl` · `asyncio`（timer / net / fs / process / signal / select / join）|

---

### Dynamic — 异构数据一把梭

Map、数组、闭包、对象可以塞进同一条流水线；`match` 直接吃表达式，不需要先拆成一堆 if。

```
use fmt
use os

class Hub {
    routes
}
Hub::handler(){
    return fn(path){
        return {
            "path": path,
            "ok":   true,
            "tags": ["api", "v1", path]
        }
    }
}

fn bootstrap(){
    table = {
        "GET /":     "index",
        "POST /run": [200, "accepted"],
        "meta":      { "lang": "tu", "zero_dep": true }
    }
    hub = new Hub()
    return table, hub.handler()
}

fn main(){
    routes, handle = bootstrap()
    fmt.println(routes["meta"])

    hit = handle("/run")
    match hit["path"] {
        "/run" | "/exec" : fmt.println("dispatch", hit["tags"])
        _                : os.die("unknown route")
    }
}
```

---

### Static — 结构体就是布局

`mem` + 原生整数/指针：红黑树节点这种东西可以直接按字段布局写，没有「先装箱再猜」。

```
use runtime

Null<i64> = 0
enum {
    Insert,
    Update,
    Conflict,
}

mem Rbtree {
    RbtreeNode* root
    RbtreeNode* sentinel
    u64         insert
}
mem RbtreeNode {
    u64  key
    u8   color
    RbtreeNode* left
    RbtreeNode* right
    RbtreeNode* parent
    runtime.Value* k
    runtime.Value* v[Conflict]
}

Rbtree::find(hk<u64>){
    node<RbtreeNode>     = this.root
    sentinel<RbtreeNode> = this.sentinel
    while node != sentinel {
        if hk != node.key {
            if hk < node.key {
                node = node.left
            } else {
                node = node.right
            }
            continue
        }
        break
    }
    if node == sentinel return Null
    return node
}

fn main(){}
```

---

### Asyncio — 异步运行时：定时器、网络与并发

`packages/asyncio` 提供 Builder、时间轮、IO/信号 driver，以及 `select` / `join` / `timeout`。下面这段真实可跑——两个定时器 `select` 竞速，再 `join` 并发等待：

```
use fmt
use io
use os
use runtime
use asyncio.runtime as rt
use asyncio.macros as m
use asyncio.time as atime

// Race two timers: the 10ms one wins the select.
async race() {
    winner<i32> = m.select2(
        atime.sleep(atime.from_millis(10)),
        atime.sleep(atime.from_millis(1000))
    ).await
    fmt.println("select: fast timer won, branch =", int(winner))

    // Run two sleeps concurrently; total wait is max(20,30), not the sum.
    st<i32> = m.join2(
        atime.sleep(atime.from_millis(20)),
        atime.sleep(atime.from_millis(30))
    ).await
    fmt.println("join: both timers fired")
    return st
}

fn main() {
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    err<i32>, ret<i64> = rt.builder_block_on(b, race(), 0)
    if err != 0 || ret != io.Ok os.die("runtime failed")
    fmt.println("done")
}
```

```text
select: fast timer won, branch = 1
join: both timers fired
done
```

网络侧走 `asyncio.wrapper` 动态 OOP 门面，仓库自带 HTTP demo：

```bash
tu run examples/httpserver   # 终端 1
tu run examples/httpclient   # 终端 2
# 或 curl / ab http://127.0.0.1:18080/
```

```
use fmt
use os
use asyncio.wrapper as asyncio

okResp = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
okResp += "Content-Length: 13\r\nConnection: close\r\n\r\nHello, world!"

async serveOne(st) {
    st.drain(4096).await
    st.sendStr(okResp).await
    st.close()
    return 0
}

class HttpServer {
    func init() {}
}

async HttpServer::run() {
    err, lis = asyncio.listen("127.0.0.1:18080")
    if err != 0 {
        return err
    }
    fmt.println("listening on http://127.0.0.1:18080")
    loop {
        aerr, st = lis.takeConn().await
        if aerr == 0 && st != null {
            serveOne(st).await
        }
    }
}

fn main() {
    asyncio.blockOnCt(new HttpServer().run())
}
```

客户端同形：`asyncio.dialTo(addr).await` → `sendStr` → `recvStr`。完整源码见 [`examples/`](./examples/)；TCP/UDP/Unix、fs、process、signal 用例见 `tests/asyncio/`。

---

### Api + Impl — 静态类型上的多态

接口带默认方法，`impl` 只补差异；同一个 `Animal` 槽可以先后挂 `Cat` / `Dog`。

```
use fmt

api Animal {
    fn name()
    fn talk()
    fn do(){
        fmt.printf("%s can %s\n", this.name(), this.talk())
    }
}

mem Dog {}
impl Animal for Dog {
    fn name(){ return "dog" }
    fn talk(){ return "wowo!" }
}

mem Cat {}
impl Animal for Cat {
    fn name(){ return "cat" }
    fn talk(){ return "miao!" }
}

fn main(){
    ani<Animal> = new Cat{}
    ani.do()        // cat can miao!
    ani = new Dog{}
    ani.do()        // dog can wowo!
}
```

## License

Copyright © 2016–2026 The tu-lang authors. All rights reserved.
