// Load nested packages when callers `use netio`. Alias `sys` — root files
// already `use sys` (library/sys), which conflicts with path-tail `netio.sys`.

use netio.event
// Mother net::{tcp,udp,uds}; each is its own Tu package (short-name != `net`).
// Pull tcp+udp with `use netio`; uds loads via asyncio.net.unix when needed.
use netio.net.tcp
use netio.net.udp
use netio.sys as netsys
