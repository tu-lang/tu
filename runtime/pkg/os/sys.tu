//implement by asm
func _getpid()
func _fork()
func _wait4()

//user space
func getpid() {
	return int(_getpid())
}
func fork(){
	return int(_fork())
}
