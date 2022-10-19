

mem Lnode {
    u64*       value
    i32    	   size
	Lnode* next
}

mem List {
	Lnode* root
}

func push(list<List>,v<u64*>,size<i32>)
{
	node<Lnode> = std.malloc(sizeof(Lnode))
    node.value = v
    node.size = size
    node.next = Null
    if list.root == null {
        list.root = node
        return Null
    }
    node.next = list.root
    list.root = node
}
func mark(list<List>,v<u64*>){
	cur<Lnode> = list.root
    while cur != null 
	{
        if cur.value == v {
			hdr<Block> = v - 8
			flag_set(hdr,FLAG_MARK)
            for (p<u64*>  = v ; p < v + cur.size - 8 ; p += 1){
                gc_mark(*p)
            }
            return Null
        }
        cur = cur.next
    }
}
func del(list<List>,v<u64*>)
{
    if !list.root || !v return Null

	tmp<Lnode> = list.root
    if tmp.value == v {
        list.root = tmp.next
        return Null
    }
    while tmp != null && tmp.next != null {
        if tmp.next.value == v {
            tmp.next = tmp.next.next
            return Null
        }
        tmp = tmp.next
    }
}


