
use string
use std
use std.map

fn cap(v<Value>){
	type<i8> = v.type
	data<i8> = v.data

	if  type == Array  {
        arr<std.Array> = v.data
        return int(arr.cap())
	}
	printf(*"[warn] len(unknow type)")
	return 0
}

fn kv_update(var<Value>,index<Value>,root<Value>)
{
    match root.type {
        Array : return arr_updateone(var,index,root)
        Map   : return map.map_insert(root,index,var)
        _     : {
            dief(*"[kv_update] arr or map is invalid,ty:%s\n",type_string(root))
        }
    }
}

fn kv_get(index<Value>,root<Value>){
    match root.type {
        Array : return arr_get(root,index)
        Map   : {
            ret<Value> = map.map_find(root,index)
            if ret == Null return null
            return ret
        }
        String: return string.index_get(root,index)
        Null:  printf(*"[kv_get] arr or map for null ,probably something wrong %s\n",debug.callerpc())
        Int:   printf(*"[kv_get] arr or map for int ,probably something wrong %s\n",debug.callerpc())
        Float: printf(*"[kv_get] arr or map for float ,probably something wrong %s\n",debug.callerpc())
        Bool:  printf(*"[kv_get] arr or map for bool ,probably something wrong %s\n",debug.callerpc())
        Char:  printf(*"[kv_get] arr or map for char ,probably something wrong %s\n",debug.callerpc())
        Object: printf(*"[kv_get] arr or map for object ,probably something wrong %s\n",debug.callerpc())
        Func:   printf(*"[kv_get] arr or map for func ,probably something wrong %s\n",debug.callerpc())
        _     : printf(*"[kv_get] arr or map is invalid ,probably something wrong %s\n",debug.callerpc())
    }
}

