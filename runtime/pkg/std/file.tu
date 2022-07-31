use runtime
use fmt
use string

//open syscall; implement by asm
func open(filename<i8*> , flags<i64> , mode<i64>)

//read syscall ; implement by asm
func read(fd<i64> , buffer<u64*> , size<u64>)

//write syscall; implement by asm
func write(fd<i64>,buffer<i8*>,size<u64>)

//close syscall; implement by asm
func close(fd<i64>)

//seek syscall ; implement by asm
func seek(fd<i64> , offset<i64> , mode<i64>)

//stat syscall; implement by syscall/sys_std_amd64.s
func stat(filename<i8*>,statbuf<Stat>)

//fstat syscall; implement by syscall/sys_std_amd64.s
func fstat(fd<i64>,statbuf<Stat>)

//lstat syscall; implement by syscall/sys_std_amd64.s
func lstat(filename<i8*>,statbuf<Stat>)

//fwrite
func fwrite(buffer<i8*> , size<u64> , count<u64> , fd<u64*>){
	return write(fd,buffer,size * count)
}
//fopen
func fopen(filename<i8*> , mode<i8*>){
	fd<i64> = -1
	flags<i64> = 0
	access<i32> = 438 # 0666

	if strcmp(mode,*"w") == runtime.Zero {
		flags |= O_WRONLY | O_CREAT | O_TRUNC
	}
	if strcmp(mode,*"w+") == runtime.Zero {
		flags |= O_RDWR | O_CREAT | O_TRUNC
	}
	if strcmp(mode,*"r") == runtime.Zero {
		flags |= O_RDONLY
	}
	if strcmp(mode,*"r+") == runtime.Zero {
		flags |= O_RDWR | O_CREAT 
	}
	if strcmp(mode,*"a") == runtime.Zero {
		flags |= O_WRONLY | O_CREAT | O_APPEND
	}
	if strcmp(mode,*"a+") == runtime.Zero {
		flags |= O_RDWR | O_CREAT | O_APPEND
	}
	fd = open(filename,flags,access)
	return fd
}
func fread(fd<u64>,buffer<i8*>,size<i64>,count<i64>){
	return read(fd,buffer,size * count)
}
func fclose(fp<u64>){
	return close(fp)
}
func fseek(fp<u64>,offset<i64> , set<i64>){
	return seek(fp,offset,set)
}

class File {
	fd
	open 
	size
	func init(filepath){
		this.open = false
		em<i64> = filepath
		if em == null {
			fmt.println("File::init null filepath")
			return null
		}
		if filepath == "" {
			fmt.println("File::init empty filepath")
			return null
		}	
		ret<i8> = fopen(*filepath,*"r")
		if ret == null {
			fmt.print("fopen failed\n")
			return null
		}
		this.size = fseek(ret,runtime.Null,SEEK_END)
		fseek(ret,runtime.Null,SEEK_SET)
		this.open = true
		this.fd = ret
	}
	func IsOpen() {
		return this.open
	}
	func Size(){
		return int(this.size)
	}
	func ReadAll(){
		s<i32> = this.size
		buf<u64*> = new s
		read_size<i64> = read(this.fd,buf,s)
		if read_size != s {
			fmt.println("fread err,",int(read_size))
			return ""
		}
		return string.new(buf)
	}
}

