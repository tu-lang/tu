use string
use fmt
use runtime


func replace(str,src,dst){
	ret<runtime.Value> = string.split(str,src)
	arr<runtime.Array> = ret.data	
	
	s = ""
	p<u64*> = arr.addr
	for( i<i32> = 1 ; i <= arr.used ; i += 1){
		v = *p
		p += arr.size
		s += v
		if i  < arr.used
			s += dst
	}
	return s

}