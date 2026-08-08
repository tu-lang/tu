# Darwin syscall asm for Tu (BSD class 0x02000000).
# Parallel tree to syscall/*.s (Linux). Selected by make install TARGET=darwin
# or copied to /usr/local/lib/coasm-darwin for tuc build --target=darwin.
#
# Threading: runtime_clone packs start args below tls_hi (tls_hi-24), uses
# libSystem pthread_* + _sched_yield; Core TLS via pthread_key (CAS once).
