use runtime
use fmt
use string

//getdents syscall; implement by syscall/sys_std_amd64.s
func getdents(fd<u32> , dirent<Dirent> , count<u32>)

DT_UNKNOWN<i32> = 0
DT_FIFO<i32>    = 1
DT_CHR<i32>     = 2
DT_DIR<i32>     = 4
DT_BLK<i32>     = 6
DT_REG<i32>     = 8
DT_LNK<i32>     = 10
DT_SOCK<i32>    = 12 
DT_WHT<i32>     = 14


DIRENT_BUF_SIZE<i32> = 4096

mem Dir{
    u64     fd
    Dirent* dir
    i32     counts
    i32     pos
    i32     init
    runtime.Value* path
}
//for user space
class Dir {}
//dirent::init(type,name){
//    fmt.println(type,name)
//    this.type = type
//    this.name = name
//}
//for internal
mem Dirent{
    i64 d_ino 
    i64 d_off
    u16 d_reclen
    i8 d_name
}
class FileFd {}
//opendir
//@param  dir_path
//@return Dir
func opendir(dir_path<runtime.Value>){
     fd<i32> = open(dir_path.data,O_RDONLY | O_DIRECTORY)
     if fd < 0 {
	    fmt.vfprintf(STDOUT,string.stringfmt(
            "open %s failed ret:%d\n".(i8),
            dir_path.data,fd
        ))
        return False
     }
     dir = new Dir()
     d<Dir> = new Dir {
        fd   : fd,
        pos  : 0,
        dir  : new DIRENT_BUF_SIZE,
        init : 0,
        path : dir_path
     }
     dir.dirent = d
     return dir
}
Dir::readdir(){
    dir<Dir> = this.dirent
    //need init
    if dir.init == 0 {
        dir.init = 1
init_dents:
        counts<i32> = getdents(dir.fd,dir.dir,DIRENT_BUF_SIZE)
        if counts == -1 {
	        fmt.vfprintf(STDOUT,*"getdents failed\n")
            return False
        }
        if counts == 0 {
            return False
        }
        dir.pos = 0
        dir.counts = counts
    }
    if dir.pos >= dir.counts {
        goto init_dents
    }


    d<Dirent> = dir.dir + dir.pos
    file_name = string.new(&d.d_name)
    file_type_p<i8*> = d + d.d_reclen - 1 
    file_type = dirtype(*file_type_p)

    #incr pos
    dir.pos += d.d_reclen
    # return wrap obj
    file = new FileFd()
    file.type = file_type
    file.name = file_name
    //TODO: file.path = dir.path + "/" +file_name (mem.field + dynamic string)
    dir_address<u64> = dir.path 
    //TODO: dynmic var = mem.field => auto load(mem.field)
    dir_path = dir_address
    dir_path += "/" + file_name 
    file.path = dir_path
    return file
}
FileFd::isFile(){
    if this.type == "file" return True
    return False
}
FileFd::isDir(){
    if this.type == "directory" return True
    return False
}
func dirtype(t<i8>){
    match t {
        DT_REG : return "file"
        DT_DIR : return "directory"
        DT_FIFO: return "fifo"
        DT_SOCK: return "socket"
        DT_LNK : return "symlink"
        DT_BLK : return "blockdev"
        DT_CHR : return "chardev"
        DT_WHT : return "wht"
        DT_UNKNOWN : return "unknow"
        _      : return "invalid"
    }
}

func is_dir(filepath<runtime.Value>){
    s<Stat> = new Stat
    ret<i8> = stat(filepath.data,s)
    if ret != 0 return False

    if s.st_mode & S_IFDIR > 0 {
        return True
    }
    return False
}
func is_file(filepath<runtime.Value>){
    s<Stat> = new Stat
    ret<i8> = stat(filepath.data,s)
    if ret != 0 return False

    if s.st_mode & S_IFREG > 0 {
        return True
    }
    return False
}