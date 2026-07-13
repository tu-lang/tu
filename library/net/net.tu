use sys

/// Possible values which can be passed to the [`TcpStream::shutdown`] method.
ShutdownRead<i32> = 1
ShutdownWrite<i32> = 2
ShutdownBoth<i32> = 3

fn toDigit(c<i8>, radix<i32>) i32, i32 {
    v<i32> = 0
    if '0' <= c && c <= '9' {
        v = c - '0'
    }else if  'a' <= c && c <= 'z' {
        v = c - 'a' + 10
    }else if 'A' <= c && c <= 'Z' {
        v = c - 'A' + 10
    }else{
        return Err
    }

    if v >= radix {
        return Err
    }
    return Ok,v
}
