mem Map {
	Rbtree* rb
	u64     hashfn
}
mem MapIter {
    Rbtree*     rb
    RbtreeNode* node
}
MapIter::v(){
    if this.node != null
        return this.node.v
    return End
}
MapIter::k(){
    if this.node != null
        return this.node.k
    return End
}
MapIter::next(){
    if this.rb.root == this.rb.sentinel { 
        return End
    }
    if this.node == null {
        node<RbtreeNode> =  this.rb.root.min(this.rb.sentinel)
        if node == Null return End
        this.node = node
        return node
    }

    this.node = this.rb.next(
        this.node
    )
    if this.node == Null {
        return End
    }
    return this.node
}

func map_new(hashfn<u64>,insertfn<u64>){

    if insertfn == null {
        insertfn = map_insert_or_update_default.(u64)
    }
    sentinel<RbtreeNode> = new RbtreeNode
	sentinel.black()

	rb<Rbtree> =  new Rbtree {
		root : sentinel,
		sentinel : sentinel,
		insert: insertfn,
	}
	return new Map {
		rb : rb,
		hashfn : hashfn
	}
}

func map_insert_or_update_default(temp<RbtreeNode>, node<RbtreeNode>,sentinel<RbtreeNode>)
{
    p<u64*> = null
    loop {
        if  node.key == temp.key {
            temp.v = node.v
            return Update
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

Map::insert( k<u64*>,v<u64*>){
    tree<Rbtree> = this.rb
    hk<u64> = k
	if this.hashfn != null {
		hfn<u64> = this.hashfn
		hk = hfn(k)
	}
	node<RbtreeNode> = new RbtreeNode {
		key : hk,
		k   : k,
		v   : v	
	}
    tree.insert(node)
	return True
}

Map::find(key<u64>){
    hk<u64> = key
	if this.hashfn != null {
		hashfn<u64*> = this.hashfn
		hk = hashfn(key)
	}
	return this.rb.find(hk)
}

Map::iter(){
    return new MapIter{
        rb  : this.rb,
    }
}