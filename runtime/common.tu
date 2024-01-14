
use fmt
use os
use string

fn hash_key(data<u8*>,len<u64>){
    i<i64>   = 0
    key<i64> = 0
    for(i<u64> = 0 ; i < len ; i += 1){
        temp_key<u32> = key
        temp_data<u8*> = data + i
        key = temp_key * 31 + *temp_data
    }
    return key
}

fn get_hash_key(key<Value>){
    if  key.type == Bool || key.type == Int {
		return key.data
	}
    str<string.Str> = key.data
	if  key.type == String {
        return str.hash64()
		// return hash_key(str,str.len())
	}
    os.dief("[hash_key] unsupport type:%s" , type_string(key))
}
fn assert(ret<i8>,str){
    if ret return True
    os.die(str)
}

//implement by asm
fn callerpc()
fn nextpc(){
	return callerpc()
}