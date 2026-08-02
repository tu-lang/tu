// Async member .await: static Type::method(), instance obj.method(), and this.method().
use fmt
use runtime
use os

mem TestCase {
    i32 ty
}
case1<TestCase> = new TestCase { ty: 1 }

// Static async member: TcpStream::connect().await style.
mem TcpStream {
}
async TcpStream::connect() {
    return 42.(i8)
}

// Instance async member: listener.accept().await style.
mem Listener {
    i32 fd
}
async Listener::accept() {
    return 99.(i8)
}

async TestCase::helper() {
    return 7.(i8)
}

async TestCase::static_member_await() {
    return TcpStream::connect().await
}

async TestCase::instance_member_await() {
    l<Listener> = new Listener { fd: 0 }
    return l.accept().await
}

async TestCase::this_member_await() {
    return this.helper().await
}

async TestCase::multi_static_await() {
    a<i8>, b<i8> = TcpStream::connect().await, this.helper().await
    return a + b
}

// Expression-surface matrix: .await as BinaryExpr operands (mem path).
async TestCase::mem_binop_type_type() {
    return TcpStream::connect().await + TcpStream::connect().await
}
async TestCase::mem_binop_type_this() {
    return TcpStream::connect().await + this.helper().await
}
async TestCase::mem_binop_this_this() {
    return this.helper().await + this.helper().await
}
async TestCase::mem_binop_type_lit() {
    return TcpStream::connect().await + 8.(i8)
}
async TestCase::mem_binop_lit_type() {
    return 8.(i8) + TcpStream::connect().await
}
async TestCase::mem_binop_this_lit() {
    return this.helper().await + 3.(i8)
}
async TestCase::mem_binop_lit_this() {
    return 3.(i8) + this.helper().await
}
async TestCase::mem_binop_nested_triple() {
    return TcpStream::connect().await + this.helper().await + 1.(i8)
}
async TestCase::mem_binop_add_assign() {
    s<i8> = 0.(i8)
    s += TcpStream::connect().await
    s += this.helper().await
    return s
}
async TestCase::mem_binop_instance_mix() {
    l<Listener> = new Listener { fd: 0 }
    return l.accept().await + this.helper().await
}

fn test_static_type_await() {
    fmt.println("test static Type::method().await")
    ret<i64> = runtime.block(case1.static_member_await())
    if int(ret.(i8)) != 42 os.dief("static await want 42 got %d", int(ret.(i8)))
    fmt.println("test static Type::method().await success")
}

fn test_instance_await() {
    fmt.println("test instance obj.method().await")
    ret<i64> = runtime.block(case1.instance_member_await())
    if int(ret.(i8)) != 99 os.dief("instance await want 99 got %d", int(ret.(i8)))
    fmt.println("test instance obj.method().await success")
}

fn test_this_await() {
    fmt.println("test this.method().await")
    ret<i64> = runtime.block(case1.this_member_await())
    if int(ret.(i8)) != 7 os.dief("this await want 7 got %d", int(ret.(i8)))
    fmt.println("test this.method().await success")
}

fn test_multi_static_await() {
    fmt.println("test multi static member await")
    ret<i64> = runtime.block(case1.multi_static_await())
    if int(ret.(i8)) != 49 os.dief("multi await want 49 got %d", int(ret.(i8)))
    fmt.println("test multi static member await success")
}

fn test_mem_fut_binop_await() {
    fmt.println("test mem await BinaryExpr matrix")
    r<i64> = runtime.block(case1.mem_binop_type_type())
    if int(r.(i8)) != 84 os.dief("Type.await + Type.await want 84 got %d", int(r.(i8)))
    r = runtime.block(case1.mem_binop_type_this())
    if int(r.(i8)) != 49 os.dief("Type.await + this.await want 49 got %d", int(r.(i8)))
    r = runtime.block(case1.mem_binop_this_this())
    if int(r.(i8)) != 14 os.dief("this.await + this.await want 14 got %d", int(r.(i8)))
    r = runtime.block(case1.mem_binop_type_lit())
    if int(r.(i8)) != 50 os.dief("Type.await + lit want 50 got %d", int(r.(i8)))
    r = runtime.block(case1.mem_binop_lit_type())
    if int(r.(i8)) != 50 os.dief("lit + Type.await want 50 got %d", int(r.(i8)))
    r = runtime.block(case1.mem_binop_this_lit())
    if int(r.(i8)) != 10 os.dief("this.await + lit want 10 got %d", int(r.(i8)))
    r = runtime.block(case1.mem_binop_lit_this())
    if int(r.(i8)) != 10 os.dief("lit + this.await want 10 got %d", int(r.(i8)))
    r = runtime.block(case1.mem_binop_nested_triple())
    if int(r.(i8)) != 50 os.dief("nested triple want 50 got %d", int(r.(i8)))
    r = runtime.block(case1.mem_binop_add_assign())
    if int(r.(i8)) != 49 os.dief("+= await want 49 got %d", int(r.(i8)))
    r = runtime.block(case1.mem_binop_instance_mix())
    if int(r.(i8)) != 106 os.dief("instance.await + this.await want 106 got %d", int(r.(i8)))
    fmt.println("test mem await BinaryExpr matrix success")
}

fn main() {
    fmt.println("test async member await")
    test_static_type_await()
    test_instance_await()
    test_this_await()
    test_multi_static_await()
    test_mem_fut_binop_await()
    fmt.println("test async member await success")
}
