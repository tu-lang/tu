// PE link backend (W1): collect COFF .o, write .link.rsp, invoke host link.exe / lld-link.
// When asm_amd64.o is present (full Windows runtime), nostd stubs are skipped.

use asmer.asm
use linker.utils
use compiler.utils as hostu
use std
use string
use fmt
use os
use runtime

fn peff_path_basename(path) {
    n = std.len(path)
    i = n - 1
    bs = hostu.char1(92.(i8))
    while i >= 0 {
        c = path[i]
        if c == '/' || c == bs {
            break
        }
        i -= 1
    }
    return string.sub(path, i + 1)
}

fn peff_stub_dir() {
    for (k, v : os.envs()) {
        arr = string.split(v, "=")
        if std.len(arr) >= 2 {
            if arr[0] == "CO_PEFF_LIB" && arr[1] != "" {
                return arr[1]
            }
            if arr[0] == "CO_WINDOWS_LIB" && arr[1] != "" {
                return arr[1]
            }
        }
    }
    pref = "/usr/local/lib/copeff"
    fp<i32> = utils.fopen(pref + "/stub_entry.s", "r")
    if fp > 0 {
        utils.fclose(fp)
        return pref
    }
    return pref
}

fn peff_linker_bin() {
    for (k, v : os.envs()) {
        arr = string.split(v, "=")
        if std.len(arr) >= 2 && arr[0] == "CO_PEFF_LINK" && arr[1] != "" {
            return arr[1]
        }
    }
    if runtime.host_os() == 2 {
        return "link"
    }
    return "lld-link"
}

fn peff_objs_have_basename(files, name) {
    for f : files {
        if peff_path_basename(f) == name {
            return true
        }
    }
    return false
}

fn peff_is_stub_obj_name(b) {
    if b == "copeff_stub_entry.o" || b == "copeff_stub_runtime.o" {
        return true
    }
    return false
}

// Write one rsp line. Dyn strings are runtime.Value(String) whose .data is
// string.Str (SDS); mirror std.File::Write — not *s / .str().
func peff_write_line(fp, s) {
    if s == null {
        return
    }
    sv<runtime.Value> = s
    if sv.type != runtime.String {
        fmt.printf("[tul/peff] rsp line not a string\n")
        return
    }
    st<string.Str> = sv.data
    n<i32> = st.len()
    if n <= 0 {
        return
    }
    n64<u64> = n
    ret<u64> = std.write(fp, sv.data, n64)
    if ret != n64 {
        fmt.printf("[tul/peff] rsp write short: got %d want %d\n", int(ret), int(n))
        os.die("peff rsp write failed")
    }
}

// Assemble stub .s with asmer peff into out_o next to outfile.
fn peff_ensure_stub_obj(src_s, out_o) i32 {
    sdir = utils.path_dirname(out_o)
    stem = peff_path_basename(out_o)
    n = std.len(stem)
    s_name = stem + ".s"
    if n > 2 && stem[n - 2] == '.' {
        base = ""
        j = 0
        while j < n - 2 {
            base += stem[j]
            j += 1
        }
        s_name = base + ".s"
    }
    s_path = utils.path_join(sdir, s_name)
    if runtime.host_os() == 2 {
        hostu.copy_file(src_s, s_path)
    } else {
        os.shell("cp '" + src_s + "' '" + s_path + "'")
    }
    asm.requested_target = "windows"
    eng<asm.Asmer> = new asm.Asmer(s_path)
    eng.execute()
    eng.close()
    fp<i32> = utils.fopen(out_o, "r")
    if fp <= 0 {
        fmt.printf("[tul/peff] expected stub object missing: %s\n", out_o)
        return 1
    }
    utils.fclose(fp)
    return 0
}

