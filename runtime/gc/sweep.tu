use runtime
use string

func get_sp()
func get_di()
func get_si()
func get_dx()
func get_cx()
func get_r8()
func get_r9()
func get_bp()
func get_ax()
func get_bx()

func gc_mark(ptr<u64*>)
{
    if ptr == Null return True

    po<Pool>  = pool_addr(ptr)
    areobj<Arena> = arenas
    if po < areobj.address || areobj.address + ARENA_SIZE < po{
        // mark(&Hugmem,ptr)
        return NOT_STACK
    }
    if in_heap(ptr,po) != True {
        // mark(&Hugmem,ptr)
        return NOT_STACK
    }

    size<i32> = index2size(po.szidx)

    hdr<Block> = ptr - 8
    if hdr.mask == BLOCK_MASK {
        if hdr.flags < 1 || hdr.flags > 3     return True
        if flag_test(hdr,FLAG_ALLOC) == False return True
        if flag_test(hdr,FLAG_MARK) == True   return True
        flag_set(hdr,FLAG_MARK)
    }
    for (p<u64*> = ptr ; p < ptr + size - 8 ; p += 1) {
        if gc_mark(*p) == NOT_STACK {
            mark(hugmem,*p)
        }
    }
    return True
}
func gc_sweep()
{

    area<Arena> = arenas 
    
    for (p<u64> = area.first_address ; p < area.pool_address ; p += POOL_SIZE)
    {
        po<Pool> = p

        size<i32> = index2size(po.szidx)
        start_addr<u64> = p + POOL_OVERHEAD
        end_addr<u64>   = p + POOL_SIZE
        for (pp<u64> = start_addr ; pp < end_addr ; pp += size)
        {
            obj<Block> = pp
            if obj.mask != BLOCK_MASK {
                continue
            }
            if flag_test(obj,FLAG_ALLOC) != False 
            {
                if flag_test(obj,FLAG_MARK) != False
                    flag_unset(obj,FLAG_MARK)
                else {
                    flag_unset(obj,FLAG_ALLOC)
                    free(pp)
                }
            }
        }
    }
}
func tell_is_stackarg(arg<u64*>){
    if arg == null return True
    top<u64> = get_sp()
    if spstart > arg  && arg > top {
        if gc_mark(*arg) == NOT_STACK {
            mark(hugmem,*arg)
        }
    }
}
func scan_register()
{
    reg<u64*> = null
    reg = get_sp()  tell_is_stackarg(reg)
    reg = get_bp()  tell_is_stackarg(reg)
    reg = get_di()  tell_is_stackarg(reg)
    reg = get_si()  tell_is_stackarg(reg)
    reg = get_dx()  tell_is_stackarg(reg)
    reg = get_cx()  tell_is_stackarg(reg)
    reg = get_r8()  tell_is_stackarg(reg)
    reg = get_r9()  tell_is_stackarg(reg)
    reg = get_ax()  tell_is_stackarg(reg)
    reg = get_bx()  tell_is_stackarg(reg)
}
func scan_stack(){
    cur_sp<u64*> = get_sp()
    if spstart < cur_sp {
        die(*"spstart should >= cur_sp")
    }
    ai<i32> = 0
    for ( cur_sp ;cur_sp < spstart ; cur_sp += 2){
        ptr<u64> = *cur_sp
        v<runtime.Value> = ptr
        hdr<Block> = ptr - 8
        po<Pool> = pool_addr(ptr)
        areobj<Arena> = getarena(ai) 
        #FIXME: po(-4191910998841462784) > 140577428357136 should be false
        if po < areobj.address || areobj.address + ARENA_SIZE < po {
            continue
        }
        if in_heap(ptr,po) == False {
            continue
        }
        if hdr.flags < 1 || hdr.flags > 3 {
            string.stringmark(ptr)
            continue
        }
        if v.type == runtime.String {
            //TODO: fix 会有 type=string data=1的情况
            temp_po<Pool> = pool_addr(v.data)
            if temp_po < areobj.address || areobj.address + ARENA_SIZE < temp_po {
            }else{
                string.stringmark(v.data)
            }
        }
        if gc_mark(ptr) == NOT_STACK {
            mark(hugmem,ptr)
        }
    }
}
func gc()
{
    return runtime.Null
    scan_register()
    scan_stack()

    gc_sweep()
}

