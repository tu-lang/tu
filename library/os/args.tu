use runtime

# start at userspace init process
export func argc(){
	return runtime.ori_argc
} 
export func argv(){
	return runtime.ori_argv
}
export func envs(){
	return runtime.ori_envs
}