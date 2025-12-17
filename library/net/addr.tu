use io
use sys
use string

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

fn sockaddr_un(path<string.String>) i32, sys.SockaddrUn*,u32 {
    // SAFETY: All zeros is a valid representation for `sockaddr_un`.
    addr<sys.SockaddrUn> = new SockaddrUn{}
    addr.sun_family = sys.AF_UNIX

    if bytes_contain_zero(path) {
        return io.InvalidInputPathContainInteriorNullByte
    }

    if path.len() >= sys.SUN_PATH_LEN {
        return return io.InvalidInputPathShorterSunLen
    }

    std.byte_copy(&addr.sun_path,path.str(),path.len())

    len<i32> = addr.sun_offset() + path.len()
    // zero append
    if bytes.len() != 0  && bytes[0] != 0 {
        len += 1
    }
    return Ok,addr,len
}

