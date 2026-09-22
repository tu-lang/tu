use runtime
use fmt
use string
use std

//open syscall; implement by asm
fn open(filename<i8*> , flags<i64> , mode<i64>)

//read syscall ; implement by asm
fn read(fd<i64> , buffer<u64*> , size<u64>)

//write syscall; implement by asm
fn write(fd<i64>,buffer<i8*>,size<u64>)

//close syscall; implement by asm
fn close(fd<i64>)

//seek syscall ; implement by asm
fn seek(fd<i64> , offset<i64> , mode<i64>)

//stat syscall; implement by syscall/sys_std_amd64.s
fn stat(filename<i8*>,statbuf<Stat>)

//fstat syscall; implement by syscall/sys_std_amd64.s
fn fstat(fd<i64>,statbuf<Stat>)

//lstat syscall; implement by syscall/sys_std_amd64.s
fn lstat(filename<i8*>,statbuf<Stat>)

//fwrite
fn fwrite(buffer<i8*> , size<u64> , count<u64> , fd<u64*>){
	return write(fd,buffer,size * count)
}
//fopen
fn fopen(filename<i8*> , mode<i8*>){
	fd<i64> = -1
	flags<i64> = 0
	access<i32> = 438 # 0666

	if strcmp(mode,*"w") == runtime.Zero {
		flags |= O_WRONLY | O_CREAT | O_TRUNC
	}
	if strcmp(mode,*"w+") == runtime.Zero {
		flags |= O_RDWR | O_CREAT | O_TRUNC | O_BINARY
	}
	if strcmp(mode,*"r") == runtime.Zero {
		flags |= O_RDONLY
	}
	if strcmp(mode,*"r+") == runtime.Zero {
		flags |= O_RDWR | O_CREAT | O_BINARY
	}
	if strcmp(mode,*"a") == runtime.Zero {
		flags |= O_WRONLY | O_CREAT | O_APPEND
	}
	if strcmp(mode,*"a+") == runtime.Zero {
		flags |= O_RDWR | O_CREAT | O_APPEND | O_BINARY
	}
	if strcmp(mode,*"rb") == runtime.Zero {
		flags |= O_RDONLY | O_BINARY
	}
	fd = open(filename,flags,access)
	return fd
}
fn fread(fd<u64>,buffer<i8*>,size<i64>,count<i64>){
	return read(fd,buffer,size * count)
}
fn fclose(fp<u64>){
	return close(fp)
}
fn fseek(fp<u64>,offset<i64> , set<i64>){
	return seek(fp,offset,set)
}

class File {
	fd
	open 
	size
	filepath = filepath
	unsafe func init(filepath<runtime.Value>,perm<runtime.Value>){
		this.open = false
		if filepath == null {
			fmt.println("File::init null filepath")
			return null
		}
		if filepath.data == null {
			fmt.println("File::init empty filepath")
			return null
		}	
		ret<i32> = null
		if perm == null ret = fopen(filepath.data,*"r")
		else 			ret = fopen(filepath.data,perm.data)

		if ret == null || ret < 0{
			fmt.print("fopen failed\n")
			return null
		}
		this.size =  int(fseek(ret,runtime.Null,SEEK_END))

		fseek(ret,runtime.Null,SEEK_SET)
		this.open = true
		this.fd = ret
	}
	func IsOpen() {
		return this.open
	}
	func Size(){
		return this.size
	}
	unsafe func ReadAllNative(){
		sv<runtime.Value> = this.size
		s<i32> = 0
		if sv != null {
			s = sv.data.(i32)
		}
		// last byte NUL
		fs<i32> = s + 1
		buf<i8*> = new fs
		bp<u64*> = buf
		std.memset(bp, 0, fs.(u64))
		read_size<i64> = read(this.fd, bp, s.(u64))
		if read_size != s.(i64) {
			fmt.println("fread err,",int(read_size))
			return Null
		}
		buf[s] = 0
		return buf
	}
	unsafe func ReadAll(){
		sv<runtime.Value> = this.size
		s<i32> = 0
		if sv != null {
			s = sv.data.(i32)
		}
		fs<i32> = s + 1
		buf<i8*> = new fs
		bp<u64*> = buf
		std.memset(bp, 0, fs.(u64))
		read_size<i64> = read(this.fd, bp, s.(u64))
		if read_size != s.(i64) {
			fmt.println("fread err,",int(read_size))
			return ""
		}
		buf[s] = 0
		return string.new(buf)
	}
	unsafe func Write(buffer<runtime.Value>){
		if buffer.type != runtime.String {
			return false
		}
		s<i8> = 1
		// CAUTION: should be string.Str
		size<i32> = buffer.data.(string.Str).len()
		ret<u64> = write(this.fd,buffer.data,size)
		if ret != size {
			fmt.println("fwrite err",int(ret),int(size))
			return false
		}
		return true
	}
	unsafe func NWrite(buffer<i8*>){
		size<i32> = strlen(buffer)
		ret<u64> = std.write(this.fd , buffer,size)
		if ret != size {
			fmt.print("fwrite err\n")
			return false
		}
		return true
	}
	unsafe func Close(){
		close(this.fd)
	}
}

