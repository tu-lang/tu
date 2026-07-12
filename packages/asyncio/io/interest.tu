// User-facing Interest helpers; type is netio.Interest.

use netio

READABLE<u8> = netio.READABLE_BIT
WRITABLE<u8> = netio.WRITABLE_BIT

fn readable() {
    return netio.readable_interest()
}

fn writable() {
    return netio.writable_interest()
}

fn interest_add(a, b) {
    return netio.interest_merge(a, b)
}
