
use fmt
use os
use std
use string
use std
use std.map

mem VObjFunc {
	u64 hid
	u64 entry
	i32 argsize
	i32 asyncsize
	u64 init
}
mem VObjMem {
    u64 nid
    i64 ofs
}
mem VObjHeader {
	u64 parent
	i32 membersize
	i32	funcsize
	VObjFunc fcs[1]
}

VObjHeader::funcentry(){
	return &this.fcs
}
VObjHeader::mementry(){
    return &this.fcs[this.funcsize]
}
VObjHeader::checknew(osize<i64>){
    checksize<i64> = this.membersize * 8
    prt<VObjHeader> = this.parent
    while prt != null {
        checksize += prt.membersize * 8
        prt = prt.parent
    }
    if osize != checksize {
        dief("[newclsobject] size not eq".(i8))
    }

}

fn objdataofs(hdr<VObjHeader>, data<i64*>, hid<u64>){
    l<i32> = 0
    r<i32> = hdr.membersize
    middle<i32> = 0
    arr<i64*> = hdr.mementry()
    while l < r {
        middle = (l + r) / 2
        mtype<VObjMem> = arr +  (sizeof(VObjMem) * middle)
        if hid == mtype.nid {
            return data + mtype.ofs
        }
        else if hid < mtype.nid  r = middle
        else if hid > mtype.nid l = middle + 1
    }

    if hdr.parent != null {
        return objdataofs(
            hdr.parent,
            data + hdr.membersize * 8,
            hid,
        )
    }
    return Null
}
fn objfuncofs(hdr<VObjHeader>, hid<u64>){
    l<i32> = 0
    r<i32> = hdr.funcsize
    middle<i32> = 0
    arr<i64*> = hdr.funcentry()
    while l < r {
        middle = (l + r) / 2
        mtype<VObjFunc> = arr +  (sizeof(VObjFunc) * middle)
        if hid == mtype.hid {
            return mtype
        }
        else if hid < mtype.hid  r = middle
        else if hid > mtype.hid l = middle + 1
    }

    if hdr.parent != null {
        return objfuncofs(
            hdr.parent,
            hid,
        )
    }
    return Null
}

func newfuncobject(entry<u64>,as<i32>){
    //printf("entry:%d size:%d\n".(i8),entry,as) 
    return new FuncObject {
        type : Func,
        hdr : VObjFunc {
            argsize : as,
            entry: entry
        }
    } 
}

func newclsobject(vid<VObjHeader>, objsize<i64>)
{
    if vid == null dief("new cls obj is null".(i8))
    if objsize < 0 dief("new cls size is invalid".(i8))
    // if enable_debug {
        vid.checknew(objsize)
    // }
    dptr<i64> = null
    if objsize != 0
        dptr = new objsize

    members<map.Rbtree> = map.map_create()
    members.insert = member_insert_or_update.(i64)
    obj<ObjectValue> = new ObjectValue {
        base : Value {
            type : Object,
            data : dptr
        },
        hdr : vid,
        dynm : members, 
    }
    if  obj == null  {
        fmt.println("[object_create2] failed to create")
        return Null
    }
    return obj
}

func object_parent_get2(obj<ObjectValue>){
    if obj == null {
        dief("[error] super()  obj is null".(i8))
    }
    if obj.base.type != Object {
        dief("[error] super()  not object2".(i8))
    }
    if obj.hdr.parent == null {
        dief("[error] super() called not in child class 2".(i8))
    }
    pm<u64> = obj.base.data + obj.hdr.membersize * 8
    return new ObjectValue {
        base : Value {
            type : Object,
            data : pm
        },
        hdr : obj.hdr.parent ,
        dynm: obj.dynm,
    } 
}

fn object_member_update2(obj<ObjectValue>,k<u64>,v<Value>){
    if  obj.base.type != Object {
        dief("[object_membe_update2] invalid obj type".(i8))
    }
    member<i64*> = objdataofs(obj.hdr ,obj.base.data,k)
    if member == Null {
        //warn("[object_membe_update2] warn not found object member\n".(i8))
        member_insert2(obj.dynm,k,v)
        return Null
    }
    *member = v
}

fn object_member_get2(k<u64>,obj<ObjectValue>){
    if  obj.base.type != Object {
        os.dief("[object_membe_get] invalid obj type :%s %d",runtime.type_string(obj),obj)
    }
    v<u64*> = objdataofs(obj.hdr,obj.base.data,k)
    if v == null {
        v = member_find2(obj.dynm,k)
        if v != null {
            return v
        }

        fmt.printf("[warn] class memeber not define in %s\n", debug.callerpc())
        return &internal_null
    }
    return *v
}

fn object_unary_operator2(opt<i32>,k<u64>,v<Value>,obj<ObjectValue>){
    if   obj == null || v == null  || obj.base.type != Object {
        fmt.println(" [object-uop2] probably wrong at there! object:%p rhs:%p\n",obj,int(v))
        return Null
    }
    origin<Value> = object_member_get2(k,obj)
    if origin == null origin = &internal_null
    
    ret<Value> = operator_switch(opt,origin,v)
    object_member_update2(obj,k,ret)
}

fn object_func_addr2(k<u64>,obj<ObjectValue>){
    if  obj.base.type != Object {
        os.dief("[object_func_addr] invalid obj type :%s",runtime.type_string(obj))
    }
    fctype<VObjFunc> = objfuncofs(obj.hdr,k)
    if fctype == null  {
        entry<FuncObject> = member_find2(obj.dynm,k)
        if entry == null {
            os.dief("[object-func] func not exist")
        } 
        if entry.type != Func {
            os.dief("[object-func] dyn func invalid ")
        }
        return entry.hdr.entry
    }
    return fctype.entry
}


fn member_find2(tree<map.Rbtree>,hk<u64>){

	node<map.RbtreeNode> = null
	sentinel<map.RbtreeNode> = null

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
        //if  node.k.type == key.type {
        //    return node.v
        //}
        return node.v
    }
    return Null
}

fn member_insert2(tree<map.Rbtree>, hk<u64>,v<Value>)
{

	node<map.RbtreeNode> = new map.RbtreeNode
    node.key   = hk
    //node.k     = hk
    node.v     = v
    tree.insert(node)
}