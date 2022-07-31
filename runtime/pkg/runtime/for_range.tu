
use os
use fmt

func for_first(data<Value>){
	match data.type 
	{
		Map : {
			tree<Rbtree> = data.data
			if tree.root == tree.sentinel { return }
			return rbtree_min(tree.root,tree.sentinel)
		}
		Array : {
			arr<Array> = data.data
			if  arr.used <= 0 { return }
			iter<Array_iter> = new Array_iter
			iter.addr = arr.addr
			init_index = 0
			iter.cur  = init_index
			return iter
		}
		_     : os.die("[for range]: first unsupport type:" + type_string(data.type))
	}
}
func for_get_key(data<Value>,node){
	match data.type {
		Map : {
			map_node<Rbtree_node> = node
			return map_node.k
		}
		Array : {
			iter<Array_iter> = node
			return iter.cur
		}
		_  : os.die("[for range]: get key unsupport type:" + type_string(data.type))
	}
}
func for_get_value(data<Value>,node){
	match data.type  {
		Map : {
			map_node<Rbtree_node> = node
			return map_node.v
		}
		Array : {
			iter<Array_iter> = node
			rv<u64*> = iter.addr
			return *rv
		}
		_ : os.die("[for range]: get value unsupport type:" + type_string(data.type))
	}
}
func for_get_next(data<Value>,node){
	match data.type {
		Map : return rbtree_next(data.data,node)
		Array : {
			arr<Array> = data.data
			arr_node<Array_iter> = node
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
		_ : os.die("[for range]: next unsupport type:" + type_string(data.type))
	}
}