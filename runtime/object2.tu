
use fmt
use os
use std
use string
use std
use std.map

mem VObjFunc {
	u64 hid    , entry
    i64 isvarf , argstack
    i64 retsize, retstack
	i32 argsize, asyncsize
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

func newfuncobject(entry<u64>,as<i32>,isvarf<i32>,retsize<i32>){
    return new FuncObject {
        type : Func,
        hdr : VObjFunc {
            isvarf : isvarf,
            argstack: as * 8,
            argsize : as,
            retsize: retsize,
            retstack: (retsize - 1) * 8,
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
        dief(*"[object_create2] failed to create")
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

fn object_offset_get(ofs<u32> , obj<ObjectValue>){
    if  obj.base.type != Object {
        os.dief("[op-obj-ofs] invalid obj type :%s %d",runtime.type_string(obj),obj)
    }
    mber<u64*> = obj.base.data + ofs
    return *mber
}

fn object_member_get2(k<u64>,obj<ObjectValue>){
    if  obj.base.type != Object {
        dief(*"[object_membe_get] invalid obj type :%d\n",obj.base.type)
        // os.dief("[object_membe_get] invalid obj type :%s %d",runtime.type_string(obj),obj)
    }
    v<u64*> = objdataofs(obj.hdr,obj.base.data,k)
    if v == null {
        v = member_find2(obj.dynm,k)
        if v != null {
            return v
        }

        printf("[warn] class memeber not define in %s\n", debug.callerpc())
        return &internal_null
    }
    return *v
}

fn object_unary_operator2(opt<i32>,k<u64>,v<Value>,obj<ObjectValue>){
    if   obj == null || v == null  || obj.base.type != Object {
        warn(*" [object-uop2] probably wrong at there! object:%p rhs:%p\n",obj,v)
        return Null
    }
    origin<Value> = null
    mber<u64*> = objdataofs(obj.hdr,obj.base.data,k)
    if mber == null {
        mber = member_find2(obj.dynm,k)
        if mber != null {
            origin = mber
        }else {
            printf("[warn] unary class memeber not define in %s\n", debug.callerpc())
            origin = &internal_null
        }
    } else {
        origin = *mber
    }
    
    ret<Value> = operator_switch(opt,origin,v)
    object_member_update2(obj,k,ret)
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

fn object_func_addr2(k<u64>,obj<ObjectValue>){
    if  obj.base.type != Object {
        dief(*"[object_func_addr] invalid obj type %d",obj.base.type)
    }
    fctype<VObjFunc> = objfuncofs(obj.hdr,k)
    if fctype == null  {
        entry<FuncObject> = member_find2(obj.dynm,k)
        if entry == null {
            dief(*"[object-func] func not exist k:%s\n",string.fromulonglong(k))
        } 
        if entry.type != Func {
            dief(*"[object-func] dyn func invalid \n")
        }
        return &entry.hdr
    }
    return fctype
}

fn get_func_value(obj<FuncObject>){
    if  obj == null {
        dief("func ptr is null".(i8))
    }
    if obj.type != Func {
        dief("call not func object".(i8))
    }
    return &obj.hdr
}


fn dynarg_pass(fc<VObjFunc>...){ 
    passstack<u64*> = &fc  
    passstack += ptrSize  //typeinfo         

    userstack<u64*> = passstack + fc.argstack + ptrSize //pad
    count<i32> = userstack[0]       
    countaddr<i64*> = userstack     
    userstack += ptrSize  
    retstackptr<u64> = userstack[count]

    //variadic args pass
    if fc.isvarf { 
        copy<i32> = fc.argsize - 1 
        if copy == 0 {
            passstack[0] = countaddr  
            if fc.retsize > 1
                passstack[1] =  retstackptr
        }else{
            j<i32> = 0
            last<i32> = 0
            for i<i32> = 0 ; i < copy ; i += 1 {
                if j + 1 > count {
                    passstack[i] = &internal_null
                }else{
                    passstack[i] = userstack[j]
                    last = j 
                    j += 1   
                }
            }
            if count == 0 {
                passstack[copy] = countaddr
            }else {
                passstack[copy] = userstack + last * 8
                userstack[last] = count - j
            }
            if fc.retsize > 1
                passstack[copy + 1] = retstackptr
        }
        return fc.entry
    }
    //normal pass args
    copy<i32> = fc.argsize 
    j<i32> = 0
    for i<i32> = 0 ; i < copy ; i += 1 {
        if j + 1 > count { 
            passstack[i] = &internal_null
        }else{
            passstack[i] = userstack[j]
            j  += 1
        }
    } 
    //make the ret pointer be the last user arg
    if fc.retsize > 1
        passstack[copy] = retstackptr
    return fc.entry
}

fn dynarg_varadicerr1(){
    os.die("pass varadict args, args count is not equal")
}