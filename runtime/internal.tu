//TODO: prohibit modificate
internal_bool_true<Value:> = new Value {
	type : 4,//Bool
	data : 1
}
internal_bool_false<Value:> = new Value {
	type : 4,//Bool
	data : 0
}
internal_null<Value:> = new Value {
	type : 0, //Null
	data : 0
}

//implement by asm
func callerpc()
func nextpc(){
	return callerpc()
}