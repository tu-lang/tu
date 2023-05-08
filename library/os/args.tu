use runtime

# start at userspace init process
func argc(){
	return runtime.ori_argc
} 
func argv(){
	return runtime.ori_argv
}
func envs(){
	return runtime.ori_envs
}