use std
use fmt
use os 

//func fwrite(buffer<i8*> , size<u64> , count<u64> , fd<u64*>){
func fwrite(fd<i64>,buffer<u64>,size<u64>){
	s<i8> = 1
	ret<u64> = std.fwrite(buffer,size,s,fd)
	if ret != size {
		os.die("fwrite err\n")
	}
	return true
}

//func fopen(filename,mode)
func fopen(filename,mode){
	utils.debug("linker.io:fopen",filename,mode)
	if filename == "" {
		fmt.print("fopen filename is empty\n")
		return false
	}
	ret<i32> = std.fopen(*filename,*mode)
	if ret == null {
		fmt.print("fopen failed\n")
		return false
	}
	utils.debug("fopen file:",int(ret))
	return ret
}
//func fclose(fp<u64>)
func fclose(fp<i64>){
	return std.fclose(fp)
}


//func seek(fd<i64> , offset<i64> , mode<i64>)
func rewind(fd){
	st<i8> = 0
	ret<i32> = std.seek(fd,st,std.SEEK_SET)	
	if ret < 0 {
		fmt.println(ret)
		os.die("rewind failed")
	}
}

alloc_max<u64> = 1073741824 
//func read(fd<i64> , size<u64>
func fread(fd<i32>,size<u64>){
	if size > alloc_max {
		os.die("alloc too large! :" + int(size))
	}
	buffer<u64*> = new size
	read_size<i64> = std.read(fd,buffer,size)
	if read_size != size {
		//utils.debug("fread err")
		os.die("fread err " + int(read_size))
		return false
	}
	return buffer
}
//func read(fd<i64> , buffer<u64*> , size<u64>
func fread_with_buf(fd<i32>,buf<u64*> , size<i64>){
	//utils.debug("fread fd:",int(fd),int(size))
	read_size<i64> = std.read(fd,buf,size)
	if read_size != size {
		//utils.debug("fread err")
		os.die("fread err " + int(read_size))
		return false
	}
	return buf
}

//func fseek(fp<u64>,offset<i64> , set<i64>)
func fseek(fp,offset<i64>){
	utils.debug("utils.fseek:",int(fp),int(offset))
	ret<i32> = std.fseek(fp,offset,std.SEEK_SET)
	if ret < 0 {
		fmt.println(int(ret))
		os.die("fseek failed")
	}
	return true
}