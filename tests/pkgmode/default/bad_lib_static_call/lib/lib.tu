// Undeclared (dyn) package: runtime.host_os is a non-export static fn and needs unsafe.

use runtime

func probe() {
    return runtime.host_os()
}
