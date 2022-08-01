use runtime


func len(v){
	return runtime.len(v)
}
func pop(v){
	return runtime.pop(v)	
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
func exist(v<runtime.Value>,key){
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