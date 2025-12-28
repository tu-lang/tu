use sys
use string

//module
MOD_STD_ID:i32 =  1;
MOD_NETIO_ID:i32 =  2;
MOD_ASYNC_RUNTIME_ID:i32     = 3;
MOD_WS_ID:i32     = 4;
// layer
MOD_OS<i32> = 1
MOD_CUSTOM<i32> = 2
MOD_IO_SIMPLE<i32> = 3
MOD_SIMPLE<i32> = 4
MOD_IO<i32> = 5
MOD_PROTOCOL<i32> = 6
MOD_SEND_QUEUE<i32> = 7
MOD_CAPCITY<i32> = 8
MOD_URL<i32> = 9
MOD_TLS<i32> = 10


fn encode_error(layer<i32>, module<i32>, error<i32>) i32 {
    err<i32> =  ((layer & 0xFF) << 24) |
    ((module & 0xFF) << 16) |
    (error & 0xFFFF)
    return 0 - err
}

fn decode_error(code<i32>)  i32, i32, i32{
    if code > 0 {
        code = 0 - code
    }
    layer<i32>  = (code >> 24) & 0xFF
    module<i32> = (code >> 16) & 0xFF
    error<i32>  =  code        & 0xFFFF
    return layer, module, error
}

fn decode_error_code(code<i32>) i32 {
    return code        & 0xFFFF
}

pub fn last_error(code<i32>)  i32 {
    sys.decode_error_code(code)
}

pub fn errormsg(code<i32>)  {
    layer<i32>, module<i32> = decode_error(code)

    layer_name<i8*> = layer_name(layer)
    module_name<i8*> = module_name(module)
    message<i8*> = error_message(code)

    return fmt.sprintf(
        "%s :: %s :: %s",
        string.new(layer_name),
        string.new(module_name),
        string.new(message)
    )
}


// paths must not contain interior null bytes
InvalidInputPathContainInteriorNullByte<i32> = -16908341
// parse error
OtherParse<i32> = -16908354

// layer=1, module=1 : (1<<24)|(1<<16)|X  = 0x01010000 + X
/// An entity was not found, often a file.
NotFound<i32> = 16908289      // 0x01020001
/// The operation lacked the necessary privileges to complete.
PermissionDenied<i32> = 16908290
/// The connection was refused by the remote server.
ConnectionRefused<i32> = 16908291
/// The connection was reset by the remote server.
ConnectionReset<i32> = 16908292
/// The remote host is not reachable.
HostUnreachable<i32> = 16908293
/// The network containing the remote host is not reachable.
NetworkUnreachable<i32> = 16908294
/// The connection was aborted (terminated) by the remote server.
ConnectionAborted<i32> = 16908295
/// The network operation failed because it was not connected yet.
NotConnected<i32> = 16908296
/// A socket address could not be bound because the address is already in use elsewhere.
AddrInUse<i32> = 16908297
/// A nonexistent interface was requested or the requested address was not local.
AddrNotAvailable<i32> = 16908298
/// The system's networking is down.
NetworkDown<i32> = 16908299
/// The operation failed because a pipe was closed.
BrokenPipe<i32> = 16908300
/// An entity already exists, often a file.
AlreadyExists<i32> = 16908301
/// The operation needs to block to complete, but the blocking operation was requested to not occur.
WouldBlock<i32> = 16908302
NotADirectory<i32> = 16908303
IsADirectory<i32> = 16908304
DirectoryNotEmpty<i32> = 16908305
ReadOnlyFilesystem<i32> = 16908306
FilesystemLoop<i32> = 16908307
StaleNetworkFileHandle<i32> = 16908308
InvalidInput<i32> = 16908309
InvalidData<i32> = 16908310
TimedOut<i32> = 16908311
WriteZero<i32> = 16908312
StorageFull<i32> = 16908313
NotSeekable<i32> = 16908314
FilesystemQuotaExceeded<i32> = 16908315
FileTooLarge<i32> = 16908316
ResourceBusy<i32> = 16908317
ExecutableFileBusy<i32> = 16908318
Deadlock<i32> = 16908319
CrossesDevices<i32> = 16908320
TooManyLinks<i32> = 16908321
InvalidFilename<i32> = 16908322
ArgumentListTooLong<i32> = 16908323
Interrupted<i32> = 16908324
Unsupported<i32> = 16908325
UnexpectedEof<i32> = 16908326
OutOfMemory<i32> = 16908327
Other<i32> = 16908328
Uncategorized<i32> = 16908329

// formatter error
UncategorizedFormatter<i32> = 16908330
// failed to write whole buffer
WriteZeroFailedToWriteWholeBuffer<i32> = 16908331
// failed to fill whole buffer
UnexpectedEofFailedFillWholeBuffer<i32> = 16908332
// cursor position exceeds maximum possible vector length
InvalidInputCursorExceedMaximum<i32> = 16908333
// invalid seek to a negative or overflowing position
InvalidInputSeekNegativeOverflowing<i32> = 16908334
// invalid socket address
InvalidInputSocketAddress<i32> = 16908335
// invalid port value
InvalidInputPortValue<i32> = 16908336
// invalid argument
InvalidInputArgument<i32> = 16908337
// file name contained an unexpected NUL byte
InvalidInputUnexpectedNulByte<i32> = 16908338
// could not resolve to any addresses
InvalidInputCouldNotResolveAddress<i32> = 16908339
// path must be shorter than SUN_LEN
InvalidInputPathShorterSunLen<i32> = 16908340
// no addresses to send data to
InvalidInputNoAddressSendData<i32> = 16908342
// libc os inprogress
OS_EINPROGRESS<i32> = 16842807

