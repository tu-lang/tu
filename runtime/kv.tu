
use string
use std
use std.map

func cap(v<Value>){
	type<i8> = v.type
	data<i8> = v.data

	if  type == Array  {
        arr<std.Array> = v.data
        return int(arr.cap())
	}
	fmt.println("[warn] len(unknow type)")
	return 0
}

func kv_update(var<Value>,index<Value>,root<Value>)
{
    match root.type {
        Array : return arr_updateone(var,index,root)
        Map   : return map.map_insert(root,index,var)
        _     : {
            os.dief("[kv_update] arr or map is invalid,ty:%s\n",type_string(root))
            // fmt.println("[kv_update] arr or map is invalid ,probably something wrong")
        }
    }
}

func kv_get(index<Value>,root<Value>){
    match root.type {
        Array : return arr_get(root,index)
        Map   : {
            ret<Value> = map.map_find(root,index)
            if ret == Null return null
            return ret
        }
        String: return string.index_get(root,index)
        Null:  fmt.printf("[kv_get] arr or map for null ,probably something wrong %s\n",debug.callerpc())
        Int:   fmt.printf("[kv_get] arr or map for int ,probably something wrong %s\n",debug.callerpc())
        Int:   fmt.printf("[kv_get] arr or map for float ,probably something wrong %s\n",debug.callerpc())
        Int:   fmt.printf("[kv_get] arr or map for bool ,probably something wrong %s\n",debug.callerpc())
        Int:   fmt.printf("[kv_get] arr or map for char ,probably something wrong %s\n",debug.callerpc())
        Int:   fmt.printf("[kv_get] arr or map for object ,probably something wrong %s\n",debug.callerpc())
        _     : fmt.printf("[kv_get] arr or map is invalid ,probably something wrong %s\n",debug.callerpc())
    }
}