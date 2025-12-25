use io

mem Parser{
    // Parsing as ASCII, so can use byte array.
    u8* state
    i32 len
}

const Parser::new(input<u8*> , len<i32> ) Parser {
    return new Parser { state: input ,len: len}
}

/// Run a parser, and restore the pre-parse state if it fails.
Parser::read_atomically(inner) bool,SocketAddrV4 {
{
    state<u8*> = this.state
    len<i32>   = this.len
    has<i32>, result<u64> = inner(this)
    if has == None {
        this.state = state
        this.len   = len
        return None
    }
    return Has,result
}

/// Run a parser, but fail if the entire input wasn't consumed.
/// Doesn't run atomically.
Parser::parse_with(inner, kind<i32>) i32,SocketAddr {
    result<u64> = inner(this)
    if this.len == 0 {
        return Ok,result 
    } else { 
        return io.OtherParse
    }
}

/// Peek the next character from the input
Parser::peek_char() i32,i8 {
    if this.len == 0 {
        return None
    }
    return Has,this.state[0]
}

/// Read the next character from the input
Parser::read_char() i32,i8 {
    if this.len == 0 {
        return None
    }
    first<i8>   = this.state[0]
    this.state += 1
    this.len   -= 1

    return Has,first
}

/// Read the next character from the input if it matches the target.
Parser::read_given_char(target<i8>) i32 {

    return this.read_atomically(func(p<Parser>){
        has<i32> ,ret<i8> = p.read_char()
        if has == None {
            return None
        }

        if ret == c {
            return Has
        }
        return None
    })
    
}

Parser::read_separator(sep<i8>, index<u64>, inner) i32,u64 {

    has<i32>,ret<u64> = this.read_atomically( func(p<Parser>) {
        if index > 0 {
            has<i32> = p.read_given_char(sep)
            if has == None {
                return None
            }
        }
        has,ret<u64> = inner(p)
        return has,ret
    })
    return has,ret
}

Parser::read_number(radix<u32>, digits<i32>, max_digits<usize>, allow_zero_prefix<i32>,
) i32,u32 {
    has<i32>, ret<u32> = this.read_atomically(func(p<Parser>) {
        result<u32> = 0
        digit_count<i32> = 0
        has_leading_zero<i32> = false

        has<i32> ,c<i8> = p.peek_char()
        if c == '0' {
            has_leading_zero = true
        }

        loop {
            has,digit<u32> = p.read_atomically(func(p<Parser>){
                ok<i32> , c<i8> = p.read_char()
                if ok != Ok {
                    return ok
                }
                ok,d<u32> = toDigit(c,radix)
                return ok,d
            })
            //break
            if has != Ok  break

            checkMulAdd = fn(v<u32>, radix<u32>, digit<u32>) i32,u32 {
                if radix != 0 && v > (runtime.I32_MAX - digit) / radix {
                    return Err
                }
                return Ok, v * radix + digit
            }

            ok,result = checkMulAdd(result,radix,digit)
            if ok != Ok {
                return ok
            }
            digit_count += 1

            if digits == Has {
                if digit_count > max_digits {
                    return None
                }
            }
        }

        if digit_count == 0 {
            return None
        } else if !allow_zero_prefix && has_leading_zero && digit_count > 1 {
            return None
        } else {
            return Has,result
        }
    })
}


/// Read an IPv4 address.
Parser::read_ipv4_addr() i32, Ipv4Addr {

    ok<i32>, addr<Ipv4Addr> = this.read_atomically(func(p<Parser>) {
        groups<u8:4> = null
        
        for i<i32> = 0 ; i < 4 ; i += 1 {
            ok<i32>,slot<u8> = p.read_separator('.',i,func(p<Parser>){
                // Disallow octal number in IP string.
                ok<i32>,slot<u8> = p.read_number(10, Has,3, false)
            })
            if ok != Ok {
                return ok
            }
            groups[i] = slot
        }
        return Ok,Ipv4Addr::from(&groups)
    })
    
    return ok,addr
}

/// Read an IPv6 Address.
Parser::read_ipv6_addr() i32 , Ipv6Addr {
    read_groups = fn(p<Parser>, limit<i32>,groups<u16*> ) i32, u64 {
        for i<i32> = 0 ;i < limit ; i += 1 {
            // Try to read a trailing embedded IPv4 address. There must be
            // at least two groups left.
            if i < limit - 1 {
                ok<i32>,ipv4<Ipv4Addr> = p.read_separator(':', i, fn(p<Parser>){
                        ok<i32>,addr<u64> = p.read_ipv4_addr()
                        return ok,addr
                    } 
                )

                if ok {
                    one<u8>, two<u8>, three<u8>, four<u8> = ipv4.octets()
                    groups[i + 0] = tou16(one,two)
                    groups[i + 1] = tou16(three,four)
                    return Ok,i + 2
                }
            }

            ok<i32>, group<u16> = p.read_separator(':', i, fn(p<Parser>){
                    p.read_number(16, Has,4, true)
                } 
            )
            if ok == None  return None, i

            groups[i] = group
        }
        return None, limit
    }

    ok<i32>, ret<Ipv4Addr> = this.read_ipv6_atomically(fn(p<Parser>) {
        // Read the front part of the address; either the whole thing, or up
        // to the first ::
        head<u16:8> = null
        head_ipv4<i32>,head_size<i32> = read_groups(p, &head)

        if head_size == 8 {
            return Has,Ipv6Addr::from_u16(&head)
        }

        // IPv4 part is not allowed before `::`
        if head_ipv4 {
            return None
        }

        // Read `::` if previous code parsed less than 8 groups.
        // `::` indicates one or more groups of 16 bits of zeros.
        has<i32> = p.read_given_char(':')
        if has != Ok return has
        has<i32> =p.read_given_char(':')
        if has != Ok return has

        // Read the back part of the address. The :: must contain at least one
        // set of zeroes, so our max length is 7.
        tail<u16:7> = null
        limit<i32> = 8 - (head_size + 1)

        tail_<i32>,tail_size<i32> = read_groups(p,limit,&tail)

        // Concat the head and tail of the IP address
        copy_tail_to_head_u16(head, 8 ,tail , tail_size)

        return Has, Ipv6Addr::from_u16(&head)
    })

    return ok, ret
}

/// Read a `:` followed by a port in base 10.
Parser::read_port() i32,u16 {
    has<i32> , ret<u16> = this.read_atomically(fn(p<Parser>) {
        has<i32> = p.read_given_char(':')
        if has != Ok {
            return has
        }
        has,ret<i32> = p.read_number(10, None, None, true)
        return has,ret
    })
    return has,ret
}

/// Read a `%` followed by a scope ID in base 10.
Parser::read_scope_id() i32,u32 {
    has<i32> , ret<u32> = this.read_atomically(fn(p<Parser>) {
        has<i32> = p.read_given_char('%')
        if has != Ok {
            return has
        }
        ret<i32> , has<u32> = p.read_u32_number(10, None,None, true)
    })
    return has,ret
}

/// Read an IPv4 address with a port.
Parser::read_socket_addr_v4() i32 , SocketAddrV4 {
    ok<i32> , ret<SocketAddrV4> = this.read_sock_atomically(fn(p<Parser>) {
        has<i32> ,ip<Ipv4Addr> = p.read_ipv4_addr()
        if has != Ok return has

        has, port<u16> = p.read_port()
        if has != Ok return has

        return Ok , SocketAddrV4::new(ip,port)
    })
    return ok, ret
}

/// Read an IPv6 address with a port.
Parser::read_socket_addr_v6() i32,SocketAddrV6 {
    ok<i32> , addr<SocketAddrV6> = this.read_sockv6_atomically(fn(p<Parser>) {
        has<i32> = p.read_given_char('[')
        if has != Ok return has

        has<i32>, ip<Ipv6Addr> = p.read_ipv6_addr()
        if has != Ok return has

        has, scope_id<u32> = p.read_scope_id()
        if has != Ok {
                scope_id = 0
        }

        has = p.read_given_char(']')
        if has != Ok return has

        has, port<u16> = p.read_port()
        if has != Ok return has

        return Ok, SocketAddrV6::new(ip,port,0,scope_id)
    })
    return ok, addr
}

/// Read an IP address with a port
Parser::read_socket_addr() i32 , SocketAddr {
    ok<i32>, addr<SocketAddrV4> = this.read_socket_addr_v4()
    if ok {
        return ok,addr
    }

    ok, addr_v6<SocketAddrV6> = this.read_socket_addr_v6()
    if ok {
        return ok,addr_v6
    }
    return None
}


const SocketAddr::parse_ascii(b<u8*>,len<i32>) i32,SocketAddr {
    p<Parser> = Parser::new(b,len)
    ok<i32> , ret<p.parse_with(fn(p<Parser>) {
        has<i32> , ret<SocketAddr> = p.read_socket_addr()
    },Socket)
    return ok,ret
}

enum  {
    Ip,
    Ipv4,
    Ipv6,
    Socket,
    SocketV4,
    SocketV6,
}
fn err_description(kind<i32>) i8* {
    match kind {
        Ip => return "invalid IP address syntax",
        Ipv4 => return "invalid IPv4 address syntax",
        Ipv6 => return "invalid IPv6 address syntax",
        Socket => return "invalid socket address syntax",
        SocketV4 => return "invalid IPv4 socket address syntax",
        SocketV6 => return "invalid IPv6 socket address syntax",
    }
}
