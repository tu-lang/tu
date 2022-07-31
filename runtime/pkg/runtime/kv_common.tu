
use fmt
use string

// 解析字符串
func len_string(v<u8*>){
	len<i32> = string.stringlen(v)
	return int(len)
	//len = 0
	//while p != 0 {
	//	fmt.println(p)
	//	v += 1
	//	p = int(*v)
	//	len += 1
	//}
	//return len
}

mem Array_t {
	u8* 	 addr
	u8		 used		
    i64      size
	u8		 total
}
func len_array(arr<Array_t>){
	return int(arr.used)
}
func cap_array(arr<Array_t>){
	return int(arr.total)
}
func len(v<Value>){
	type<i8> = v.type
	data<i8> = v.data
	match type {
		Null : return 0
		Int  : return data
		Bool : return data
		Array : return len_array(v.data)
		String : return len_string(v.data)
		Map   : os.die("unsupport len(map)")
		_     : fmt.println("[warn] len(unknow type)")
	}
	return 0
}

func pop(v<Value>){
	type<i8> = v.type
	match type {
		Array  : return array_pop(v.data)
		_      : return null
	}
	return null
}