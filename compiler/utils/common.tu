use std

func ALIGN_DOWN(x<u64>,a<u64>) {
	return ALIGN_UP(x-a+1,a)
}
func ALIGN_UP(x<u64> , a<u64>) {
	//((x) + (a - 1)) & ~(a - 1)
	t<u64> = x + (a - 1) 
	o<u64> = a - 1
	o ~= o
	return t & o
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
string strRand() {			
	v = std.rand(1000000000)
	return fmt.sprintf("%D",v)
}