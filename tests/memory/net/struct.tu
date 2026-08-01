mem Data {
	i8 a,b,c,d
}

// Cross-pkg member call target (struct_inner.test_cross_pkg_member).
Data::bump_a(){
	this.a = this.a + 1
}

Data::set_flag(v<i8>){
	this.b = v
}
