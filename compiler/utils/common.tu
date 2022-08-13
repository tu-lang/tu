use std

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