
READABLE<u8> = 1
WRITABLE<u8> = 2
AIO<u8>      = 4
LIO<u8>      = 8

mem Interest {
    inner u8
}

Interest::add(other<Interest>) Interest {
    return new Interest {
        inner: this.inner | other.inner
    }
}

//TODO: option check
Interest::remove(other<Interest>) Interest {
    return new Interest {
        inner: this.inner & !other.inner 
    }
}

Interest::is_readable() u8 {
    return (this.inner & READABLE) != 0
}

Interest::is_writable() u8 {
    return (this.inner & Writable) != 0
}

Interest::is_aio() u8 {
    return ( this.inner & AIO ) != 0
}
Interest::is_lio() u8 {
    return ( this.inner & LTO ) != 0
}

// |
Interest::bitor(b<Interest>) Interest {
    return this.add(b)
}
// a |= b
Interest::bitor_assign(other<Interest>) {
    this.inner = this.inner | other.inner
}

Interest::fmt() {
    one<i32> = false
    if this.is_readable() == true {
        if one {
            runtime.printf(*" | ")
        }
        runtime.printf(*"READABLE")
        one = true
    }
    if this.is_writable() == true {
        if one {
            runtime.printf(*" | ")
            runtime.print(*"WRITABLE")
            one = true
        }
        if this.is_aio() == true {
            if one {
                fmt.print(*" | ")
            }
            runtime.print(*"AIO")
            one = true
        }
        if this.is_lio() == true {
            if one {
                runtime.print(*" | ")
            }
            runtime.print(*" LIO ")
            one = true
        }
    }
}
