// UDP async surface deferred: full PollEvented impl blocked by asyncio.net.udp
// vs netio.net.udp package-name collision on member async multi-return.
// int_udp_recv.tu uses leaf futures + netio path once C-layer fixes land.

use io

mem UdpSocket {
    i32 placeholder
}

const UdpSocket::bind(addr) (i32, UdpSocket) {
    unsupported<i32> = 95
    return unsupported, null
}
