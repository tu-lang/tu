
use fmt
use os
use std
use string
use std
use std.map

func newobject(type<i32> , data<u64*>)
{
    ret<Value> = new Value
    ret.type   = type
    match type {
        Int:    ret.data = data
        Float:  ret.data = data
        String: ret.data = string.newstring(data)
        Bool:   ret.data = data
        Char:   ret.data = data
        Null:   ret.data = 0
        Array:  ret.data = std.array_create(std.ARRAY_SIZE, PointerSize)
        Map:    ret.data = map.map_create()
        Object: ret.data = object_create(data)
        _ : {
            fmt.println("[new obj] unknown type")
            ret.type = Null
        }
    } 
    return ret
}
func newinherit_object(father<Value>,typeid<i32>){
    ret<Value> = new Value
    ret.type   = Object

    //new default object
    obj<Object> = object_create()
    //save father
    obj.father  = father.data
    //save type id
    obj.typeid = typeid
    ret.data = obj

    return ret
}
func object_parent_get(obj<Value>){
    if obj == null return obj
    if obj.type != Object {
        fmt.println("[warn] super()  not object")
        return null
    }
    o<Object> = obj.data
    if o.father == null {
        fmt.println("[warn] super() called not in child class")
        return null
    }
    ret<Value> = new Value
    ret.type  = Object
    ret.data  = o.father
    return ret
}
// NOTICE: get_object_value called by compiler
// so it didn't save the %rdi,%rsi,%rdx,%rcx,%r8,%r9
// don't do anything in those who called by compiler,will cause terriable problem
func get_object_value(obj<Value>){
    if obj == null {
        //FIXME: fmt.println("[get obj] null")
        return Null
    }
    return obj.data
}

func member_insert_or_update(temp<map.RbtreeNode>, node<map.RbtreeNode>,sentinel<map.RbtreeNode>)
{
	// RbtreeNode **
	p<u64*> = null

	while True {
        if  node.key == temp.key {
            temp.v = node.v
        }
		if  node.key < temp.key {
			p = &temp.left
		}else{
			p = &temp.right
		}

        if *p == sentinel {
            break
        }

        temp = *p
    }

    *p = node
    node.parent = temp
    node.left = sentinel
    node.right = sentinel
    node.red()
}
func member_find(tree<map.Rbtree>,key<Value>){

	node<map.RbtreeNode> = null
	sentinel<map.RbtreeNode> = null

    hk<u64> = get_hash_key(key)

    node = tree.root
    sentinel = tree.sentinel

    while node != sentinel {

        if hk != node.key {
			if  hk < node.key  {
				node = node.left
			}else{
				node = node.right
			}
            continue
        }
        if  node.k.type == key.type {
            return node.v
        }
    }
    return Null
}
func member_insert(tree<map.Rbtree>, k<Value>,v<Value>)
{

	node<map.RbtreeNode> = new map.RbtreeNode
	hk<u64> = get_hash_key(k)
    node.key   = hk
    node.k     = k
    node.v     = v
    tree.insert(node)
}
// return object
func object_create(typeid<i32>){
    c<Object> = new Object
    if  c == null  {
        fmt.println("[object_create] failed to create")
        return Null
    }
    c.typeid = typeid
    members<map.Rbtree> = map.map_create()
    members.insert = member_insert_or_update

    funcs<map.Rbtree> = map.map_create()
    funcs.insert = member_insert_or_update

    c.members = members
    c.funcs   = funcs
    c.father  = null

    return c
}
// return value
func object_member_update(obj<Value>,k<u32>,v<Value>){
    key<Value> = int(k)
    if  obj.type != Object {
        fmt.println("[object_membe_update] invalid obj type")
        os.exit(-1)
    }
    c<Object> = obj.data
    member_insert(c.members,key,v)
}
func _object_member_get(obj<Object>,key<Value>){
    v<Value> = member_find(obj.members,key)
    if  v == null {
        v = member_find(obj.funcs,key)
    }

    //need find it form father class
    if v == null && obj.father != null {
        v = _object_member_get(obj.father,key)
    }
    if  v == null {
        //fmt.println("object_get] not find the memeber:%d value\n",key)
        return null
    }
    return v
}
// return value
func object_member_get(obj<Value>, k<u32>){
    key<Value> = int(k)
    if  obj.type != Object {
        os.dief("[object_membe_get] invalid obj type :%s",runtime.type_string(obj))
    }
    c<Object> = obj.data 
    return _object_member_get(obj.data,key)
}
func object_unary_operator(opt<i32>,obj<Value>,k<u32>,v<Value>){
    if   obj == null || v == null  {
        fmt.println(" [object-uop] probably wrong at there! object:%p rhs:%p\n",obj,int(v))
        return Null
    }
    origin<Value> = object_member_get(obj,k)
    ret<Value> = operator_switch(opt,origin,v)
    object_member_update(obj,k,ret)
}
func object_func_add(obj<Value>,k<u32>,addr<u64*>){

    key<Value> = int(k)
    c<Object> = obj.data
    member_insert(c.funcs,key,addr)
}
//used by internal runtime
func get_member_func_addr(obj<Object>,key<Value>){
    funcaddr<u64*> = member_find(obj.funcs,key)
    if  funcaddr == null {
        funcaddr = member_find(obj.members,key)

        //need find it form father class
        if funcaddr == null && obj.father != null {
            funcaddr = get_member_func_addr(obj.father,key)
        }
    }
    //not find finally
    if funcaddr == null {
        os.dief("[object-func] func not exist in func table and members table")
    }
    return funcaddr
}
func object_func_addr(obj<Value>,k<u32>){
    if  obj.type != Object {
        os.dief("[object_func_addr] invalid obj type :%s",runtime.type_string(obj))
    }
    key<Value> = int(k)
    return get_member_func_addr(obj.data,key)
}


