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