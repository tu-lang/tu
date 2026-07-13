use io

// Sentinel: no max-digit cap when parsing numbers.
MAX_DIGITS_NONE<i32> = -1
PARSER_U32_MAX<u32> = 2147483647.(u32)

mem Parser {
    // Parsing as ASCII, so can use byte array.
    u8* state
    i32 remain
}

const Parser::new(input<u8*>, len<i32>) Parser {
    return new Parser { state: input, remain: len }
}

// Restore cursor when step_fn reports failure (None).
Parser::read_none_atomically(step_fn) i32 {
    saved_state<u8*> = this.state
    saved_len<i32> = this.remain
    has<i32> = step_fn(this)
    if has == None {
        this.state = saved_state
        this.remain = saved_len
        return None
    }
    return Has
}

Parser::read_u8_atomically(step_fn) i32, u8 {
    saved_state<u8*> = this.state
    saved_len<i32> = this.remain
    has<i32>, result<u8> = step_fn(this)
    if has == None {
        this.state = saved_state
        this.remain = saved_len
        return None, 0
    }
    return Has, result
}

Parser::read_u16_atomically(step_fn) i32, u16 {
    saved_state<u8*> = this.state
    saved_len<i32> = this.remain
    has<i32>, result<u16> = step_fn(this)
    if has == None {
        this.state = saved_state
        this.remain = saved_len
        return None, 0
    }
    return Has, result
}

Parser::read_u32_atomically(step_fn) i32, u32 {
    saved_state<u8*> = this.state
    saved_len<i32> = this.remain
    has<i32>, result<u32> = step_fn(this)
    if has == None {
        this.state = saved_state
        this.remain = saved_len
        return None, 0
    }
    return Has, result
}

Parser::read_ipv4_atomically(step_fn) i32, Ipv4Addr {
    saved_state<u8*> = this.state
    saved_len<i32> = this.remain
    has<i32>, result<Ipv4Addr> = step_fn(this)
    if has == None {
        this.state = saved_state
        this.remain = saved_len
        return None, null
    }
    return Has, result
}

Parser::read_ipv6_atomically(step_fn) i32, Ipv6Addr {
    saved_state<u8*> = this.state
    saved_len<i32> = this.remain
    has<i32>, result<Ipv6Addr> = step_fn(this)
    if has == None {
        this.state = saved_state
        this.remain = saved_len
        return None, null
    }
    return Has, result
}

Parser::read_sock_atomically(step_fn) i32, SocketAddrV4 {
    saved_state<u8*> = this.state
    saved_len<i32> = this.remain
    has<i32>, result<SocketAddrV4> = step_fn(this)
    if has == None {
        this.state = saved_state
        this.remain = saved_len
        return None, null
    }
    return Has, result
}

Parser::read_sock6_atomically(step_fn) i32, SocketAddrV6 {
    saved_state<u8*> = this.state
    saved_len<i32> = this.remain
    has<i32>, result<SocketAddrV6> = step_fn(this)
    if has == None {
        this.state = saved_state
        this.remain = saved_len
        return None, null
    }
    return Has, result
}

// Legacy generic atomic helper kept for older call sites.
Parser::read_atomically(step_fn) i32, u64 {
    saved_state<u8*> = this.state
    saved_len<i32> = this.remain
    has<i32>, result<u64> = step_fn(this)
    if has == None {
        this.state = saved_state
        this.remain = saved_len
        return None, 0
    }
    return Has, result
}

// Run step_fn and require the entire input to be consumed.
Parser::parse_with(step_fn, kind<i32>) i32, SocketAddr {
    has<i32>, result<SocketAddr> = step_fn(this)
    if has == None {
        return io.OtherParse, null
    }
    if this.remain == 0 {
        return io.Ok, result
    }
    return io.OtherParse, null
}

Parser::peek_char() i32, i8 {
    if this.remain == 0 {
        return None, 0
    }
    return Has, this.state[0]
}

Parser::read_char() i32, i8 {
    if this.remain == 0 {
        return None, 0
    }
    first<i8> = this.state[0]
    this.state += 1
    this.remain -= 1
    return Has, first
}

