// Owner package for cross-pkg mem multi-return formal tests.

mem Inner {
	i32 tag
}

mem Box {
	i32    tag
	Inner* pe
	Box*   next
}

fn make_linked(tag<i32>) (i32, Box) {
	pe<Inner> = new Inner { tag: tag + 100 }
	tail<Box> = new Box { tag: tag + 1, next: null, pe: null }
	head<Box> = new Box { tag: tag, next: tail, pe: pe }
	return 1, head
}

const Box::make_linked(tag<i32>) (i32, Box) {
	pe<Inner> = new Inner { tag: tag + 100 }
	tail<Box> = new Box { tag: tag + 1, next: null, pe: null }
	head<Box> = new Box
	head.tag = tag
	head.pe = pe
	head.next = tail
	return 1, head
}
