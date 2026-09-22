// PE link backend: collect COFF .o, self-hosted PE writer (no host link.exe).
// When asm_amd64.o is present (full Windows runtime), nostd stubs are skipped.

use asmer.asm
use linker.utils
use std
use string
use fmt
use os
use runtime

unsafe fn peff_path_basename(path) {
    n = std.len(path)
    i = n - 1
    bs = utils.char1(92.(i8))
    while i >= 0 {
        c = path[i]
        if c == '/' || c == bs {
            break
        }
        i -= 1
    }
    return string.sub(path, i + 1)
}

unsafe fn peff_stub_dir() {
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
    d = utils.stub_dir_for(2)
    if d != null && d != "" {
        probe = utils.path_join(d, "stub_entry.s")
        fp<i32> = utils.fopen(probe, "r")
        if fp > 0 {
            utils.fclose(fp)
            return d
        }
    }
    pref = utils.lib_root() + "/copeff"
    fp<i32> = utils.fopen(pref + "/stub_entry.s", "r")
    if fp > 0 {
        utils.fclose(fp)
        return pref
    }
    return pref
}

unsafe fn peff_objs_have_basename(files, name) {
    for f : files {
        if peff_path_basename(f) == name {
            return true
        }
    }
    return false
}

// Assemble stub .s into out_o. Reuses existing .o; otherwise shells tua
// (embedded Asmer::execute for TARGET_WINDOWS can strlen-panic inside tul/tu).
unsafe fn peff_ensure_stub_obj(src_s, out_o) i32 {
    fp0<i32> = utils.fopen(out_o, "r")
    if fp0 > 0 {
        utils.fclose(fp0)
        return 0
    }
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
        utils.copy_file(src_s, s_path)
    } else {
        utils.run_shell("cp '" + src_s + "' '" + s_path + "'")
    }
    // Prefer host tua: same COFF writer as `tu build` asmer phase.
    utils.run_shell("tua --target=windows -c '" + s_path + "'")
    fp<i32> = utils.fopen(out_o, "r")
    if fp <= 0 {
        // Fallback: in-process asmer.
        asm.requested_target = "windows"
        eng<asm.Asmer> = new asm.Asmer(s_path)
        eng.execute()
        eng.close()
        fp = utils.fopen(out_o, "r")
        if fp <= 0 {
            fmt.printf("[tu/peff] expected stub object missing: %s (tua / asmer failed)\n", out_o)
            return 1
        }
    }
    utils.fclose(fp)
    return 0
}

unsafe fn peff_collect_with_stubs(files, outfile) {
    all = []
    full_rt = peff_objs_have_basename(files, "asm_amd64.o")
    have_entry = peff_objs_have_basename(files, "copeff_stub_entry.o")
    have_runtime = peff_objs_have_basename(files, "copeff_stub_runtime.o")
    need_entry = !full_rt && !have_entry
    need_runtime_stub = !full_rt && !peff_objs_have_basename(files, "sys_std_amd64.o") && !have_runtime
    for f : files {
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
            fmt.printf("[tu/peff] missing stub_entry.s (looked in %s; set CO_PEFF_LIB)\n", sdir)
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
        fp2<i32> = utils.fopen(runtime_s, "r")
        if fp2 > 0 {
            utils.fclose(fp2)
            runtime_o = utils.path_join(out_dir, "copeff_stub_runtime.o")
            if peff_ensure_stub_obj(runtime_s, runtime_o) != 0 {
                return null
            }
            all[] = runtime_o
        }
    }
    return all
}

unsafe fn link_objects(files, outfile) i32 {
    if std.len(files) <= 0 {
        fmt.printf("[tu/peff] no object files\n")
        return 1
    }

    all = peff_collect_with_stubs(files, outfile)
    if all == null {
        return 1
    }

    img<PeImage> = PeImage::create()
    for f : all {
        if img.add_object(f) != 0 {
            return 1
        }
    }
    rc<i32> = img.link(outfile)
    if rc != 0 {
        return 1
    }
    return 0
}
