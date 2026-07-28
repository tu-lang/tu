// Library `net` bridges for asyncio.net.
//
// Package asyncio.net has short-name `net`. Importing the library as
// `use net` / `use net as libnet` registers path "net" and poisons
// getPackage for local mem types. Call these from asyncio.util instead.

use net as libnet
use io
use string
use std

fn net_parse_ascii_bytes_bits(b<u8*>, len<i32>) i32, u64 {
    err<i32>, bits<u64> = libnet.parse_ascii_bytes_bits(b, len)
    return err, bits
}

// Typed parse (Pillar B cross-pkg Mem return). On error returns null SocketAddr.
fn net_parse_ascii_bytes(b<u8*>, len<i32>) i32, libnet.SocketAddr {
    err<i32>, bits<u64> = libnet.parse_ascii_bytes_bits(b, len)
    if err != io.Ok {
        empty<libnet.SocketAddr> = null
        return err, empty
    }
    addr<libnet.SocketAddr> = bits.(libnet.SocketAddr)
    return err, addr
}

fn net_strto_socket_addrs(host<string.String>) i32, std.Array {
    err<i32>, list<std.Array> = libnet.strto_socket_addrs(host)
    return err, list
}

fn net_socket_addr_from_bits(bits<u64>) libnet.SocketAddr {
    return bits.(libnet.SocketAddr)
}

fn net_socket_addr_to_bits(addr<libnet.SocketAddr>) u64 {
    return addr.(u64)
}

// Append lowercase hex for a host-order u16 (catfmt has no %x).
fn cat_hex_u16(strl<string.Str>, val<u16>) string.Str {
    buf_o<i8:8> = null
    buf<i8*> = &buf_o
    n<i64> = 0
    n = val
    std.itoa(n, buf, 16.(i32))
    return strl.cat(buf)
}

// Format SocketAddr for parse round-trip tests.
fn net_socket_addr_to_string(addr<libnet.SocketAddr>) string.String {
    return net_socket_addr_to_string_bits(addr.(u64))
}

// catfmt: use %i (not %d — literal 'd'; not %u — empty for zero).
fn net_socket_addr_to_string_bits(bits<u64>) string.String {
    addr<libnet.SocketAddr> = bits.(libnet.SocketAddr)
    if libnet.socket_addr_is_v4(addr) {
        v4<libnet.SocketAddrV4> = libnet.socket_addr_v4_store(addr)
        ip<libnet.Ipv4Addr> = v4.ip()
        a<u8>, b<u8>, c<u8>, d<u8> = ip.octets()
        port<u16> = v4.port_num()
        ai<i64> = 0
        bi<i64> = 0
        ci<i64> = 0
        di<i64> = 0
        pi<i64> = 0
        ai = a
        bi = b
        ci = c
        di = d
        pi = port
        strl<string.Str> = string.empty()
        strl = strl.catfmt(*"%i.%i.%i.%i:%i", ai, bi, ci, di, pi)
        return string.S(strl)
    }
    v6<libnet.SocketAddrV6> = libnet.socket_addr_v6_store(addr)
    ip6<libnet.Ipv6Addr> = v6.ip()
    segs<u16*> = ip6.segments()
    port6<u16> = v6.port_num()
    strl6<string.Str> = string.empty()
    strl6 = strl6.cat(*"[")
    strl6 = cat_hex_u16(strl6, segs[0])
    strl6 = strl6.cat(*":")
    strl6 = cat_hex_u16(strl6, segs[1])
    strl6 = strl6.cat(*":")
    strl6 = cat_hex_u16(strl6, segs[2])
    strl6 = strl6.cat(*":")
    strl6 = cat_hex_u16(strl6, segs[3])
    strl6 = strl6.cat(*":")
    strl6 = cat_hex_u16(strl6, segs[4])
    strl6 = strl6.cat(*":")
    strl6 = cat_hex_u16(strl6, segs[5])
    strl6 = strl6.cat(*":")
    strl6 = cat_hex_u16(strl6, segs[6])
    strl6 = strl6.cat(*":")
    strl6 = cat_hex_u16(strl6, segs[7])
    strl6 = strl6.cat(*"]:")
    pi6<i64> = 0
    pi6 = port6
    strl6 = strl6.catfmt(*"%i", pi6)
    return string.S(strl6)
}
