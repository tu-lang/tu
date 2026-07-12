// Error code aliases for mpsc Sender/Receiver. Centralised so users only
// import asyncio.sync.mpsc and never reach into asyncio.error directly.

SendErrorClosed<i32> = 0x0302000D
SendErrorFull<i32>   = 0x0302000A
RecvErrorEmpty<i32>  = 0x0302000C
RecvErrorClosed<i32> = 0x0302000D
