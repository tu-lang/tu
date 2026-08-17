# Minimal PE stubs so -nostd Tu objects can link without Linux colib.
# Not a real runtime. Only enough for empty main smoke.

.data
.align 3
.globl runtime_internal_null
runtime_internal_null:
    .quad 0
    .quad 0
    .quad 0
    .quad 0

.globl gc.os.ms
gc.os.ms:
    .quad 0

.globl gc.runtime.ms
gc.runtime.ms:
    .quad 0

.globl gc.runtime_debug.ms
gc.runtime_debug.ms:
    .quad 0

.globl gc.std.ms
gc.std.ms:
    .quad 0

.globl gc.std_map.ms
gc.std_map.ms:
    .quad 0

.globl gc.string.ms
gc.string.ms:
    .quad 0

.globl gc.fmt.ms
gc.fmt.ms:
    .quad 0

.globl gc.time.ms
gc.time.ms:
    .quad 0

.globl gc.sys.ms
gc.sys.ms:
    .quad 0

.globl gc.io.ms
gc.io.ms:
    .quad 0

.globl gc.net.ms
gc.net.ms:
    .quad 0

.globl gc.exception.ms
gc.exception.ms:
    .quad 0
