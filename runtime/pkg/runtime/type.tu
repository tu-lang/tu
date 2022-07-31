
# array
ARRAY_SIZE<i8>  = 8

# base
PointerSize<i32>    = 8
True<i32>   		= 1
False<i32>  		= 0
Zero<i32>			= 0
Positive1<i32>		= 1
Negative1<i32> 		= -1

mem Value  { 
	u64 type,data 
}
mem Object { 
	Rbtree* members
	Rbtree* funcs
	Object* father
	i32		typeid
}
func type(v<Value>, obj<i8>){
	if obj == 1 {
		match v.type {
			Null : return 0
			Int  : return 1
			Float : return 2
			String : return 3
			Bool : return 4
			Char : return 5
			Array : return 6
			Map  : return 7
			Object : {
				o<Object> = v.data
				return int(o.typeid)
			}
			_    : return "type: unknown type:" + int(v.type)				
		}
	}else {
		return int(v)
	}
}

func type_string(t<i8>){
	match t {
		Null : return "null"
		Int  : return "int"
		Float : return "float"
		String : return "string"
		Bool : return "bool"
		Char : return "char"
		Array : return "array"
		Map  : return "map"
		Object : return "object"
		_    : return "unknown type:" + int(t)
	}
}
func is_map(map<Value>){
	if  map.type == Map {
		return true
	}
	return false
}
func is_array(arr<Value>){
	if  arr.type == Array {
		return true
	}
	return false
}

I8_MAX<i8> = 127 	 
I8_MIN<i8> = -128 				 	
U8_MAX<u8> = 255 						
U8_MIN<u8> = 0 

I16_MAX<i16> = 32767 					
I16_MIN<i16> = -32768 				 	
U16_MAX<u16> = 65535 					
U16_MIN<u16> = 0 

I32_MAX<i32> = 2147483647 				
I32_MIN<i32> = -2147483648 		 	
U32_MAX<u32> = 4294967295 				
U32_MIN<u32> = 0 

I64_MAX<i64> = 9223372036854775807 	
I64_MIN<i64> = -9223372036854775808 	
U64_MAX<u64> = 18446744073709551615 	
U64_MIN<u64> = 0