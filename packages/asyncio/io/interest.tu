// User-facing Interest helpers; type is netio.Interest.

use netio

READABLE<u8> = netio.READABLE_BIT
WRITABLE<u8> = netio.WRITABLE_BIT

fn readable() netio.Interest {
    return netio.Interest::readable()
}

fn writable() netio.Interest {
    return netio.Interest::writable()
}

fn interest_add(a<netio.Interest>, b<netio.Interest>) netio.Interest {
    return a.add(b)
}
