// expect: pkgmode: static symbol 'dyn_close_leaf' not exported from static package 'asyncio_net_tcp'; call an export or use unsafe
// No tu.mod (dyn): dyn code may use the asyncio.net.tcp export facade
// (listen / dialTo / Stream methods) but not its non-export engine fns.

use asyncio.net.tcp

func main() {
    tcp.dyn_close_leaf(0)
}
