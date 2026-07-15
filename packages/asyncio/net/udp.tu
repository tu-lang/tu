// Async UDP socket stub for compile of the asyncio.net package root.
// Full PollEvented + send_to / recv_from lives in mother tokio::net::UdpSocket
// and will be restored via asyncio.util net bridges (this package must not
// `use net` — short-name collision with library net). See int_udp_recv.tu.

use runtime
use netio
use asyncio.io as aio

// Async UDP socket placeholder (addr bits API; full impl deferred).
mem UdpSocket {
    aio.PollEvented* io
}

const UdpSocket::bind(addr_bits<u64>) (i32, UdpSocket) {
    unsupported<i32> = 95
    return unsupported, null
}
