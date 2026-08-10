// Toolchain target selection: linux (ELF) / darwin (Mach-O) / windows (reserved).

use std
use runtime

TARGET_LINUX<i32>   = 0
TARGET_DARWIN<i32>  = 1
TARGET_WINDOWS<i32> = 2

// Parse "linux" / "darwin" / "windows" (plus aliases). Unknown → -1.
fn target_parse(name) i32 {
    if name == "linux" {
        return TARGET_LINUX
    }
    if name == "darwin" || name == "macos" || name == "osx" {
        return TARGET_DARWIN
    }
    if name == "windows" || name == "win64" || name == "pe" {
        return TARGET_WINDOWS
    }
    return -1
}

// Stable short name for -v and logs.
fn target_name(t<i32>) {
    if t == TARGET_DARWIN {
        return "darwin"
    }
    if t == TARGET_WINDOWS {
        return "windows"
    }
    return "linux"
}

// TU_TARGET / CO_TARGET env, then runtime.host_os().
fn target_default() i32 {
    if std.exist("TU_TARGET", envs) {
        v = envs["TU_TARGET"]
        t<i32> = target_parse(v)
        if t >= 0 {
            return t
        }
    }
    if std.exist("CO_TARGET", envs) {
        v = envs["CO_TARGET"]
        t<i32> = target_parse(v)
        if t >= 0 {
            return t
        }
    }
    return runtime.host_os()
}

// linux and darwin are ready; windows is reserved.
fn target_ready(t<i32>) i32 {
    if t == TARGET_LINUX {
        return 1
    }
    if t == TARGET_DARWIN {
        return 1
    }
    return 0
}
