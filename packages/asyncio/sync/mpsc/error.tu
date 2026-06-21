// Error code aliases for mpsc Sender/Receiver. Centralised so users only
// import asyncio.sync.mpsc and never reach into asyncio.error directly.

use asyncio.error as aerr

SendErrorClosed<i32> = aerr.ChannelClosed
SendErrorFull<i32>   = aerr.SendFull
RecvErrorEmpty<i32>  = aerr.RecvEmpty
RecvErrorClosed<i32> = aerr.ChannelClosed

