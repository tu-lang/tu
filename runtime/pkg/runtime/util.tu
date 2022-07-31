
use fmt
use os
use string

func hash_key(data<u8*>,len<u64>){
    i<i64>   = 0
    key<i64> = 0
    for(i<u64> = 0 ; i < len ; i += 1){
        temp_key<u32> = key
        temp_data<u8*> = data + i
        key = temp_key * 31 + *temp_data
    }
    return key
}

func get_hash_key(key<Value>){
    if  key.type == Bool || key.type == Int {
		return key.data
	}
	if  key.type == String {
		return hash_key(key.data,string.stringlen(key.data))
	}
    fmt.println("[hash_key] unsupport type:" + type_string(key))
    os.exit(-1)
}
func assert(ret<i8>,str){
    if ret return True
    os.die(str)
}