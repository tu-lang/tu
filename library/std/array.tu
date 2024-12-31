
use fmt
use os
use string
use runtime

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
func NewArray(n<u32>,size<u64>){
    if n == 0 n = ARRAY_SIZE
    if size == 0 size = runtime.PointerSize

    a<Array> = new Array
    if  a == null {
        fmt.println("[arr_create] failed to create\n")
        return Null
    }
    if a.init(n,size)  != runtime.True {
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
        return runtime.False
    }
    return runtime.True
}
Array::array_destroy(){
    runtime.gc_free(this)
}

Array::get(i<i64>) {
    if i >= this.used {
        return Null
    }
    match this.size {
        1 : {
            addr<u8*> = this.addr 
            return addr[i]
        }
        2 : {
            addr<u16*> = this.addr 
            return addr[i]
        }
        4 : {
            addr<u32*> = this.addr 
            return addr[i]
        }
        8 : {
            addr<u64*> = this.addr 
            return addr[i]
        }
        _ : dief(*"Array::get size not allowed:%d\n",this.size)
    }
}
Array::tail(){
    if  this == null os.die("[arr_tail] not array_type")
    if this.used <= 0 {
        os.die("[warn] tail empty array")
        // fmt.println("[warn] array_tail for empty array")
        // return runtime.newobject(Null,Null)
    }
    return this.get(this.used - 1)
}
Array::head(){
    if  this == null os.die("[arr_head] not array_type")
    if this.used <= 0 {
        fmt.println("[warn] array_head for empty array")
        return Null
    }
    return this.get(0.(i8))
}

Array::pop(){
    if  this == null os.die("[arr_pop] not array_type")

    if this.used <= 0 {
        fmt.println("[warn] array_pop for empty array")
        return runtime.newobject(Null,Null)
    }

    data<u64> = this.get(this.used - 1)
    //pop one 
    this.used -= 1
    return data
}

Array::expand(){
    // if  this.used != this.total {
        // return True
    // }
    size<u64> = this.size * this.total
    newp<u64*> = runtime.gc_malloc(size * 2)
    if  newp == null {
        fmt.println("[arr_expand] failed to expand memeory")
        return Null
    }
    memcpy(newp,this.addr,size)
    runtime.gc_free(this.addr)
    this.addr = newp
    this.total *= 2
}

Array::push(ele<u64>){
    if this.used == this.total {
        this.expand()
    }
    match this.size {
        1 : {
            insrt<u8> = ele
            addr<u8*> = this.addr 
            addr[this.used] = insrt
        }
        2 : {
            insrt<u16> = ele
            addr<u16*> = this.addr 
            addr[this.used] = insrt
        }
        4 : {
            insrt<u32> = ele
            addr<u32*> = this.addr 
            addr[this.used] = insrt
        }
        8 : {
            insrt<u64> = ele
            addr<u64*> = this.addr 
            addr[this.used] = insrt
        }
        _ : dief(*"Array::push size not allowed:%d\n",this.size)
    }
    this.used += 1
    return ele
}

Array::merge(v2<Array>){
    if this.size != v2.size {
        fmt.println("[warn] array_merge: incompact with size")
        return runtime.False
    }
    p<u64*>  = this.pushN(v2.used)
    if p == Null {
        fmt.println("[warn] array_merge: array_push_n failed")
        return runtime.False
    }
    memcpy(p, v2.addr, v2.used * v2.size)
    return runtime.True
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

        newp = runtime.gc_malloc(total * this.size)
        if  newp == null  {
            fmt.println("[arr_pushn] failed to expand memeory")
            return Null
        }
        memcpy(newp, this.addr, this.used * this.size)
        runtime.gc_free(this.addr)
        this.addr = newp
        this.total = total
    }
    elt = this.addr + this.size * this.used
    this.used += n

    return elt
}
Array::len(){
    return this.used
}
Array::cap(){
	return this.total
}