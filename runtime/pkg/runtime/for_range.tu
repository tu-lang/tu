
use os
use fmt
use std

func for_first(data<Value>){
	match data.type 
	{
		Map : {
			tree<Rbtree> = data.data
			if tree.root == tree.sentinel { return }
			return rbtree_min(tree.root,tree.sentinel)
		}
		Array : {
			arr<std.Array> = data.data
			if  arr.used <= 0 { return }
			iter<std.Array_iter> = new std.Array_iter
			iter.addr = arr.addr
			init_index = 0
			iter.cur  = init_index
			return iter
		}
		_     : os.dief("[for range]: first unsupport type:%s" , type_string(data))
	}
}
func for_get_key(data<Value>,node){
	match data.type {
		Map : {
			map_node<Rbtree_node> = node
			return map_node.k
		}
		Array : {
			iter<std.Array_iter> = node
			return iter.cur
		}
		_  : os.dief("[for range]: get key unsupport type:%s" ,type_string(data))
	}
}
func for_get_value(data<Value>,node){
	match data.type  {
		Map : {
			map_node<Rbtree_node> = node
			return map_node.v
		}
		Array : {
			iter<std.Array_iter> = node
			rv<u64*> = iter.addr
			return *rv
		}
		_ : os.dief("[for range]: get value unsupport type:%s" , type_string(data))
	}
}
func for_get_next(data<Value>,node){
	match data.type {
		Map : return rbtree_next(data.data,node)
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
		_ : os.dief("[for range]: next unsupport type:%s" , type_string(data))
	}
}