// Package-level bodies: inline fn callbacks may only contain a single return.

fn parser_given_char_body(p<Parser>, target<i8>) i32 {
    has<i32>, c<i8> = p.read_char()
    if has == None {
        return None
    }
    if c == target {
        return Has
    }
    return None
}

Parser::read_given_char(target<i8>) i32 {
    return this.read_none_atomically(fn(p) {
        return parser_given_char_body(p, target)
    })
}

Parser::read_u8_given_char(target<i8>) i32 {
    return this.read_given_char(target)
}

Parser::read_u16_given_char(target<i8>) i32 {
    return this.read_given_char(target)
}

fn parser_u8_sep_body(p<Parser>, sep<i8>, index<i32>, step_fn) i32, u8 {
    if index > 0 {
        if p.read_u8_given_char(sep) == None {
            return None, 0
        }
    }
    return step_fn(p)
}

fn parser_u16_sep_body(p<Parser>, sep<i8>, index<i32>, step_fn) i32, u16 {
    if index > 0 {
        if p.read_u16_given_char(sep) == None {
            return None, 0
        }
    }
    return step_fn(p)
}

fn parser_ipv4_sep_body(p<Parser>, sep<i8>, index<i32>, step_fn) i32, Ipv4Addr {
    if index > 0 {
        if p.read_given_char(sep) == None {
            return None, null
        }
    }
    return step_fn(p)
}

fn parser_sep_body(p<Parser>, sep<i8>, idx<i32>, step_fn) i32, u64 {
    if idx > 0 {
        if p.read_given_char(sep) == None {
            return None, 0
        }
    }
    return step_fn(p)
}

Parser::read_u8_separator(sep<i8>, index<i32>, step_fn) i32, u8 {
    has<i32>, ret<u8> = this.read_u8_atomically(fn(p) {
        return parser_u8_sep_body(p, sep, index, step_fn)
    })
    return has, ret
}

Parser::read_u16_separator(sep<i8>, index<i32>, step_fn) i32, u16 {
    has<i32>, ret<u16> = this.read_u16_atomically(fn(p) {
        return parser_u16_sep_body(p, sep, index, step_fn)
    })
    return has, ret
}

Parser::read_ipv4_separator(sep<i8>, index<i32>, step_fn) i32, Ipv4Addr {
    has<i32>, ret<Ipv4Addr> = this.read_ipv4_atomically(fn(p) {
        return parser_ipv4_sep_body(p, sep, index, step_fn)
    })
    return has, ret
}

Parser::read_separator(sep<i8>, index<u64>, step_fn) i32, u64 {
    idx<i32> = index.(i32)
    has<i32>, ret<u64> = this.read_atomically(fn(p) {
        return parser_sep_body(p, sep, idx, step_fn)
    })
    return has, ret
}

fn parser_u32_digit_body(p<Parser>, radix<u32>) i32, u32 {
    ok<i32>, c<i8> = p.read_char()
    if ok != Has {
        return None, 0
    }
    tok<i32>, d<i32> = toDigit(c, radix.(i32))
    if tok != Ok {
        return None, 0
    }
    return Has, d.(u32)
}

fn parser_u32_number_body(p<Parser>, radix<u32>, max_digits<i32>, allow_zero_prefix<i32>) i32, u32 {
    result<u32> = 0
    digit_count<i32> = 0
    has_leading_zero<i32> = 0
    peek_has<i32>, peek_c<i8> = p.peek_char()
    if peek_has == Has && peek_c == '0' {
        has_leading_zero = 1
    }
    loop {
        has<i32>, digit<u32> = p.read_u32_atomically(fn(p2) {
            return parser_u32_digit_body(p2, radix)
        })
        if has != Has {
            break
        }
        if radix != 0 && result > (PARSER_U32_MAX - digit) / radix {
            return None, 0
        }
        result = result * radix + digit
        digit_count += 1
        if max_digits != MAX_DIGITS_NONE && digit_count > max_digits {
            return None, 0
        }
    }
    if digit_count == 0 {
        return None, 0
    }
    if allow_zero_prefix == 0 && has_leading_zero != 0 && digit_count > 1 {
        return None, 0
    }
    return Has, result
}

