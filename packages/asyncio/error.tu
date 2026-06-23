// asyncio error code segment 0x03_02_xxxx (io reuses 0x01_02 segment for IO codes).

Cancelled<i32>           = 0x03020001
Closed<i32>              = 0x03020002
Lagged<i32>              = 0x03020003
Elapsed<i32>             = 0x03020004
RuntimeShutdown<i32>     = 0x03020005
SpawnFailed<i32>         = 0x03020006
AlreadyConsumed<i32>     = 0x03020007
RuntimePollError<i32>    = 0x03020008
NoBudget<i32>            = 0x03020009
SendFull<i32>            = 0x0302000A
SendNoReceiver<i32>      = 0x0302000B
RecvEmpty<i32>           = 0x0302000C
ChannelClosed<i32>       = 0x0302000D
PoisonedMutex<i32>       = 0x0302000E
SignalNotRegistered<i32> = 0x0302000F
