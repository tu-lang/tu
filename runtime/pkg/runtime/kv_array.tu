
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
func array_create(n<u32>,size<u64>){

    a<Array> = new Array
    if  a == null {
        fmt.println("[arr_create] failed to create\n")
        return Null
    }
    if a.init(n,size)  != True {
        fmt.println("[arr_init] failed to init\n")
        return Null
    }
    return a
}
Array::init(n<u32>,size<u64>){
    this.used = 0
    this.size = size
    this.total = n

    memsize<u64> = n * size
    this.addr = new memsize

    if  this.addr == null {
        return False
    }
    return True
}
Array::array_destroy(){
    gc.gc_free(this)
}
Array::tail(){
    if  this == null os.die("[arr_tail] not array_type")
    if this.used <= 0 {
        fmt.println("[warn] array_tail for empty array")
        return newobject(Null,Null)
    }
    return this.addr[this.used - 1]
}
Array::head(){
    if  this == null os.die("[arr_head] not array_type")
    if this.used <= 0 {
        fmt.println("[warn] array_head for empty array")
        return Null
    }
    return this.addr[0]
}

Array::pop(){
    if  this == null os.die("[arr_pop] not array_type")

    if this.used <= 0 {
        fmt.println("[warn] array_pop for empty array")
        return newobject(Null,Null)
    }

    //pop one 
    this.used -= 1

    return this.addr[this.used]
}
Array::push(){
    size<u64> =  0
    newp<u64*> = null
    elt<u64*> = null
    if  this.used == this.total {
        size = this.size * this.total
        newp = gc.gc_malloc(size * 2)
        if  newp == null {
            fmt.println("[arr_pushn] failed to expand memeory")
            return Null
        }
        std.memcpy(newp,this.addr,size)
        gc.gc_free(this.addr)
        this.addr = newp
        this.total *= 2
    }
    elt = this.addr + this.size * this.used
    this.used += 1
    return elt
}

Array::merge(v2<Array>){
    if this.size != v2.size {
        fmt.println("[warn] array_merge: incompact with size")
        return False
    }
    p<u64*>  = this.pushN(v2.used)
    if p == Null {
        fmt.println("[warn] array_merge: array_push_n failed")
        return False
    }
    std.memcpy(p, v2.addr, v2.used * v2.size)
    return True
}
Array::pushN(n<u32>)
{
    elt<u64*>  = null
    newp<u64*> = null
    size<u64>  = 0
    total<u32> = 0

    size = n * this.size

    if  this.used + n > this.total  {
        if  n >= this.total  total = 2 * n
        else total = 2 * this.total

        newp = gc.gc_malloc(total * this.size)
        if  newp == null  {
            fmt.println("[arr_pushn] failed to expand memeory")
            return Null
        }
        std.memcpy(newp, this.addr, this.used * this.size)
        gc.gc_free(this.addr)
        this.addr = newp
        this.total = total
    }
    elt = this.addr + this.size * this.used
    this.used += n

    return elt
}