use std
use os

chars<std.Array> = null
func init(){
	chars = std.array_create(128.(i8),8.(i8))
	for i<i32> = 0 ; i < 128 ; i += 1 {
		c<Value> = new Value {
			type : Char,
			data : i
		}
		if chars.push(c) == Null {
			os.die("chars pool init: memory failed")
		}
	}
}
func chars_get(i<i8>){
	if i < 0 || i > 128 {
		os.dief("new char: value should >= 0 || < 128 %d",int(i))
	}
	return chars.addr[i]
}