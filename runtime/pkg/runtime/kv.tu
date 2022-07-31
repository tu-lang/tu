
use string

func cap(v<Value>){
	type<i8> = v.type
	data<i8> = v.data

	if  type == Array  {
		return cap_array(v.data)
	}
	fmt.println("[warn] len(unknow type)")
	return 0
}

func kv_update(root<Value>,index<Value>,var<Value>)
{
    match root.type {
        Array : return arr_updateone(root,index,var)
        Map   : return map_insert(root,index,var)
        _     : fmt.println("[kv_update] arr or map is invalid ,probably something wrong")
    }
}

func kv_get(root<Value>,index<Value>){
    match root.type {
        Array : return arr_get(root,index)
        Map   : return map_find(root,index)
        String: return string.index_get(root,index)
        _     : fmt.println("[kv_get] arr or map is invalid ,probably something wrong\n")
    }
}