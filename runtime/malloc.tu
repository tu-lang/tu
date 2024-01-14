use fmt
use os
use std

fn largeAlloc(size<u64>, needzero<u8> , noscan<u8>)
{
	if size + pageSize < size {
		dief("out of memory\n".(i8))
	}
	npages<u64> = 0
	s<Span> = null

	npages = size >> pageShift 
	if( size & PageMask != 0 ) {
		npages += 1
	}
	s = heap_.alloc(npages, makeSpanClass(0.(i8),noscan), 1.(i8), needzero)
	if( s == null ){
		dief("out of memory\n".(i8))
	}
	s.limit = s.startaddr + size
	h<HeapBits:> = null
	h.heapBitsForAddr(s.startaddr)
	h.initSpan(s)
	return s
}


fn malloc(size<u64> , noscan<u8> , needzero<u8>)
{
	if size == 0 {
		//only this can use dynamic grammer,cos it's easy to backtrace
		os.die("malloc size == 0")
	}
	if( gcphase != _GCoff){}

	assistG<Coroutine> = null
	if( gcBlackenEnabled != 0 )
	{
		assistG = getg()
		if( assistG.m.curg != null ){
			assistG = assistG.m.curg
		}
		assistG.gcAssistBytes -= size
	}

	mp<Core> = acquirem()
	if( mp.mallocing != 0 ){ 
		dief("malloc deadlock".(i8))
	}
	if( mp.gsignal == getg() ){
		dief("malloc during signal".(i8))
	}
	mp.mallocing = 1
	shouldhelpgc<u8> = false
	dataSize<u64>  = size
	g<Coroutine> = getg()
	c<Cache> = g.m.mcache
	x<u64*> = null
	if( size <= maxSmallSize ){ 
		if( noscan && size < maxTinySize ){
			off<u64> = c.tinyoffset
			if( size&7 == 0 ) {
				off = round(off, 8.(i8))
			} else if( size&3 == 0 ){
				off = round(off, 4.(i8))
			} else if( size&1 == 0 ){
				off = round(off, 2.(i8))
			}
			if( off+size <= maxTinySize && c.tiny != 0 ){
				x = (c.tiny + off)
				c.tinyoffset = off + size
				c.local_tinyallocs += 1
				mp.mallocing = 0
				releasem(mp)
				return x
			}
			s<Span> = c.alloc[tinySpanClass]
			v<u64> = s.nextFreeFast()

			if( v == 0 ) {
				v = c.nextFree(tinySpanClass,&s,&shouldhelpgc)
			}
			x = v
			//clear 16 bits
			x[0] = 0
			x[1] = 0
			if( size < c.tinyoffset || c.tiny == 0 ){
				c.tiny = x
				c.tinyoffset = size
			}
			size = maxTinySize
		} else {
			sz<u8> = 0
			if( size <= smallSizeMax - 8 ){
				sz = size_to_class8[(size+smallSizeDiv - 1)/smallSizeDiv]
			} else {
				sz = size_to_class128[(size-smallSizeMax+largeSizeDiv - 1)/largeSizeDiv]
			}
			size = (class_to_size[sz])
			spc<u8> = makeSpanClass(sz, noscan)
			s<Span> = c.alloc[spc]
			v<u64> = s.nextFreeFast()
			if( v == 0 ){
				v = c.nextFree(spc,&s,&shouldhelpgc)
			}
			x = v
			if( needzero && s.needzero != 0 ){
				std.memset(v,0.(i8),size)
			}
		}
	} else {
		s<Span> = null
		shouldhelpgc = true
		s = largeAlloc(size,needzero,noscan)
		s.freeindex = 1
		s.allocCount = 1
		x = s.startaddr
		size = s.elemsize
	}

	scanSize<u64> = null

	if( !noscan ){
		scanSize = size
		c.local_scan += scanSize
	}

	if( gcphase != _GCoff ){
	}

	mp.mallocing = 0 
	releasem(mp)

	if( assistG != null ){
	}

	if( shouldhelpgc ){
	}
	return x
}

mem TreapNode {

    TreapNode* right
    TreapNode* left
    TreapNode* parent

    u64     npagesKey
    Span*   spankey
    u32     priority
}
mem Treap {
    TreapNode* root
}
func rotateLeft(root<Treap>,x<TreapNode>)
{
	p<TreapNode> = x.parent
	a<TreapNode> = null
	y<TreapNode> = null
	b<TreapNode> = null
	c<TreapNode> = null
	a = x.left
	y = x.right
	b = y.left
	c = y.right

	y.left = x
	x.parent = y
	y.right = c
	if ( c != null ){
		c.parent = y
	}
	x.left = a
	if ( a != null ){
		a.parent = x
	}
	x.right = b
	if ( b != null ){
		b.parent = x
	}

	y.parent = p
	if ( p == null ){
		root.root = y
	} else if ( p.left == x ){
		p.left = y
	} else {
		if ( p.right != x ){
			dief(" large span treap roateleft".(i8))
		}
		p.right = y
	}
}

