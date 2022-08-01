
use fmt
use os
use runtime.gc
use std
use string

mem Array {
    u64*     addr
    u32   	 used
    u64   	 size
    u32      total
}
mem Array_iter {
	u64* addr
	u64* cur
}
func arr_get(varr<Value>,index<Value>){
    if  varr.type != Array {
        fmt.println("[arr_get] not array type")
        os.exit(-1)
    }

    if  varr == null || varr.data == null || index == null {
        fmt.println("[arr_get] arr or index is null ,probably something wrong\n")
        os.exit(-1)
    }

    arr<Array> = varr.data
    // 计算索引
    i<i64> = 0
    match index.type {
        Int : i = index.data
        String : i = string.stringlen(index.data)
        _   : os.die("[arr_get] invalid type: " + type_string(index.type) )
    }
    if  i >= arr.used {
        return newobject(Null,Null)
    }

    var<u64*> = arr.addr
    offset<i64> = i * 8
    var += offset

    return *var

}
func arr_pushone(varr<Value>,var<Value>){
    if  varr == null || varr.data == null || var == null {
        fmt.println("[arr_pushone] arr or var is null ,probably something wrong\n")
        return Null
    }
    arr<Array> = varr.data
    //FIXME: insert<u8*>= ... (>= 连起来解析错误)
    insert<u64*> = array_push(arr)
    *insert    = var
}
func arr_updateone(varr<Value>,index<Value>,var<Value>){
    if  varr == null || varr.data == null || index == null || var == null {
        fmt.println("[arr_updateone] arr or var or index is null ,probably something wrong\n")
        return Null
    }
    arr<Array> = varr.data
    i<i64> = 0

    match index.type {
        Int : i = index.data
        String : i = string.stringlen(index.data)
        # FIXME: _ : os.die("[arr_update]" invalid type" + type_string(index.type))
        _ : os.die("[arr_update] invalid type" + type_string(index.type))
    }
    // TODO:如果索引超出了 当前array的范围则需要扩充
    if  i >= arr.used {
        fmt.println("[arr_updateone] index is over the max size\n")
        return Null
    }
    // pp[i] = var
    pp<u64*> = arr.addr
    pp += i * 8
    *pp = var
}
func array_init(arr<Array>,n<u32>,size<u64>){
    arr.used = 0
    arr.size = size
    arr.total = n

    memsize<u64> = n * size
    arr.addr = new memsize

    if  arr.addr == null {
        return False
    }
    return True
}
func array_create(n<u32>,size<u64>){

    a<Array> = new Array
    if  a == null {
        fmt.println("[arr_create] failed to create\n")
        return Null
    }
    if   array_init(a,n,size)  != True {
        fmt.println("[arr_init] failed to init\n")
        return Null
    }
    return a
}
func array_destroy(a<Array>){
    gc.gc_free(a)
}
func array_pop(arr<Array>){
    if  arr == null os.die("[arr_pop] not array_type")

    if arr.used <= 0 {
        fmt.println("[warn] array_pop for empty array")
        return newobject(Null,Null)
    }

    var<u64*> = arr.addr
    //pop one 
    arr.used -= 1

    offset<i64> = arr.used * arr.size
    var += offset

    return *var
}
func array_push(a<Array>){
    size<u64> =  0
    newp<u64*> = null
    elt<u64*> = null
    if  a.used == a.total {
        // 数组满了
        size = a.size * a.total
        // 直接扩充2倍
        newp = gc.gc_malloc(size * 2)
        if  newp == null {
            fmt.println("[arr_pushn] failed to expand memeory")
            return Null
        }
        std.memcpy(newp,a.addr,size)
        //手动释放之前绝对不会用到的数组,降低gc压力
        gc.gc_free(a.addr)
        a.addr = newp
        //扩充2倍
        a.total *= 2
    }
    elt = a.addr + a.size * a.used
    a.used += 1
    return elt
}
//NOTICE: only support plain memory data
func array_in(v1<Value>,v2<Array>){
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
func array_merge(v1<Array>,v2<Array>){
    if v1.size != v2.size {
        fmt.println("[warn] array_merge: incompact with size")
        return False
    }
    p<u64*>  = array_push_n(v1,v2.used)
    if p == Null {
        fmt.println("[warn] array_merge: array_push_n failed")
        return False
    }
    std.memcpy(p, v2.addr, v2.used * v2.size)
    return True
}
func array_push_n(a<Array>,n<u32>)
{
    elt<u64*>  = null
    newp<u64*> = null
    size<u64>  = 0
    total<u32> = 0

    size = n * a.size

    if  a.used + n > a.total  {
        //数组满了
        if  n >= a.total  total = 2 * n
        else total = 2 * a.total

        newp = gc.gc_malloc(total * a.size)
        if  newp == null  {
            fmt.println("[arr_pushn] failed to expand memeory")
            return Null
        }
        std.memcpy(newp, a.addr, a.used * a.size)
        //手动释放拷贝前的数组降低gc压力
        gc.gc_free(a.addr)
        a.addr = newp
        a.total = total
    }
    elt = a.addr + a.size * a.used
    a.used += n

    return elt
}
func arr_tostring(varr<Value>)
{
    ret<i8*>   = string.stringempty()
    arr<Array> = varr.data
    orr<u64*>  = arr.addr

    ret = string.stringcat(ret,*"[")

    for (i<i32> = 0 ; i < arr.used ; i += 1) {
        p<u64*>  = orr + i * PointerSize
        v<Value> = *p
        //String
        if v.type == String {
            ret = string.stringcat(ret,v.data)
            ret = string.stringcat(ret,*",")
        //Int,Float,Bool,Char
        }else {
            ret = string.stringcatfmt(ret,*"%I,",v.data)
        }
    }
    ret = string.stringcat(ret,*"]")
    return ret
}