use std.atomic

mem Node {
    u64  next
    u64  pushcnt
}

mem List {
    u64 self
}
mem Buf {
    Node     node
    i32      nobj
    u64      obj[BufObjsize]
}
mem Queue {
    Buf*  buf1
	Buf*  buf2
    u64   used 
    u64   u8used
    i32   flushed
}

Buf::checkempty(){
	if this.nobj != 0 {
		dief(*"Buf is not empty")
	}
}
Buf::checknoempty(){
	if this.nobj == 0 {
		dief(*"Buf is empty")
	}
}
fn putempty(b<Buf>){
	b.checkempty()
	gc.empty.push(&b.node)
}
fn putfull(b<Buf>){
	b.checknoempty()
	gc.full.push(&b.node)
}
fn getempty() {
	tracef(*"cycle:%d",gc.cycles)
	b<Buf> = Null
	if gc.empty.self != 0 {
	    b = gc.empty.pop()
		if b != Null && b.nobj != 0  {
		    dief(*"work buf is not empty!\n")
		}
	}
	if  b == Null {
		s<Span> = Null
		if  gc.spans.free.first != Null  {
			gc.spans.lock.lock()
			s = gc.spans.free.first
			if s != Null {
				gc.spans.free.remove(s)
				gc.spans.busy.insert(s)
			}
			gc.spans.lock.unlock()
		}
		if  s == Null {
		    s = heap_.allocManual(BufAlloc/pageSize)
			if s == Null {
				dief(*"out of memory\n")
			}
			gc.spans.lock.lock()
			gc.spans.busy.insert(s)
			gc.spans.lock.unlock()
		}
		for i<u64> = 0; (i + WorkbufSize) <= BufAlloc; i += WorkbufSize {
			newb<Buf> = s.startaddr + i
			newb.nobj    = 0
			newb.node.validate()

			if i == 0  {
				b = newb
			} else {
				putempty(newb)
			}
		}
	}
	return b
}
fn trygetfull() {
    b<Buf> = gc.full.pop()
	if b != Null {
	    if b.nobj == 0 {
	        dief(*"work buf is empty!")
	    }
		return b
	}
	return b
}

Queue::init()
{
    this.buf1    = getempty()
    this.buf2  = trygetfull()

    if  this.buf2 == Null {
        this.buf2 = getempty()
    }
}

Queue::putFast(obj<u64>)
{
    buf<Buf> = this.buf1
	if ( buf == Null) {
		return Null
	} else if ( buf.nobj == BufObjsize ) {
		return Null
	}

	buf.obj[buf.nobj] = obj
	buf.nobj += 1
	return True
}

Queue::tryGetFast(){
	buf<Buf> = this.buf1
	if buf == Null {
		return 0.(i8)
	}
	if (buf.nobj == 0.(i8) ){
		return 0.(i8)
	}

	buf.nobj -= 1
	return buf.obj[buf.nobj]
}

Queue::tryGet()
{
	buf<Buf> = this.buf1
	if buf == Null {
		this.init()
		buf = this.buf1
	}
	if buf.nobj == 0 {
	    tmp<Buf> = this.buf1
	    this.buf1 = this.buf2
	    this.buf2 = tmp
		buf = this.buf1
		if buf.nobj == 0 {
			obuf<Buf> = buf
			buf = trygetfull()
			if (buf == Null ){
				return 0.(i8)
			}
			putempty(obuf)
			this.buf1 = buf
		}
	}

	buf.nobj -= 1
	return buf.obj[buf.nobj]
}

Queue::put(obj<u64>)
{
	flushed<i32>  = false
	buf<Buf> = this.buf1
	if (buf == Null ){
		this.init()
		buf = this.buf1
	} else if (buf.nobj == BufObjsize )
	{
	    t<Buf> = this.buf1
	    this.buf1   = this.buf2
	    this.buf2   = t

		buf = this.buf1
		if ( buf.nobj == BufObjsize){
			gc.full.push(&buf.node)
			this.flushed = true
			buf = getempty()
			this.buf1 = buf
			flushed = true
		}
	}

	buf.obj[buf.nobj] = obj
	buf.nobj += 1

}

Queue::empty(){
	return this.buf1 == Null || (this.buf1.nobj == 0 && this.buf2.nobj == 0)
}

Queue::dispose(){
	buf<Buf> = this.buf1
	if(buf != Null){
		if(buf.nobj == 0){
			putempty(buf)
		}else{
			putfull(buf)
			this.flushed = true
		}
		this.buf1 = Null

		buf = this.buf2
		if(buf.nobj == 0){
			putempty(buf)
		}else{
			putfull(buf)
			this.flushed = true
		}
		this.buf2 = Null
	}
	if(this.used != 0 ){
		atomic.xadd64(&gc.marked,this.used)
		this.used = 0
	}
}


fn nodePack(node<Node>, cnt<u64>)
{
	onode<u64> = node
	onode <<= (64 - addrBits)
	ocnt<u64> = cnt & (1 << (cntBits - 1))
	return onode | ocnt
}
fn nodeUnPack(val<u64>){
    return (val >> cntBits)  << 3
}

Node::validate(){
    if nodeUnPack(nodePack(this, -1.(i8))) != this {
        dief(*"bad lfnode address\n")
    }
}

List::push(node<Node>)
{
	node.pushcnt += 1
	newp<u64> = nodePack(node, node.pushcnt)
	node1<Node> = nodeUnPack(newp)
	if ( node1 != node ){
		dief(*"lfstack.push\n")
	}
	loop {
		old<u64> = atomic.load64(this)
	    node.next = old
		if atomic.cas64(this, old, newp) != False  {
			break
		}
	}
}
List::pop()
{
	loop {
		old<u64> = atomic.load64(this)
		if( old == 0 ){
			return Null
		}
		node<Node> = (old >> cntBits) << 3
		next<u64> = node.next
		if atomic.cas64(this, old, next) != Null {
		    return node
		}
	}
}