// Compile-cover smoke: force-parse every asyncio / netio package directory.
// Catches syntax / layout breaks (e.g. stray trailing `}`) that behavioral
// int_* never import. Not a behavioral substitute for those suites.
//
// Keep the `use` list in sync when adding packages under packages/asyncio
// or packages/netio.

use fmt

use asyncio
use asyncio.error as aerr
use asyncio.fs
use asyncio.io as aio
use asyncio.io.std as aiostd
use asyncio.io.util as ioutil
use asyncio.macros
use asyncio.net as anet
use asyncio.net.tcp as atcp
use asyncio.net.udp as audp
use asyncio.net.unix as aunix
use asyncio.process
use asyncio.runtime as rt
use asyncio.runtime.blocking as rtblk
use asyncio.runtime.io as rtio
use asyncio.runtime.scheduler as sch
use asyncio.runtime.signal as rtsig
use asyncio.runtime.time as rttime
use asyncio.signal as asig
use asyncio.sync as asyncsync
use asyncio.sync.mpsc as mpsc
use asyncio.task
use asyncio.time as atime
use asyncio.util
use asyncio.wrapper as awrap
use asyncio.wrapper.types as awtypes

use netio
use netio.event as nevent
use netio.net.tcp as ntcp
use netio.net.udp as nudp
use netio.net.uds as nuds
use netio.sys as netsys
use netio.sys.uds as netsysuds

fn main() {
	fmt.println("int_pkg_compile ok")
}
