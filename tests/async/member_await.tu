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

fn main() {
    fmt.println("test async member await")
    test_static_type_await()
    test_instance_await()
    test_this_await()
    test_multi_static_await()
    fmt.println("test async member await success")
}
