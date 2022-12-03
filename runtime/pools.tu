use std
use os
use std.map

chars<std.Array> = null
strings<map.Rbtree> = null
//TODO: remove
enable_object_pool<i64> = 0

func string_insert(temp<map.RbtreeNode>, node<map.RbtreeNode>,sentinel<map.RbtreeNode>)
{
    p<u64*> = null

	loop {
        if  node.key == temp.key {
            if node.k != temp.k  {
				//TODO:
				//string hash conflict
                fmt.printf("[kv_update] hash conflict %s %s\n",node.v,temp.v)
            }
            temp.v = node.v
            return map.Update
        }
        if  node.key < temp.key {
            p = &temp.left 
        }else{
            p = &temp.right
        }
        if  *p == sentinel  {
            break
        }
        temp = *p
    }

    *p = node
    node.parent = temp
    node.left = sentinel
    node.right = sentinel

    // make red
    node.color = 1
}

func init(){
	//init array
	chars = std.array_create(256.(i8),8.(i8))
	for i<i32> = 0 ; i < 256 ; i += 1 {
		c<Value> = new Value {
			type : Char,
			data : i
		}
		if chars.push(c) == Null {
			os.die("chars pool init: memory failed")
		}
	}
	//init map
	strings = map.map_create(string_insert)
	enable_object_pool = 1
}
func chars_get(i<i8>){
	if i < 0 {
		return chars.addr[127-i]
		// os.dief("new char: value should >= 0 || < 128 %d",int(i))
	}
	return chars.addr[i]
}