Parser::read_u32_number(radix<u32>, max_digits<i32>, allow_zero_prefix<i32>) i32, u32 {
    has<i32>, ret<u32> = this.read_u32_atomically(fn(p) {
        return parser_u32_number_body(p, radix, max_digits, allow_zero_prefix)
    })
    return has, ret
}

Parser::read_u16_number(radix<u32>, max_digits<i32>, allow_zero_prefix<i32>) i32, u16 {
    has<i32>, v<u32> = this.read_u32_number(radix, max_digits, allow_zero_prefix)
    if has != Has {
        return None, 0
    }
    return Has, v.(u16)
}

Parser::read_u8_number(radix<u32>, max_digits<i32>, allow_zero_prefix<i32>) i32, u8 {
    has<i32>, v<u32> = this.read_u32_number(radix, max_digits, allow_zero_prefix)
    if has != Has {
        return None, 0
    }
    return Has, v.(u8)
}

// Back-compat wrapper: digits==Has enables max_digits, else unlimited.
Parser::read_number(radix<u32>, digits<i32>, max_digits<i32>, allow_zero_prefix<i32>) i32, u32 {
    cap<i32> = MAX_DIGITS_NONE
    if digits == Has {
        cap = max_digits
    }
    has<i32>, ret<u32> = this.read_u32_number(radix, cap, allow_zero_prefix)
    return has, ret
}

fn parser_ipv4_octet_body(p<Parser>) i32, u8 {
    has<i32>, v<u8> = p.read_u8_number(10, 3, 0)
    return has, v
}

fn parser_ipv4_addr_body(p<Parser>) i32, Ipv4Addr {
    groups<u8:4> = null
    for i<i32> = 0 ; i < 4 ; i += 1 {
        ok<i32>, slot<u8> = p.read_u8_separator('.'.(i8), i, fn(p2) {
            return parser_ipv4_octet_body(p2)
        })
        if ok != Has {
            return None, null
        }
        groups[i] = slot
    }
    return Has, Ipv4Addr::from(&groups)
}

Parser::read_ipv4_addr() i32, Ipv4Addr {
    has<i32>, ret<Ipv4Addr> = this.read_ipv4_atomically(fn(p) {
        return parser_ipv4_addr_body(p)
    })
    return has, ret
}

fn parser_ipv6_read_groups(p<Parser>, groups<u16*>, limit<i32>) i32, i32 {
    for i<i32> = 0 ; i < limit ; i += 1 {
        if i < limit - 1 {
            ok<i32>, ipv4<Ipv4Addr> = p.read_ipv4_separator(':'.(i8), i, fn(p2) {
                return p2.read_ipv4_addr()
            })
            if ok == Has {
                one<u8>, two<u8>, three<u8>, four<u8> = ipv4.octets()
                groups[i + 0] = tou16(one, two)
                groups[i + 1] = tou16(three, four)
                return i + 2, 1
            }
        }
        ok<i32>, group<u16> = p.read_u16_separator(':'.(i8), i, fn(p2) {
            return p2.read_u16_number(16, 4, 1)
        })
        if ok != Has {
            return i, 0
        }
        groups[i] = group
    }
    return limit, 0
}

fn parser_ipv6_addr_body(p<Parser>) i32, Ipv6Addr {
    head<u16:8> = null
    head_size<i32>, head_ipv4<i32> = parser_ipv6_read_groups(p, &head, 8)
    if head_size == 8 {
        return Has, Ipv6Addr::from_u16(&head)
    }
    if head_ipv4 != 0 {
        return None, null
    }
    has<i32> = p.read_given_char(':'.(i8))
    if has != Has {
        return None, null
    }
    has = p.read_given_char(':'.(i8))
    if has != Has {
        return None, null
    }
    tail<u16:7> = null
    limit<i32> = 8 - (head_size + 1)
    tail_size<i32>, _<i32> = parser_ipv6_read_groups(p, &tail, limit)
    copy_tail_to_head_u16(&head, 8, &tail, tail_size)
    return Has, Ipv6Addr::from_u16(&head)
}

