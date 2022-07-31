
use os
use std
use string
use fmt

ori_envp<u64*>

func args_init(argc<u64> argv<u64*>,envp<u64*>){
	c = int(argc)
	c -= 1
	ori_envp = envp # save env
	//save args
	arr = []
	while argc > 0 {
		if *argv == null {
			break
		}
		str<Value> = new Value
		str.type = String
		str.data = string.stringnew(*argv)
		arr_pushone(arr,str)
		argv += PointerSize
		argc -= 1
	}
	os.argc = c 
	os.argv = arr
	//save env
	envs = []
	while *envp != null {
		str1<Value> = new Value
		str1.type = String
		str1.data = string.stringnew(*envp)
		arr_pushone(envs,str1)
		envp += PointerSize
	}
	os.envs = envs

}