// TaskId：全局唯一 task 标识
// 关联：packages-asyncio-runtime task 3.1，R8.5
//
// 调度器为每个 spawn 出来的 task 分配一个单调递增、不重复的 u64 id；
// 通过 std.atomic.xadd64 原子递增，保证多线程并发分配两两不等。
// TaskId 与 (handle_hash, task_id) 一同打包成 ctx 透传给叶子 future（详见 design §2.7）。

use std.atomic

mem TaskId {
    u64 v
}

// 模块级原子计数器；从 1 起（0 保留给「无 task」语义）
next_task_id<u64> = 1

// alloc_id()：原子分配下一个 TaskId
//   xadd64 返回累加后的值；这里令 id = pre-increment，故先取一份再 +1。
//   实现上 std.atomic.xadd64 已返回 add 后的值，所以 id = ret - 1 才是分配出去的旧值。
fn alloc_id() TaskId {
    after<u64> = atomic.xadd64(&next_task_id, 1)
    return new TaskId { v: after - 1 }
}
