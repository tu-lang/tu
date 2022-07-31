ZERO<i64> = 0
Done<i64> = 1

STDERR<i64> = 2
STDOUT<i64> = 1
STDIN<i64>  = 0

EOF<i64>    = -1

O_RDONLY<i64> = 0
O_WRONLY<i64> = 1
O_RDWR<i64>   = 2
O_CREAT<i64>  = 64
O_TRUNC<i64>  = 512
O_APPEND<i64> = 1024
O_DIRECTORY<i64> = 65536

S_IFDIR<i64> = 16384 
S_IFREG<i64> = 32768


SEEK_SET<i64> = 0
SEEK_CUR<i64> = 1
SEEK_END<i64> = 2

//file stat
mem Stat {
    u64 st_dev
    u64 st_ino
    u64 st_nlink
    u32 st_mode
    i32 st_uid
    i32 st_gid
    i32 __pad
    u64 std_rdev
    u64 st_size
    u64 st_blksize
    u64 st_blocks
    u64 st_atime
    u64 st_mtime
    u64 st_ctime
    u64 reserved[3]
}