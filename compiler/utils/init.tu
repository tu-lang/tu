use os
use std

envs # map{string:string,}

func init(){
	m = {}
	for (k,v : os.envs() ){
		arr = string.split(v,"=")
		m[arr[0]] = arr[1]
	}
	envs = m
}

