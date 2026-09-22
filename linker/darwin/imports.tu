// libSystem allowlist, import stubs (jmpq *GOT(%rip)), and DYLD bind opcodes.
// Must stay in sync with the reference tul allowlist; add names there first.

use std

nm_pthread_create = "_pthread_create"
nm_pthread_attr_init = "_pthread_attr_init"
nm_pthread_attr_destroy = "_pthread_attr_destroy"
nm_pthread_attr_setdetachstate = "_pthread_attr_setdetachstate"
nm_pthread_attr_setstack = "_pthread_attr_setstack"
nm_pthread_key_create = "_pthread_key_create"
nm_pthread_getspecific = "_pthread_getspecific"
nm_pthread_setspecific = "_pthread_setspecific"
nm_pthread_self = "_pthread_self"
nm_pthread_detach = "_pthread_detach"
nm_pthread_exit = "_pthread_exit"
nm_sched_yield = "_sched_yield"
nm_nanosleep = "_nanosleep"
nm_execve = "_execve"
nm_socket = "_socket"
nm_bind = "_bind"
nm_connect = "_connect"
nm_accept = "_accept"
nm_sendto = "_sendto"
nm_recvfrom = "_recvfrom"
nm_pipe = "_pipe"
nm_dup2 = "_dup2"
nm_sigaction = "_sigaction"
nm_sigprocmask = "_sigprocmask"
nm_error = "___error"
nm_getsockopt = "_getsockopt"
nm_setsockopt = "_setsockopt"
nm_read = "_read"
nm_write = "_write"
nm_close = "_close"
nm_openat = "_openat"
nm_mkdir = "_mkdir"
nm_rmdir = "_rmdir"
nm_unlink = "_unlink"
nm_fcntl = "_fcntl"
nm_open = "_open"
nm_stat64 = "_stat64"

fn libsystem_allows(tab<NameTab>, off<i32>) i32 {
    if name_eq_cstr(tab, off, *nm_pthread_create) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_pthread_attr_init) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_pthread_attr_destroy) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_pthread_attr_setdetachstate) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_pthread_attr_setstack) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_pthread_key_create) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_pthread_getspecific) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_pthread_setspecific) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_pthread_self) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_pthread_detach) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_pthread_exit) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_sched_yield) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_nanosleep) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_execve) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_socket) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_bind) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_connect) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_accept) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_sendto) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_recvfrom) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_pipe) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_dup2) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_sigaction) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_sigprocmask) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_error) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_getsockopt) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_setsockopt) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_read) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_write) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_close) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_openat) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_mkdir) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_rmdir) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_unlink) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_fcntl) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_open) != 0 { return 1 }
    if name_eq_cstr(tab, off, *nm_stat64) != 0 { return 1 }
    return 0
}

fn uleb128_push(buf<ByteBuf>, v<u64>) {
    loop {
        b<u64> = v & 0x7f
        v = v >> 7
        if v != 0 {
            b = b | 0x80
        }
        bi<i32> = b
        buf.push_u8(bi)
        if v == 0 {
            break
        }
    }
}

mem ImportSlot {
    i32 name_off
    u32 stub_off
    u32 got_off
}

// Append jmpq *disp32(%rip) stub; disp filled later. Returns text offset.
fn emit_import_stub(text<ByteBuf>, got_off_in_data<u32>) u32 {
    text.align_to(16, 0x90)
    stub_off<u32> = i32_u32(text.len)
    text.push_u8(0xff)
    text.push_u8(0x25)
    text.push_u32(got_off_in_data)
    return stub_off
}

fn patch_stub(text<ByteBuf>, stub_off<u32>, stub_va<u64>, got_va<u64>) {
    stub6<u64> = stub_va + 6
    disp<i64> = u64_i64(got_va) - u64_i64(stub6)
    text.set_u32_at(u32_i32(stub_off) + 2, i64_u32(disp))
}

fn build_bind(slots<std.Array>, names<NameTab>) ByteBuf {
    out<ByteBuf> = ByteBuf::create()
    seg_data<u8> = 2
    lib_ord<u8> = 1
    i<i32> = 0
    while i < slots.used {
        sl<ImportSlot> = slots.addr[i]
        op0<u8> = BIND_OPCODE_SET_DYLIB_ORDINAL_IMM | (lib_ord & 0xf)
        out.push_u8(u8_i32(op0))
        out.push_u8(u8_i32(BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM))
        nlen<i32> = names.len_at(sl.name_off)
        out.append(names.ptr_at(sl.name_off), nlen)
        out.push_u8(0)
        op1<u8> = BIND_OPCODE_SET_TYPE_IMM | BIND_TYPE_POINTER
        out.push_u8(u8_i32(op1))
        op2<u8> = BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB | (seg_data & 0xf)
        out.push_u8(u8_i32(op2))
        goff<u64> = u32_u64(sl.got_off)
        uleb128_push(out, goff)
        out.push_u8(u8_i32(BIND_OPCODE_DO_BIND))
        i += 1
    }
    out.push_u8(u8_i32(BIND_OPCODE_DONE))
    return out
}
