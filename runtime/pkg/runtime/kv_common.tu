
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


func len_array(arr<Array>){
	return int(arr.used)
}
func cap_array(arr<Array>){
	return int(arr.total)
}
func len(v<Value>){
	type<i8> = v.type
	data<i8> = v.data
	match type {
		Null : {
			fmt.println("[warn] len(null)")
			return 0
		}
		Int  : {
			fmt.println("[warn] len(int)")
			return 1
		}
		Bool : {
			fmt.println("[warn] len(bool)")
			return 1
		}
		Array : return len_array(v.data)
		String : return len_string(v.data)
		Map   : os.die("unsupport len(map)")
		_     : {
			os.dief("[warn] len(unknow type:%s)",type_string(v))
		}
	}
	return 0
}

func pop(v<Value>){
	type<i8> = v.type
	match type {
		Array  : {
			arr<Array> = v.data
			return arr.pop()
		}
		_      : {
			fmt.println("[warn] pop(unknow type)")
			return null
		}
	}
	return null
}
func head(v<Value>){
	type<i8> = v.type
	match type {
		Array  : {
			arr<Array> = v.data
			return arr.head()
		}
		Map  : return map_head(v.data)
		_      : {
			fmt.println("[warn] head(unknow type)")
			return Null
		}
	}
	return Null
}
func arr_get(varr<Value>,index<Value>){
    if  varr.type != Array {
        fmt.println("[arr_get] not array type")
        os.exit(-1)
    }

    if  varr == null || varr.data == null || index == null {
        fmt.println("[arr_get] arr or index is null ,probably something wrong\n")
        os.exit(-1)
    }

    arr<Array> = varr.data
    // 计算索引
    i<i64> = 0
    match index.type {
        Int : i = index.data
        String : i = string.stringlen(index.data)
        _   : os.dief("[arr_get] invalid type: %s" , type_string(index) )
    }
    if  i >= arr.used {
        return newobject(Null,Null)
    }
    return arr.addr[i]
}
func arr_pushone(varr<Value>,var<Value>){
    if  varr == null || varr.data == null || var == null {
        fmt.println("[arr_pushone] arr or var is null ,probably something wrong\n")
        return Null
    }
    arr<Array> = varr.data
    insert<u64*> = arr.push()
    *insert    = var
}
func arr_updateone(varr<Value>,index<Value>,var<Value>){
    if  varr == null || varr.data == null || index == null || var == null {
        fmt.println("[arr_updateone] arr or var or index is null ,probably something wrong\n")
        return Null
    }
    arr<Array> = varr.data
    i<i64> = 0

    match index.type {
        Int : i = index.data
        String : i = string.stringlen(index.data)
        _ : os.dief("[arr_update] invalid type %s" , type_string(index))
    }
    // TODO:如果索引超出了 当前array的范围则需要扩充
    if  i >= arr.used {
        fmt.println("[arr_updateone] index is over the max size\n")
        return Null
    }
    arr.addr[i] = var
}
func array_in(v1<Value>,v2<Array>){
    size<u64> = v2.size
    p<u64*>   = v2.addr 
    used<u32> = v2.used
    for( i<i32> = 0 ; i < used ; i += 1 ){
        //TODO:   for dyn data
		//if value_equal(v1,*p,True){
        if v1 == *p {
			return True
		}
        p += size 
    }
    return False
}
func arr_tostring(varr<Value>)
{
    ret<i8*>   = string.stringempty()
    arr<Array> = varr.data
    orr<u64*>  = arr.addr

    ret = string.stringcat(ret,*"[")

    for (i<i32> = 0 ; i < arr.used ; i += 1) {
        p<u64*>  = orr + i * PointerSize
        v<Value> = *p
        //String
        if v.type == String {
            ret = string.stringcat(ret,v.data)
            ret = string.stringcat(ret,*",")
        //Int,Float,Bool,Char
        }else {
            ret = string.stringcatfmt(ret,*"%I,",v.data)
        }
    }
    ret = string.stringcat(ret,*"]")
    return ret
}