// Win32 import allowlist, jmp stubs (jmpq *IAT(%rip)), and PE import tables.
// Names stay in sync with syscall/windows/*.s; add both sides together.

use std

DLL_KERNEL32<i32> = 0
DLL_SHELL32<i32>  = 1
DLL_WS2_32<i32>   = 2
DLL_SYNCH<i32>    = 3

nm_k32 = "kernel32.dll"
nm_shell = "shell32.dll"
nm_ws2 = "ws2_32.dll"
nm_synch = "api-ms-win-core-synch-l1-2-0.dll"

mem ImportSlot {
    i32 name_off
    i32 dll_id
    u32 stub_off
    u32 iat_off
}

fn emit_import_stub(text<ByteBuf>) u32 {
    text.align_to(16, 0x90)
    stub_off<u32> = i32_u32(text.len)
    text.push_u8(0xff)
    text.push_u8(0x25)
    z<u32> = 0
    text.push_u32(z)
    return stub_off
}

fn patch_stub(text<ByteBuf>, stub_off<u32>, stub_va<u64>, iat_va<u64>) {
    stub6<u64> = stub_va + 6.(u64)
    disp<i64> = u64_i64(iat_va) - u64_i64(stub6)
    text.set_u32_at(u32_i32(stub_off) + 2, i64_u32(disp))
}

fn dll_name_cstr(id<i32>) i8* {
    if id == DLL_SHELL32 {
        return *nm_shell
    }
    if id == DLL_WS2_32 {
        return *nm_ws2
    }
    if id == DLL_SYNCH {
        return *nm_synch
    }
    return *nm_k32
}

fn win_dll_id(tab<NameTab>, off<i32>) i32 {
    if name_eq_cstr(tab, off, *"WSAStartup") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"WSAGetLastError") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"WSAPoll") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"accept") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"recv") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"socket") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"ioctlsocket") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"closesocket") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"bind") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"connect") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"listen") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"getpeername") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"send") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"sendto") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"recvfrom") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"shutdown") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"setsockopt") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"getsockopt") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"getsockname") != 0 { return DLL_WS2_32 }
    if name_eq_cstr(tab, off, *"WaitOnAddress") != 0 { return DLL_SYNCH }
    if name_eq_cstr(tab, off, *"WakeByAddressAll") != 0 { return DLL_SYNCH }
    if name_eq_cstr(tab, off, *"CommandLineToArgvW") != 0 { return DLL_SHELL32 }
    if name_eq_cstr(tab, off, *"ExitProcess") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"GetLastError") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"GetStdHandle") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"CreateFileA") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"ReadFile") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"WriteFile") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"CloseHandle") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"SetFilePointerEx") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"CreateDirectoryA") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"RemoveDirectoryA") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"DeleteFileA") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"GetFileAttributesA") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"VirtualAlloc") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"VirtualFree") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"Sleep") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"TlsAlloc") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"TlsGetValue") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"TlsSetValue") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"CreateThread") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"ExitThread") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"GetCurrentProcessId") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"GetCurrentThreadId") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"CreateProcessA") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"WaitForSingleObject") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"GetExitCodeProcess") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"FindFirstFileA") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"FindNextFileA") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"FindClose") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"GetCurrentDirectoryA") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"GetModuleFileNameA") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"SetConsoleOutputCP") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"SetConsoleCP") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"GetCommandLineW") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"LocalFree") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"WideCharToMultiByte") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"GetEnvironmentStringsA") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"GetSystemTimeAsFileTime") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"CreatePipe") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"SetHandleInformation") != 0 { return DLL_KERNEL32 }
    if name_eq_cstr(tab, off, *"SetNamedPipeHandleState") != 0 { return DLL_KERNEL32 }
    return -1
}

fn count_dll_slots(slots<std.Array>, dll_id<i32>) i32 {
    n<i32> = 0
    i<i32> = 0
    while i < slots.len() {
        sl<ImportSlot> = slots.addr[i]
        if sl.dll_id == dll_id {
            n += 1
        }
        i += 1
    }
    return n
}

