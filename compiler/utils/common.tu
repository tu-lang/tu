use std
use runtime
use string

func char1(cn<i8>){
    return runtime.newobject(runtime.Char,cn)
}
func hash(data){
	return int(runtime.get_hash_key(data))
}
// func ALIGN_DOWN(x<u64>,a<u64>) {
func ALIGN_DOWN(x,a) {
	return ALIGN_UP(x - a + 1,a)
}
// func ALIGN_UP(x<u64> , a<u64>) {
func ALIGN_UP(x , a) {
	return ( x + (a - 1) ) & ( ~ (a - 1))
}
func max(l<i32>,r<i32>){
	if l > r return l
	return r
}
func pwd(){
	if std.exist("PWD",envs) {
		return envs["PWD"]
	}	
	return ""
}
func strRand() {			
	v = std.rand(1000000000)
	return fmt.sprintf("%D",v)
}
func isUpper(str)
{
	return str[0] >= 'A' && str[0] <= 'Z'
}

specs = {
	"\\n"  : 10.(i8),
	"\\\\" : 92.(i8),
	"\\t"  : 9.(i8),
	"\\\'" : 39.(i8),
	"\\\"" : 34.(i8),
	"\\b"  : 8.(i8),
	"\\r"  : 13.(i8),
	"\\f"  : 12.(i8),
	"\\0"  : 0.(i8),
	"\\r"  : 13.(i8),
	"\\v"  : 11.(i8)
}
func getescapestr(dstr<runtime.Value>){
	str<string.Str> = dstr.data
	i<i32>  = 0
	total<i32> = str.len()
	p<i8*> = str
	//NOTICE: unstable ,compiler do this
	Null<u64> = &runtime.internal_null

	lex<string.String> = string.emptyS()
	while i < total {
		c<i8> = p[i]
        if c == '\\' {
			ts = "\\"
            i += 1
			c = p[i]
            ts += char1(c)
			if ts == "\\0" {
				lex.putc(0.(i8))
			}
            else if specs[ts] == Null {
				os.dief(
                    "utils: sepc character -%s- literal should surround with single-quote ori:%s",
					ts,
					dstr
                )
            }else{
				lex.putc(specs[ts])
			}
        }else{
			lex.putc(c)
        }
        i += 1
    }
	return lex.dyn()
}