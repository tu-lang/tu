// Load nested packages when callers `use netio`. Alias `sys` — root files
// already `use sys` (library/sys), which conflicts with path-tail `netio.sys`.

use netio.event
use netio.net
use netio.sys as netsys
