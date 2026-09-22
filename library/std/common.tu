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

// Dyn facade: detect Array via Value.type (not type(v)==runtime.Array —
// dyn Int vs native enum compare is unreliable; int(type(v)) re-boxes wrong).
export func len(v){
	if v == null {
		return runtime.len(null)
	}
	vv<runtime.Value> = v
	if vv.type == runtime.Array {
		a<Array> = vv.data
		return int(a.used)
	}
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
// Map hits may be unboxed native ints (map-literal constant values) or
// Value*; missing keys return 0/Null. Use u64 so heap pointers are not
// truncated by i32.
fn exist_value(key, v<runtime.Value>) i32 {
	if v.type == runtime.Array {
		if runtime.array_in(key, v.data) == runtime.True {
			return 1
		}
		return 0
	}
	if v.type == runtime.Map {
		has<u64> = map.map_find(v, key)
		if has != 0.(u64) {
			return 1
		}
		return 0
	}
	fmt.printf("[warn] unsupport exist(,%s)\n", runtime.type_string(v))
	return 0
}

// Static i32 presence check for mem/static callers.
// Dyn export exist() returns bool Values that static `if` / `!` mis-handle
// (isTrue/binary_operator on wrong bits). Callers in static context must use
// contains() and compare to 0.
fn contains(key, v<runtime.Value>) i32 {
	if v == null {
		return 0
	}
	return exist_value(key, v)
}

// Dyn facade: use Value.type for Map/Array; avoid v[key]+isTrue (unboxed
// map-literal values are not Value* and panic in isTrue/value_tag_ok).
export func exist(key, v){
	if v == null {
		return false
	}
	vv<runtime.Value> = v
	// Return real dyn bools — do not `return exist_value(...) != 0` (native i32).
	if exist_value(key, vv) != 0 {
		return true
	}
	return false
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
