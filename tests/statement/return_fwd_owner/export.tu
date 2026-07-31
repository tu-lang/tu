// Owner package for cross-pkg multi-return `return callee()` formal tests.

mem OwnerBox {
	i32 a
	i32 b
}

fn owner_pair() i32,i32 {
	return 100, 200
}

OwnerBox::as_pair() i32,i32 {
	return this.a, this.b
}

fn owner_member_pair() i32,i32 {
	p<OwnerBox> = new OwnerBox
	p.a = 30
	p.b = 40
	return p.as_pair()
}
