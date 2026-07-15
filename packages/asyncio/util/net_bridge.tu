// Library `net` bridges for asyncio.net.
//
// Package asyncio.net has short-name `net`. Importing the library as
// `use net` / `use net as libnet` registers path "net" and poisons
// getPackage for local mem types. Call these from asyncio.util instead.

use net as libnet
use string
use std

fn net_parse_ascii_bytes_bits(b<u8*>, len<i32>) i32, u64 {
    err<i32>, bits<u64> = libnet.parse_ascii_bytes_bits(b, len)
    return err, bits
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
