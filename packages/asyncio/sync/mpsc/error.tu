// Error code aliases for mpsc Sender/Receiver. Centralised so users only
// import asyncio.sync.mpsc and never reach into asyncio.error directly.

use io

SendErrorClosed<i32> = 0x0302000D
SendErrorFull<i32>   = 0x0302000A
RecvErrorEmpty<i32>  = 0x0302000C
RecvErrorClosed<i32> = 0x0302000D
MpscPushBusy<i32>      = io.Other
MpscPopEmpty<i32>      = io.NotFound
