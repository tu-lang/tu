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
			if ret == 0 return std_true
		}
		_: fmt.println("[warn] empty: unsuport type")
	}	
	return std_false
}
func len(v){
	return runtime.len(v)
}
func pop(v){
	return runtime.pop(v)	
}
func head(v){
	if (ret<u64> = runtime.head(v))	!= runtime.Null {
		return ret
	}
	return null
}
func tail(v<runtime.Value>){
	match v.type {
		runtime.Array : return runtime.array_tail(v.data)
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
				return false
			}
			ret<i8> = runtime.array_merge(v1.data,v2.data)
			if ret != runtime.True {
				fmt.println("[warn] array merge failed")
				return false
			}
			return true
		}
		_     : fmt.println("[warn] merge(unknow type)")
	}
	return false
}
func exist(key,v<runtime.Value>){
	type<i8> = v.type
	data<i8> = v.data
	match type {
		runtime.Array : {
			if runtime.array_in(key,v.data) == runtime.True {
				return true
			}
		}
		runtime.Map   : {
			has<i32> = runtime.map_find(v,key)
			if has != null return true
		}
		_     : fmt.println("[warn] exist(unknow type)")
	}
	return false
}