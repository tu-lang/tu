use std
use fmt
use os 

#func fwrite(buffer<i8*> , size<u64> , count<u64> , fd<u64*>){
func fwrite(fd<i64>,buffer<u64>,size<u64>){
	s<i8> = 1
	ret<u64> = std.fwrite(buffer,size,s,fd)
	if ret != size {
		printf("fwrite err expect:%d acutal:%d\n".(i8),size,ret)
		os.die("")
	}
	return true
}

//fn fopen(filename,mode)
func fopen(filename,mode){
	utils.debug("linker.io:fopen %s %s".(i8),*filename,*mode)
	if filename == "" {
		fmt.print("fopen filename is empty\n")
		return false
	}
	ret<i32> = std.fopen(*filename,*mode)
	if ret == null {
		fmt.print("fopen failed\n")
		return false
	}
	if ret < 0 {
		fmt.println("fopen failed ",filename," ret:",int(ret))
		return false
	}
	utils.debug("fopen file: %d".(i8),ret)
	return ret
}
//func fclose(fp<u64>)
func fclose(fp<i64>){
	return std.fclose(fp)
}


//func seek(fd<i64> , offset<i64> , mode<i64>)
func rewind(fd){
	st<i8> = 0
	std.seek(fd,st,std.SEEK_SET)	
}

//func read(fd<i64> , size<u64>
func fread(fd<i32>,size<i64>){
	//utils.debug("fread fd:",int(fd),int(size))
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
	std.fseek(fp,offset,std.SEEK_SET)
	return true
}