use os
use std
use string
use std
use std.map

func newobject(type<i32> , data<u64*>,hk<u64>)
{
    match type {
        Int:   {
            return new Value {
                type : Int,
                data : data
            }
        }
        Float:  {
            return new Value {
                type : Float,
                data : data
            }
        }
        String: {
            // return new Value {
            //     type : String,
            //     data : string.newstring(data)
            // }
            if hk == 0 {
                dief("new string hk is null %s\n".(i8),data)
            }
            //check exist
            if enable_object_pool {
                ps<u64> = strings.find(hk)
                if ps != 0 {
                    return ps
                }
            }
            //new and insert
            objs<StringValue> = new StringValue {
                base : Value {
                    type : String,
                    data : string.newstring(data)
                },
                hk : hk
            }
            node<map.RbtreeNode> = new map.RbtreeNode {
                key : hk,
                v   : objs
            }
            if enable_object_pool strings.insert(node)
            return objs
        }
        Bool:   {
            return new Value {
                type : Bool,
                data : data,
            }
        }
        Char:   {
            i<u8> = data
            return chars.addr[i]
        }
        Null:   {
            return new Value {
                type : Null,
                data : 0
            }
        }
        Array:  {
            return new Value {
                type : Array,
                data : std.NewArray(std.ARRAY_SIZE, PointerSize)
            }
        }
        Map:    {
            return new Value {
                type : Map,
                data : map.map_create()
            }
        }
        Object: {
            return new Value {
                type : Object,
                data : object_create(data)
            }
        }
        _ : dief(*"[new obj] unknown type")
    } 
    return Null
}
func newinherit_object(typeid<i32>,father<Value>){
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
        println(*"[warn] super()  not object")
        return null
    }
    o<Object> = obj.data
    if o.father == null {
        println(*"[warn] super() called not in child class")
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
        return Null
    }
    return obj.data
}

func member_insert_or_update(temp<map.RbtreeNode>, node<map.RbtreeNode>,sentinel<map.RbtreeNode>)
{
	// RbtreeNode **
	p<u64*> = null

	loop {
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
fn member_find(tree<map.Rbtree>,key<Value>){

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
fn member_insert(tree<map.Rbtree>, k<Value>,v<Value>)
{

	node<map.RbtreeNode> = new map.RbtreeNode
	hk<u64> = get_hash_key(k)
    node.key   = hk
    node.k     = k
    node.v     = v
    tree.insert(node)
}
// return object
fn object_create(typeid<i32>){
    c<Object> = new Object
    if  c == null  {
        println(*"[object_create] failed to create")
        return Null
    }
    c.typeid = typeid
    members<map.Rbtree> = map.map_create()
    members.insert = member_insert_or_update.(i64)

    funcs<map.Rbtree> = map.map_create()
    funcs.insert = member_insert_or_update.(i64)

    c.members = members
    c.funcs   = funcs
    c.father  = null

    return c
}
// return value
fn object_member_update(obj<Value>,k<u32>,v<Value>){
    key<Value> = int(k)
    if  obj.type != Object {
        dief(*"[object_membe_update] invalid obj type")
    }
    c<Object> = obj.data
    member_insert(c.members,key,v)
}
fn _object_member_get(obj<Object>,key<Value>){
    v<Value> = member_find(obj.members,key)
    if  v == null {
        v = member_find(obj.funcs,key)
    }

    //need find it form father class
    if v == null && obj.father != null {
        v = _object_member_get(obj.father,key)
    }
    return v
}
// return value
fn object_member_get(k<u32>,obj<Value>){
    key<Value> = int(k)
    if  obj.type != Object {
        dief(*"[object_membe_get] invalid obj type :%s %p",type_string(obj),obj)
    }
    v<Value> = _object_member_get(obj.data,key)
    if v == null {//myabe v is this.name = 0.(i8)
        printf(*"[warn] class memeber not define in %s\n", debug.callerpc())
        v = &internal_null
    }
    return v
}
fn object_unary_operator(opt<i32>,k<u32>,v<Value>,obj<Value>){
    if   obj == null || v == null  || obj.type != Object {
        println(*"[object-uop] probably wrong at there! object:%p rhs:%p\n",obj,int(v))
        return Null
    }
    origin<Value> = _object_member_get(obj.data,int(k))
    if origin == null origin = &internal_null
    
    ret<Value> = operator_switch(opt,origin,v)
    object_member_update(obj,k,ret)
}
fn object_func_add(k<u32>,addr<u64*>,obj<Value>){

    key<Value> = int(k)
    c<Object> = obj.data
    member_insert(c.funcs,key,addr)
}
//used by internal runtime
fn get_member_func_addr(obj<Object>,key<Value>){
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
        dief(*"[object-func] func not exist in func table and members table")
    }
    return funcaddr
}
fn object_func_addr(k<u32>,obj<Value>){
    if  obj.type != Object {
        dief(*"[object_func_addr] invalid obj type :%s",type_string(obj))
    }
    key<Value> = int(k)
    return get_member_func_addr(obj.data,key)
}


