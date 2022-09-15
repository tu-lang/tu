use std
use runtime

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
func max(l,r){
	if l > r return l
	return r
}
func pwd(){
	if std.exist(envs,"PWD") {
		return envs["PWD"]
	}	
	return ""
}
func strRand() {			
	v = std.rand(1000000000)
	return fmt.sprintf("%D",v)
}