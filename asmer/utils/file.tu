use std
use fmt
use os 
use string
use runtime

#func fwrite(buffer<i8*> , size<u64> , count<u64> , fd<u64*>){
unsafe fn fwrite(fd<i64>,buffer<u64>,size<u64>){
	s<i8> = 1
	ret<u64> = std.fwrite(buffer,size,s,fd)
	if ret != size {
		printf("fwrite err expect:%d acutal:%d\n".(i8),size,ret)
		os.die("")
	}
	return true
}

//fn fopen(filename,mode)
unsafe fn fopen(filename,mode){
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
unsafe fn fclose(fp<i64>){
	return std.fclose(fp)
}


//func seek(fd<i64> , offset<i64> , mode<i64>)
unsafe fn rewind(fd){
	st<i8> = 0
	std.seek(fd,st,std.SEEK_SET)	
}

//func read(fd<i64> , size<u64>
unsafe fn fread(fd<i32>,size<i64>){
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
unsafe fn fread_with_buf(fd<i32>,buf<u64*> , size<i64>){
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
unsafe fn fseek(fp,offset<i64>){
	utils.debug("utils.fseek:",int(fp),int(offset))
	std.fseek(fp,offset,std.SEEK_SET)
	return true
}

// Parent directory of path; no slash → "."
unsafe fn path_dirname(path){
	n = std.len(path)
	if n == 0 return "."
	i = n - 1
	while i >= 0 {
		if path[i] == '/' break
		i -= 1
	}
	if i < 0 return "."
	if i == 0 return "/"
	out = ""
	j = 0
	while j < i {
		out += path[j]
		j += 1
	}
	return out
}
unsafe fn path_join(d,f){
	if d == null || d == "" || d == "."
		return f
	dlen = std.len(d)
	last = d[dlen - 1]
	bs = runtime.newobject(runtime.Char, 92.(i8))
	if last == '/' || last == bs
		return d + f
	return d + "/" + f
}

// Directory basenames. Windows uses FindFirstFile (getdents is ENOSYS).
unsafe fn list_basenames(dir) {
	out = []
	if runtime.host_os() == 2 {
		pat = ""
		i = 0
		dn = std.len(dir)
		bs = runtime.newobject(runtime.Char, 92.(i8))
		while i < dn {
			c = dir[i]
			if c == '/' {
				pat += "\\"
			} else {
				pat += c
			}
			i += 1
		}
		if dn > 0 {
			last = pat[std.len(pat) - 1]
			if last != bs {
				pat = pat + "\\"
			}
		}
		pat = pat + "*"
		h<u64> = os.win_find_first(*pat)
		if h == 0 {
			return out
		}
		loop {
			np<i8*> = os.win_find_name()
			nm = "" + string.new(np)
			out[] = nm
			rc<i32> = os.win_find_next(h)
			if rc == 0 {
				break
			}
		}
		os.win_find_close(h)
		return out
	}
	fd = std.opendir(dir)
	if !fd {
		return out
	}
	loop {
		f = fd.readdir()
		if !f {
			break
		}
		out[] = f.name
	}
	return out
}