fn peff_collect_with_stubs(files, outfile) {
    all = []
    full_rt = peff_objs_have_basename(files, "asm_amd64.o")
    need_entry = !full_rt
    need_runtime_stub = !full_rt && !peff_objs_have_basename(files, "sys_std_amd64.o")
    for f : files {
        b = peff_path_basename(f)
        if peff_is_stub_obj_name(b) {
            continue
        }
        all[] = f
    }
    if !need_entry && !need_runtime_stub {
        return all
    }
    sdir = peff_stub_dir()
    out_dir = utils.path_dirname(outfile)
    if out_dir == null || out_dir == "" {
        out_dir = "."
    }
    if need_entry {
        entry_s = sdir + "/stub_entry.s"
        fp<i32> = utils.fopen(entry_s, "r")
        if fp <= 0 {
            fmt.printf("[tul/peff] missing stub_entry.s (looked in %s; set CO_PEFF_LIB)\n", sdir)
            return null
        }
        utils.fclose(fp)
        entry_o = utils.path_join(out_dir, "copeff_stub_entry.o")
        if peff_ensure_stub_obj(entry_s, entry_o) != 0 {
            return null
        }
        all[] = entry_o
    }
    if need_runtime_stub {
        runtime_s = sdir + "/stub_runtime.s"
        fp = utils.fopen(runtime_s, "r")
        if fp > 0 {
            utils.fclose(fp)
            runtime_o = utils.path_join(out_dir, "copeff_stub_runtime.o")
            if peff_ensure_stub_obj(runtime_s, runtime_o) != 0 {
                return null
            }
            all[] = runtime_o
        }
    }
    return all
}

fn peff_maybe_quote(s) {
    n = std.len(s)
    i = 0
    while i < n {
        c = s[i]
        if c == ' ' || c == '\t' {
            return "\"" + s + "\""
        }
        i += 1
    }
    return s
}

fn peff_link_objects_host(all, outfile) i32 {
    rsp = outfile + ".link.rsp"
    fp<i32> = utils.fopen(rsp, "w+")
    if fp <= 0 {
        fmt.printf("[tul/peff] open rsp %s failed\n", rsp)
        return 1
    }
    peff_write_line(fp, "/NOLOGO\n")
    peff_write_line(fp, "/SUBSYSTEM:CONSOLE\n")
    peff_write_line(fp, "/ENTRY:mainCRTStartup\n")
    peff_write_line(fp, "/NODEFAULTLIB\n")
    peff_write_line(fp, "/OUT:" + outfile + "\n")
    for f : all {
        peff_write_line(fp, f + "\n")
    }
    peff_write_line(fp, "kernel32.lib\n")
    peff_write_line(fp, "synchronization.lib\n")
    peff_write_line(fp, "ws2_32.lib\n")
    utils.fclose(fp)

    linkbin = peff_linker_bin()
    cmd = peff_maybe_quote(linkbin) + " @" + peff_maybe_quote(rsp)
    fmt.printf("[tul/peff] host-ld: %s (%d objs, rsp=%s)\n", cmd, std.len(all), rsp)
    rc = 0
    if runtime.host_os() == 2 {
        rc = hostu.host_run(cmd)
    } else {
        os.shell(cmd)
        rc = 0
    }
    if runtime.host_os() != 2 {
        os.shell("rm -f '" + rsp + "'")
    }
    if rc != 0 {
        fmt.printf("[tul/peff] %s failed (rc=%d)\n", linkbin, rc)
        return 1
    }
    fmt.printf("[tul] outfile: %s\n", outfile)
    return 0
}

// Public entry: link COFF objects into a PE exe. Returns 0 on success.
func link_objects(files, outfile) {
    if std.len(files) <= 0 {
        fmt.printf("[tul/peff] no object files\n")
        return 1
    }
    all = peff_collect_with_stubs(files, outfile)
    if all == null {
        return 1
    }
    // Do not `return` a static i32 straight through a dyn func — the driver
    // `rc = peff.link_objects(...)` then sees a null dyn value (unary-op).
    st<i32> = peff_link_objects_host(all, outfile)
    if st != 0 {
        return 1
    }
    return 0
}
