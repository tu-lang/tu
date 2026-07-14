use io
use sys
use string
use std

fn bytes_contain_zero(str<string.String>) i32 {
    ll<i32> = str.len()
    p<i8*>  = str.str()
    for i<i32> = 0 ; i < ll ; i += 1 {
        if p[i] == 0 {
            return true
        }
    }
    return false
}

// Mother tustd::net::addr::sockaddr_un — build AF_UNIX sockaddr from path bytes.
fn sockaddr_un(path<string.String>) i32, sys.SockaddrUn, u32 {
    // SAFETY: All zeros is a valid representation for sockaddr_un.
    addr<sys.SockaddrUn> = new sys.SockaddrUn{}
    addr.sun_family = sys.AF_UNIX

    if bytes_contain_zero(path) {
        return io.InvalidInputPathContainInteriorNullByte, null, 0
    }

    if path.len() >= sys.SUN_PATH_LEN {
        return io.InvalidInputPathShorterSunLen, null, 0
    }

    plen<i32> = path.len()
    plen_u64<u64> = plen.(u64)
    std.byte_copy(&addr.sun_path, path.str(), plen_u64)

    offs<i64> = addr.sun_offset()
    offs_i32<i32> = offs.(i32)
    len<i32> = offs_i32 + plen
    // Mother: Some(nonzero first byte) => include trailing NUL in socklen.
    p<i8*> = path.str()
    if plen != 0 && p[0] != 0 {
        len += 1
    }
    socklen<u32> = len.(u32)
    return Ok, addr, socklen
}
