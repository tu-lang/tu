
use io

FULL_BACKTRACE_DEFAULT<i32> = false
fn decode_error_code(errno<i32>) i32 {
    match errno {
        E2BIG : return io.ArgumentListTooLong,
        EADDRINUSE : return io.AddrInUse,
        EADDRNOTAVAIL : return io.AddrNotAvailable,
        EBUSY : return io.ResourceBusy,
        ECONNABORTED : return io.ConnectionAborted,
        ECONNREFUSED : return io.ConnectionRefused,
        ECONNRESET : return io.ConnectionReset,
        EDEADLK : return io.Deadlock,
        EDQUOT : return io.FilesystemQuotaExceeded,
        EEXIST : return io.AlreadyExists,
        EFBIG : return io.FileTooLarge,
        EHOSTUNREACH : return io.HostUnreachable,
        EINTR : return io.Interrupted,
        EINVAL : return io.InvalidInput,
        EISDIR : return io.IsADirectory,
        ELOOP : return io.FilesystemLoop,
        ENOENT : return io.NotFound,
        ENOMEM : return io.OutOfMemory,
        ENOSPC : return io.StorageFull,
        ENOSYS : return io.Unsupported,
        EMLINK : return io.TooManyLinks,
        ENAMETOOLONG : return io.InvalidFilename,
        ENETDOWN : return io.NetworkDown,
        ENETUNREACH : return io.NetworkUnreachable,
        ENOTCONN : return io.NotConnected,
        ENOTDIR : return io.NotADirectory,
        ENOTEMPTY : return io.DirectoryNotEmpty,
        EPIPE : return io.BrokenPipe,
        EROFS : return io.ReadOnlyFilesystem,
        ESPIPE : return io.NotSeekable,
        ESTALE : return io.StaleNetworkFileHandle,
        ETIMEDOUT : return io.TimedOut,
        ETXTBSY : return io.ExecutableFileBusy,
        EXDEV : return io.CrossesDevices,

        EACCES | EPERM : return io.PermissionDenied,
        EINPROGRESS : return io.OS_EINPROGRESS,
        // These two constants can have the same value on some systems,
        // but different values on others, so we can't use a match
        // clause
		EAGAIN | EWOULDBLOCK: return io.WouldBlock,
        _ : return io.Uncategorized
    }
}

fn cvt(t<i32>) i32,u64 {
    if t < 0 { 
		return decode_error_code(t)	
	}else {
		Ok,t
	}
}

