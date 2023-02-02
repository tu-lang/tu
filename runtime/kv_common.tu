
use fmt
use string
use std
use std.map

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
		Array : {
			arr<std.Array> = v.data
			return int(arr.len())
		}
		String : {
            s<string.Str> = v.data
            return int(s.len())
        }
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
			arr<std.Array> = v.data
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
			arr<std.Array> = v.data
			return arr.head()
		}
		Map  : {
            m<map.Rbtree> = v.data
            return m.head()
        }
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

    arr<std.Array> = varr.data
    // 计算索引
    i<i64> = 0
    match index.type {
        Int : i = index.data
        String : {
            str<string.Str> = index.data
            i = str.len()
        }
        _   : os.dief("[arr_get] invalid type: %s" , type_string(index) )
    }
    if  i >= arr.used {
        return newobject(Null,Null)
    }
    return arr.addr[i]
}
func arr_pushone(var<Value>,varr<Value>){
    if  varr == null || varr.data == null || var == null {
        os.dief("[arr_push] arr or var is null\n")
        // fmt.println("[arr_pushone] arr or var is null ,probably something wrong\n")
        // return Null
    }
    arr<std.Array> = varr.data
    insert<u64*> = arr.push()
    *insert    = var
}
func arr_updateone(varr<Value>,index<Value>,var<Value>){
    if  varr == null || varr.data == null || index == null || var == null {
        fmt.println("[arr_updateone] arr or var or index is null ,probably something wrong\n")
        return Null
    }
    arr<std.Array> = varr.data
    i<i64> = 0

    match index.type {
        Int : i = index.data
        String : {
            str<string.Str> = index.data
            i = str.len()
        }
        _ : os.dief("[arr_update] invalid type %s" , type_string(index))
    }
    // TODO:如果索引超出了 当前array的范围则需要扩充
    if  i >= arr.used {
        fmt.println("[arr_updateone] index is over the max size\n")
        return Null
    }
    arr.addr[i] = var
}
func array_in(v1<Value>,v2<std.Array>){
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
    ret<string.Str>   = string.empty()
    arr<std.Array> = varr.data
    orr<u64*>  = arr.addr

    ret = ret.cat(*"[")

    for (i<i32> = 0 ; i < arr.used ; i += 1) {
        p<u64*>  = orr + i * PointerSize
        v<Value> = *p
        //String
        if v.type == String {
            ret = ret.cat(v.data)
            ret = ret.cat(*",")
        //Int,Float,Bool,Char
        }else {
            ret = ret.catfmt(*"%I,",v.data)
        }
    }
    return ret.cat(*"]")
}