func rotateRight(root<Treap>,y<TreapNode>)
{

	p<TreapNode> = y.parent
	x<TreapNode> = null
	c<TreapNode> = null 
	a<TreapNode> = null
	b<TreapNode> = null
	x = y.left
	c = y.right
	a = x.left
	b = x.right

	x.left = a
	if ( a != null ){
		a.parent = x
	}
	x.right = y
	y.parent = x
	y.left = b
	if ( b != null ){
		b.parent = y
	}
	y.right = c
	if ( c != null ){
		c.parent = y
	}

	x.parent = p
	if ( p == null ){
		root.root = x
	} else if ( p.left == y ){
		p.left = x
	} else {
		if ( p.right != y ){
		    dief("large span treap rotateRight".(i8))
		}
		p.right = x
	}
}

Treap::find(npages<u64>){
	best<TreapNode> = null
	t<TreapNode> = this.root
	while(t != null)
	{
		if(t.spankey == null){
			dief(" treap node with null spankey found".(i8))
		}
		if( t.npagesKey >= npages ){
			best = t
			t = t.left
		} else {
			t = t.right
		}
	}
	return best
}

Treap::removeNode(t<TreapNode>){

	if(t.spankey.npages != t.npagesKey ){
		dief("span and treap node npages do not match\n".(i8))
	}
	while(t.right != null || t.left != null ) {
		if ( t.right == null || t.left != null &&  t.left.priority < t.right.priority ) {
			rotateRight(this,t)
		} else {
			rotateLeft(this,t)
		}
	}
	if ( t.parent != null ) {
		if (t.parent.left == t ){
			t.parent.left = null
		} else {
			t.parent.right = null
		}
	} else {
		this.root = null
	}
	heap_.treapalloc.free(t)
}

Treap::removeSpan(s<Span>)
{
	npages<u64> = s.npages
	t<TreapNode> = this.root
	while( t.spankey != s ){
		if ( t.npagesKey < npages ) {
			t = t.right
		} else if ( t.npagesKey > npages ) {
			t = t.left
		} else if ( t.spankey.startaddr < s.startaddr ) {
			t = t.right
		} else if ( t.spankey.startaddr > s.startaddr ) {
			t = t.left
		}
	}
	this.removeNode(t)
}

Treap::insert(s<Span>)
{

	npages<u64> = s.npages
	last<TreapNode> = null
	pt<u64*> = &this.root
	for ( t<TreapNode> = *pt; t != null; t = *pt ) {
		last = t
		if ( t.npagesKey < npages ){
			pt = &t.right
		} else if ( t.npagesKey > npages ){
			pt = &t.left
		} else if ( t.spankey.startaddr < s.startaddr ){
			pt = &t.right
		} else if ( t.spankey.startaddr > s.startaddr ){
			pt = &t.left
		} else {
			dief("inserting span already in treap\n".(i8))
		}
	}

	t<TreapNode> = heap_.treapalloc.alloc()
	t.npagesKey = s.npages
	t.priority  = fastrand()
	t.spankey   = s
	t.parent    = last
	*pt           = t 
	while( t.parent != null && t.parent.priority > t.priority ) {
		if ( t != null && t.spankey.npages != t.npagesKey ) {
			// fmt.printf("runtime: insert t=%p t.npagesKey=%ld\n",t, t.npagesKey)
			// fmt.printf("runtime:      t.spankey=%ld t.spankey.npages=%ld\n",t.spankey, t.spankey.npages)
			// fmt.printf("span and treap sizes do not match?")
			dief(" span and treap sizes die".(i8))
		}
		if ( t.parent.left == t ) {
			rotateRight(this,t.parent)
		} else {
			if (t.parent.right != t ) {
				dief(" treap insert finds a broken treap".(i8))
			}
			rotateLeft(this,t.parent)
		}
	}
}

Treap::end()
{
	t<TreapNode> = this.root
    if(t == null) return 0.(i8)
    while t.right != null{
        t = t.right
	}
    return t
}

TreapNode::pred()
{
	t<TreapNode> = this
    if ( t.left != null ) {
        t = t.left
        while( t.right != null ) {
            t = t.right
        }
        return t
    }
    while( t.parent != null && t.parent.right != t ){
        if (t.parent.left != t ) {
            dief("node is not its parent's child".(i8))
        }
        t = t.parent
    }
    return t.parent
}