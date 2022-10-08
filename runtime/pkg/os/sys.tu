//implement by asm
func _getpid()
func _fork()

//user space
func getpid() {
	return int(_getpid())
}
func fork(){
	return int(_fork())
}
