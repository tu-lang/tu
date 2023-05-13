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
	if strcmp(mode,*"rb") == runtime.Zero {
		flags |= O_RDONLY | O_BINARY
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
	filepath = filepath
	func init(filepath<runtime.Value>,perm<runtime.Value>){
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
	func ReadAllNative(){
		s<i32> = *this.size
		//last pos \0
		fs<i32> = s + 1
		buf<u64*> = new fs
		read_size<i64> = read(this.fd,buf,s)
		if read_size != s {
			fmt.println("fread err,",int(read_size))
			return Null
		}
		return buf
	}
	func ReadAll(){
		s<i32> = *this.size
		//last pos \0
		fs<i32> = s + 1
		buf<u64*> = new fs
		read_size<i64> = read(this.fd,buf,s)
		if read_size != s {
			fmt.println("fread err,",int(read_size))
			return ""
		}
		return string.new(buf)
	}
	func Write(buffer<runtime.Value>){
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
	func NWrite(buffer<i8*>){
		size<i32> = strlen(buffer)
		ret<u64> = std.write(this.fd , buffer,size)
		if ret != size {
			fmt.print("fwrite err\n")
			return false
		}
		return true
	}
	func Close(){
		close(this.fd)
	}
}

