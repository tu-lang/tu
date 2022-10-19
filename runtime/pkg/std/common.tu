use runtime
use fmt

func rand(v<runtime.Value>){

	seed = (seed * 1103515245) + 12345
	ret<u64> = (seed / 65536) % 32768
	if v != null {
		ret %= v.data
	}
	return int(ret)
}

func empty(v<runtime.Value>){
	match v.type {
		runtime.String: {
			ret<i8> = strlen(v.data)
			if ret == 0 return True
		}
		_: fmt.println("[warn] empty: unsuport type")
	}	
	return False
}
func len(v){
	return runtime.len(v)
}
func pop(v){
	return runtime.pop(v)	
}
func pop_head(v<runtime.Value>){
	if v == null {
		fmt.println("[warn] pop_head args is null")
		return False
	}
	match v.type {
		runtime.Array:{
			arr<Array> = v.data
			if  arr == null os.die("[arr_pop_head] not array_type")
			if arr.used <= 0 {
				fmt.println("[warn] array_pop for empty array")
				return False
			}
			arr.used -= 1
			addr<u64*> = arr.addr
			var<u64*>  = addr
			addr += arr.size
			arr.addr = addr
			return *var
		}
		_: {
			fmt.println("[warn] pop_head args is not array")
			return False
		}
	}
}
func head(v){
	if (ret<u64> = runtime.head(v))	!= runtime.Null {
		return ret
	}
	return null
}
func tail(v<runtime.Value>){
	match v.type {
		runtime.Array : {
			arr<Array> = v.data
			return arr.tail()
		}
		_: fmt.println("[warn] std.back unsupport type")
	}
	return null
}
func merge(v1<runtime.Value>,v2<runtime.Value>){
	match v1.type {
		runtime.Map : fmt.println("[warn] unsupport merge(map,..)")
		runtime.Array   : {
			if v2.type != runtime.Array {
				fmt.println("[warn] merge unsupport not array value")
				return False
			}
			arr<Array> = v1.data
			if arr.merge(v2.data) != runtime.True {
				fmt.println("[warn] array merge failed")
				return False
			}
			return True
		}
		_     : fmt.println("[warn] merge(unknow type)")
	}
	return False
}
func exist(key,v<runtime.Value>){
	type<i8> = v.type
	data<i8> = v.data
	match type {
		runtime.Array : {
			if runtime.array_in(key,v.data) == runtime.True {
				return True
			}
		}
		runtime.Map   : {
			has<i32> = runtime.map_find(v,key)
			if has != null return True
		}
		_     : fmt.printf("[warn] unsupport exist(,%s)\n",runtime.type_string(v))
	}
	return False
}
func is_map(map<runtime.Value>){
	if  map.type == runtime.Map {
		return True
	}
	return False
}
func is_array(arr<runtime.Value>){
	if  arr.type == runtime.Array {
		return True
	}
	return False
}