// Build .rdata import directory. Fills slot.iat_off (offset from rdata start).
fn build_imports(slots<std.Array>, names<NameTab>, rdata_rva<u32>) ByteBuf {
    rdata<ByteBuf> = ByteBuf::create()
    nd0<i32> = count_dll_slots(slots, DLL_KERNEL32)
    nd1<i32> = count_dll_slots(slots, DLL_SHELL32)
    nd2<i32> = count_dll_slots(slots, DLL_WS2_32)
    nd3<i32> = count_dll_slots(slots, DLL_SYNCH)
    ndll<i32> = 0
    if nd0 > 0 {
        ndll += 1
    }
    if nd1 > 0 {
        ndll += 1
    }
    if nd2 > 0 {
        ndll += 1
    }
    if nd3 > 0 {
        ndll += 1
    }
    if ndll == 0 {
        return rdata
    }

    desc_bytes<i32> = (ndll + 1) * 20
    off<i32> = desc_bytes

    ilt0<i32> = 0
    ilt1<i32> = 0
    ilt2<i32> = 0
    ilt3<i32> = 0
    iat0<i32> = 0
    iat1<i32> = 0
    iat2<i32> = 0
    iat3<i32> = 0
    if nd0 > 0 {
        ilt0 = off
        off = off + (nd0 + 1) * 8
        iat0 = off
        off = off + (nd0 + 1) * 8
    }
    if nd1 > 0 {
        ilt1 = off
        off = off + (nd1 + 1) * 8
        iat1 = off
        off = off + (nd1 + 1) * 8
    }
    if nd2 > 0 {
        ilt2 = off
        off = off + (nd2 + 1) * 8
        iat2 = off
        off = off + (nd2 + 1) * 8
    }
    if nd3 > 0 {
        ilt3 = off
        off = off + (nd3 + 1) * 8
        iat3 = off
        off = off + (nd3 + 1) * 8
    }

    r<i32> = off % 2
    if r != 0 {
        off += 1
    }

    nslot<i32> = slots.len()
    hints<ByteBuf> = ByteBuf::zeros(ht_bytes(nslot))
    i<i32> = 0
    while i < nslot {
        sl<ImportSlot> = slots.addr[i]
        hn<i32> = off
        hints.set_i32(i, hn)
        nlen<i32> = names.len_at(sl.name_off)
        off = off + 2 + nlen + 1
        r2<i32> = off % 2
        if r2 != 0 {
            off += 1
        }
        i += 1
    }

    name0<i32> = 0
    name1<i32> = 0
    name2<i32> = 0
    name3<i32> = 0
    if nd0 > 0 {
        name0 = off
        off = off + cstr_len(*nm_k32) + 1
    }
    if nd1 > 0 {
        name1 = off
        off = off + cstr_len(*nm_shell) + 1
    }
    if nd2 > 0 {
        name2 = off
        off = off + cstr_len(*nm_ws2) + 1
    }
    if nd3 > 0 {
        name3 = off
        off = off + cstr_len(*nm_synch) + 1
    }

    rdata.reserve(off)
    rdata.len = off
    n64<u64> = off
    std.memset(rdata.bits(), 0, n64)

    c0<i32> = 0
    c1<i32> = 0
    c2<i32> = 0
    c3<i32> = 0
    i = 0
    while i < slots.len() {
        sl<ImportSlot> = slots.addr[i]
        hn<i32> = hints.i32_at(i)
        hn_rva<u32> = rdata_rva + i32_u32(hn)
        nlen<i32> = names.len_at(sl.name_off)
        hp<i8*> = rdata.ptr() + hn
        hp[0] = 0.(i8)
        hp[1] = 0.(i8)
        std.memcpy(hp + 2, names.ptr_at(sl.name_off), nlen.(u64))
        iat<i32> = 0
        ilt<i32> = 0
        idx<i32> = 0
        if sl.dll_id == DLL_KERNEL32 {
            idx = c0
            iat = iat0 + idx * 8
            ilt = ilt0 + idx * 8
            c0 += 1
        } else if sl.dll_id == DLL_SHELL32 {
            idx = c1
            iat = iat1 + idx * 8
            ilt = ilt1 + idx * 8
            c1 += 1
        } else if sl.dll_id == DLL_WS2_32 {
            idx = c2
            iat = iat2 + idx * 8
            ilt = ilt2 + idx * 8
            c2 += 1
        } else {
            idx = c3
            iat = iat3 + idx * 8
            ilt = ilt3 + idx * 8
            c3 += 1
        }
        sl.iat_off = i32_u32(iat)
        rdata.set_u64_at(iat, u32_u64(hn_rva))
        rdata.set_u64_at(ilt, u32_u64(hn_rva))
        i += 1
    }

    if nd0 > 0 {
        p<i8*> = rdata.ptr() + name0
        n<i32> = cstr_len(*nm_k32)
        std.memcpy(p, *nm_k32, n.(u64))
    }
    if nd1 > 0 {
        p<i8*> = rdata.ptr() + name1
        n<i32> = cstr_len(*nm_shell)
        std.memcpy(p, *nm_shell, n.(u64))
    }
    if nd2 > 0 {
        p<i8*> = rdata.ptr() + name2
        n<i32> = cstr_len(*nm_ws2)
        std.memcpy(p, *nm_ws2, n.(u64))
    }
    if nd3 > 0 {
        p<i8*> = rdata.ptr() + name3
        n<i32> = cstr_len(*nm_synch)
        std.memcpy(p, *nm_synch, n.(u64))
    }

    di<i32> = 0
    if nd0 > 0 {
        pe_write_import_desc(rdata, di, ilt0, iat0, name0, rdata_rva)
        di += 1
    }
    if nd1 > 0 {
        pe_write_import_desc(rdata, di, ilt1, iat1, name1, rdata_rva)
        di += 1
    }
    if nd2 > 0 {
        pe_write_import_desc(rdata, di, ilt2, iat2, name2, rdata_rva)
        di += 1
    }
    if nd3 > 0 {
        pe_write_import_desc(rdata, di, ilt3, iat3, name3, rdata_rva)
        di += 1
    }
    return rdata
}

fn pe_write_import_desc(rdata<ByteBuf>, di<i32>, ilt<i32>, iat<i32>, nm<i32>, rva<u32>) {
    o<i32> = di * 20
    rdata.set_u32_at(o, rva + i32_u32(ilt))
    rdata.set_u32_at(o + 4, 0.(u32))
    rdata.set_u32_at(o + 8, 0.(u32))
    rdata.set_u32_at(o + 12, rva + i32_u32(nm))
    rdata.set_u32_at(o + 16, rva + i32_u32(iat))
}
