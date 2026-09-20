use runtime
use runtime.debug
use fmt
use std.map
use os

// cfg(mod_static,true)

// Static RNG for typed callers (no dyn boxing per call).
fn srand_max(max<i32>) i32 {
	seed = (seed * 1103515245) + 12345
	ret<u64> = (seed / 65536) % 32768
	if max > 0 {
		ret %= max.(u64)
	}
	return ret.(i32)
}
export func rand(v){

	seed = (seed * 1103515245) + 12345
	ret<u64> = (seed / 65536) % 32768
	if v != null {
		vv<runtime.Value> = v
		ret %= vv.data
	}
	return int(ret)
}
export func srand_i64(max){
	r<i64> = ntime()
	if max != null {
		mv<runtime.Value> = max
		r %= mv.data
	}
	return r
}
export func srand(v){

	seed = (seed * 1103515245) + 12345
	ret<u64> = (seed / 65536) % 32768
	if v != null {
		vv<runtime.Value> = v
		ret %= vv.data
	}
	// Native u64 so typed locals can assign without dyn unbox.
	return ret
}


export func empty(v){
	vv<runtime.Value> = v
	match vv.type {
		runtime.String: {
			ret<i8> = strlen(vv.data)
			if ret == 0 return true
		}
		runtime.Null: return true
		_: {
			os.dief("[warn] empty: unsupport type :%s\n",runtime.type_string(vv))
		}
	}	
	return false
}
// Static engine API (typed Value container).
fn len_value(v<runtime.Value>) i32 {
	return runtime.len(v)
}

// Dyn facade: bare Array via native type id; other containers as Value.
export func len(v){
	if v == null {
		return runtime.len(null)
	}
	tv<i32> = int(type(v))
	if tv == int(runtime.Array) {
		// export body is implicit cross-mode (RFC-110); no nested unsafe needed.
		a<Array> = v
		return int(a.used)
	}
	vv<runtime.Value> = v
	return len_value(vv)
}
export func pop(v){
	return runtime.pop(v)	
}
export func pop_head(v){
	vv<runtime.Value> = v
	if vv == null {
		fmt.println("[warn] pop_head args is null")
		return false
	}
	match vv.type {
		runtime.Array:{
			arr<Array> = vv.data
			if  arr == null os.die("[arr_pop_head] not array_type")
			if arr.used <= 0 {
				fmt.println("[warn] array_pop for empty array")
				return false
			}
			arr.used -= 1
			addr<u64*> = arr.addr
			var<u64*>  = addr
			addr += arr.size
			arr.addr = addr
			return *var
		}
		_: {
			fmt.println("[warn] pop_head args is not array")
			return false
		}
	}
}
export func head(v){
	if (ret<u64> = runtime.head(v))	!= runtime.Null {
		return ret
	}
	return null
}
export func tail(v){
	vv<runtime.Value> = v
	match vv.type {
		runtime.Array : {
			arr<Array> = vv.data
			return arr.tail()
		}
		_: fmt.println("[warn] std.back unsupport type")
	}
	return null
}
export func merge(v1, v2){
	a<runtime.Value> = v1
	b<runtime.Value> = v2
	match a.type {
		runtime.Map : fmt.println("[warn] unsupport merge(map,..)")
		runtime.Array   : {
			if b.type != runtime.Array {
				fmt.println("[warn] merge unsupport not array value")
				return false
			}
			arr<Array> = a.data
			if arr.merge(b.data) != runtime.True {
				fmt.println("[warn] array merge failed")
				return false
			}
			return true
		}
		_     : fmt.println("[warn] merge(unknow type)")
	}
	return false
}
// Static engine API (typed Value container).
fn exist_value(key, v<runtime.Value>) i32 {
	t<i32> = int(v.type)
	if t == int(runtime.Array) {
		if runtime.array_in(key, v.data) == runtime.True {
			return 1
		}
	}
	if t == int(runtime.Map) {
		has<i32> = map.map_find(v, key)
		if has != null {
			return 1
		}
	}
	fmt.printf("[warn] unsupport exist(,%s)\n", runtime.type_string(v))
	return 0
}

// Dyn facade: bare map via native type id; Value containers via exist_value.
export func exist(key, v){
	if v == null {
		return false
	}
	tv<i32> = int(type(v))
	if tv == int(runtime.Map) {
		hit = v[key]
		if hit {
			return true
		}
		return false
	}
	vv<runtime.Value> = v
	return exist_value(key, vv) != 0
}
export func is_map(m){
	mv<runtime.Value> = m
	if  mv.type == runtime.Map {
		return true
	}
	return false
}
export func is_array(arr){
	av<runtime.Value> = arr
	if  av.type == runtime.Array {
		return true
	}
	return false
}

export func ntime(){
	ts<TimeSpec> = new TimeSpec
	clock_gettime(CLOCK_REALTIME, ts)
	return ts.sec * 1000000000 + ts.nsec
}

// Static-only formatted die; format must be a C string.
fn dief(str<i8*>, args...){
	fmt.vfprintf(std.STDOUT,str,args)
    fmt.vfprintf(std.STDOUT,*"\ndebug backtrace:\n")
	unsafe {
		infos = debug.stack(10.(i8))
		i = 1
		for v : infos {
			fmt.printf("%d: %s\n",i,v)
			i += 1
		}
	}
	std.die(-1.(i8))
}