fn len(v<Value>){
	type<i8> = v.type
	data<i8> = v.data
	match type {
		Null : {
			println(*"[warn] len(null)")
			return 0
		}
		Int  : {
			println(*"[warn] len(int)")
			return 1
		}
		Float  : {
			println(*"[warn] len(float)")
			return 1
		}
		Bool : {
			println(*"[warn] len(bool)")
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
		Map   : {
            m<map.Rbtree> = v.data
			return int(m.count)
		}
		_     : {
			dief(*"[warn] len(unknow type:%s)\n",type_string(v))
		}
	}
	return 0
}

fn pop(v<Value>){
	type<i8> = v.type
	match type {
		Array  : {
			arr<std.Array> = v.data
			return arr.pop()
		}
		_      : {
			println(*"[warn] pop(unknow type)")
			return null
		}
	}
	return null
}
fn head(v<Value>){
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
			println(*"[warn] head(unknow type)")
			return Null
		}
	}
	return Null
}
fn arr_get(varr<Value>,index<Value>){
    if  varr.type != Array {
        dief(*"[arr_get] not array type\n")
    }

    if  varr == null || varr.data == null || index == null {
		dief(*"[arr_get] arr or index is null ,probably something wrong\n")
    }

    arr<std.Array> = varr.data
    i<i64> = 0
    match index.type {
        Int : i = index.data
        _   : {
			dief(*"[arr_get] invalid type: %s\n" , type_string(index))
		}
    }
    if  i >= arr.used {
        return newobject(Null,Null)
    }
    return arr.addr[i]
}
fn arr_pushone(var<Value>,varr<Value>){
    if  varr == null || varr.data == null || var == null {
        dief(*"[arr_push] arr or var is null\n")
        // return Null
    }
    arr<std.Array> = varr.data
    insert<u64*> = arr.push(var)
}
fn arr_updateone(var<Value>,index<Value>,varr<Value>){
    if  varr == null || varr.data == null || index == null || var == null {
        println(*"[arr_updateone] arr or var or index is null ,probably something wrong\n")
        return Null
    }
    arr<std.Array> = varr.data
    i<i64> = 0

    match index.type {
        Int : i = index.data
        _ : dief(*"[arr_update] invalid type %s" , type_string(index))
    }
    // TODO: over index need scale
    if  i >= arr.used {
        printf(*"[arr_updateone] index is over the max size\n")
        return Null
    }
    arr.addr[i] = var
}
fn array_in(v1<Value>,v2<std.Array>){
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
fn arr_tostring(varr<Value>)
{
    ret<string.Str>   = string.empty()
    arr<std.Array> = varr.data
    orr<u64*>  = arr.addr

    ret = ret.cat(*"[")

    for (i<i32> = 0 ; i < arr.used ; i += 1) {
        p<u64*>  = orr + i * PointerSize
        v<Value> = *p
        //String
		match v.type {
			String : {
            	ret = ret.cat(v.data)
            	ret = ret.cat(*",")
			}
			Float : {
				fstr<string.String> = string.f64tostring(v.data , 5.(i8))
				ret = ret.cat(fstr.str())
            	ret = ret.cat(*",")
			}
            _ : ret = ret.catfmt(*"%I,",v.data)
		}
    }
    return ret.cat(*"]")
}

//compiler: function iter var size
mem KvIter {
	i64  type , root
	u64* addr , cur
}

fn for_first(data<Value>,iter<KvIter>){
	iter.root = data.data
	match data.type 
	{
		Map : {
			tree<map.Rbtree> = data.data
			if tree.root == tree.sentinel { return Null}
			iter.type = Map
			iter.addr = tree.root.min(tree.sentinel)
			return iter
		}
		Array : {
			arr<std.Array> = data.data
			if  arr.used <= 0 { return Null}
			iter.type = Array
			iter.addr = arr.addr
			init_index = 0
			iter.cur  = init_index
			return iter
		}
		_     : dief(*"[for range]: first unsupport type:%d" , data.type)
	}
}
fn for_get_key(iter<KvIter>){
	match iter.type {
		Map : {
			map_node<map.RbtreeNode> = iter.addr
			if map_node == Null {
				println(*"for get key null")
			}
			return map_node.k
		}
		Array : {
			return iter.cur
		}
		_  : dief(*"[for range]: get key unsupport type:%d" , iter.type)
	}
}
fn for_get_value(iter<KvIter>){
	match iter.type  {
		Map : {
			map_node<map.RbtreeNode> = iter.addr
			return map_node.v
		}
		Array : {
			rv<u64*> = iter.addr
			return *rv
		}
		_  : dief(*"[for range]: get value unsupport type:%d" , iter.type)
	}
}
fn for_get_next(iter<KvIter>){
	match iter.type {
		Map : {
			m<map.Rbtree> = iter.root
			if m == null {
				dief(*"iter next for null map")
			}
			iter.addr = m.next(iter.addr)
			return iter.addr
		}
		Array : {
			arr<std.Array> = iter.root
			index<Value> = iter.cur
			index.data += 1
			if index.data >= arr.used { 
				return Null
			}
			iter.addr += 8
			return iter
		}
		_  : dief(*"[for range]: next unsupport type:%d" , iter.type)
	}
}

fn for_first2(data<Value>){
	match data.type 
	{
		Map : {
			tree<map.Rbtree> = data.data
			if tree.root == tree.sentinel { return Null}
			return tree.root.min(tree.sentinel)
		}
		Array : {
			arr<std.Array> = data.data
			if  arr.used <= 0 { return Null}
			iter<std.Array_iter> = new std.Array_iter
			iter.addr = arr.addr
			init_index = 0
			iter.cur  = init_index
			return iter
		}
		_     : dief(*"[for range]: first unsupport type:%s\n" , type_string(data))
	}
}
fn for_get_key2(node,data<Value>){
	match data.type {
		Map : {
			map_node<map.RbtreeNode> = node
			if node == Null {
				println(*"for get key null")
			}
			return map_node.k
		}
		Array : {
			iter<std.Array_iter> = node
			return iter.cur
		}
		_  : dief(*"[for range]: get key unsupport type:%s" ,type_string(data))
	}
}
fn for_get_value2(node,data<Value>){
	match data.type  {
		Map : {
			map_node<map.RbtreeNode> = node
			return map_node.v
		}
		Array : {
			iter<std.Array_iter> = node
			rv<u64*> = iter.addr
			return *rv
		}
		_ : dief(*"[for range]: get value unsupport type:%s" , type_string(data))
	}
}
fn for_get_next2(node,data<Value>){
	match data.type {
		Map : {
			m<map.Rbtree> = data.data
			if m == null {
				println(*"empty")
			}
			return m.next(node)
		}
		Array : {
			arr<std.Array> = data.data
			arr_node<std.Array_iter> = node
			// ++i
			index<Value> = arr_node.cur
			index.data += 1
			if index.data >= arr.used { 
				return Null
			}
			// ++pointer
			arr_node.addr += 8
			return arr_node
		}
		_ : dief(*"[for range]: next unsupport type:%s" , type_string(data))
	}
}