Parser::read_ipv6_addr() i32, Ipv6Addr {
    has<i32>, ret<Ipv6Addr> = this.read_ipv6_atomically(fn(p) {
        return parser_ipv6_addr_body(p)
    })
    return has, ret
}

fn parser_read_port_num_body(p<Parser>) i32, u16 {
    has<i32> = p.read_u16_given_char(':'.(i8))
    if has != Has {
        return None, 0
    }
    ph<i32>, pv<u16> = p.read_u16_number(10, MAX_DIGITS_NONE, 1)
    return ph, pv
}

Parser::read_port_num() i32, u16 {
    has<i32>, ret<u16> = this.read_u16_atomically(fn(p) {
        return parser_read_port_num_body(p)
    })
    return has, ret
}

fn parser_read_scope_id_body(p<Parser>) i32, u32 {
    has<i32> = p.read_given_char('%'.(i8))
    if has != Has {
        return None, 0
    }
    sh<i32>, sv<u32> = p.read_u32_number(10, MAX_DIGITS_NONE, 1)
    return sh, sv
}

Parser::read_scope_id() i32, u32 {
    has<i32>, ret<u32> = this.read_u32_atomically(fn(p) {
        return parser_read_scope_id_body(p)
    })
    return has, ret
}

fn parser_read_socket_addr_v4_body(p<Parser>) i32, SocketAddrV4 {
    ih<i32>, ip<Ipv4Addr> = p.read_ipv4_addr()
    if ih != Has {
        return None, null
    }
    ph<i32>, port_num<u16> = p.read_port_num()
    if ph != Has {
        return None, null
    }
    sa<SocketAddrV4> = socket_addr_v4_from_ipv4_port(ip, port_num)
    return Has, sa
}

fn parser_read_socket_addr_v6_body(p<Parser>) i32, SocketAddrV6 {
    bh<i32> = p.read_given_char('['.(i8))
    if bh != Has {
        return None, null
    }
    ih<i32>, ip<Ipv6Addr> = p.read_ipv6_addr()
    if ih != Has {
        return None, null
    }
    sh<i32>, scope_raw<u32> = p.read_scope_id()
    scope_id<u32> = 0
    if sh == Has {
        scope_id = scope_raw
    }
    cbh<i32> = p.read_given_char(']'.(i8))
    if cbh != Has {
        return None, null
    }
    ph<i32>, port_num<u16> = p.read_port_num()
    if ph != Has {
        return None, null
    }
    sa<SocketAddrV6> = socket_addr_v6_from_parts(ip, port_num, 0, scope_id)
    return Has, sa
}

Parser::read_socket_addr_v4() i32, SocketAddrV4 {
    has<i32>, ret<SocketAddrV4> = this.read_sock_atomically(fn(p) {
        return parser_read_socket_addr_v4_body(p)
    })
    return has, ret
}

Parser::read_socket_addr_v6() i32, SocketAddrV6 {
    has<i32>, ret<SocketAddrV6> = this.read_sock6_atomically(fn(p) {
        return parser_read_socket_addr_v6_body(p)
    })
    return has, ret
}

Parser::read_socket_addr() i32, SocketAddr {
    v4h<i32>, v4<SocketAddrV4> = this.read_socket_addr_v4()
    if v4h == Has {
        return Has, socket_addr_from_v4(v4)
    }
    v6h<i32>, v6<SocketAddrV6> = this.read_socket_addr_v6()
    if v6h == Has {
        return Has, socket_addr_from_v6(v6)
    }
    return None, null
}

fn parse_ascii_bytes(b<u8*>, len<i32>) i32, SocketAddr {
    p<Parser> = Parser::new(b, len)
    ok<i32>, ret<SocketAddr> = p.parse_with(fn(p2) {
        rh<i32>, rv<SocketAddr> = p2.read_socket_addr()
        return rh, rv
    }, 0)
    return ok, ret
}
