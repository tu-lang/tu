// Toolchain target selection: linux (ELF) / darwin (Mach-O) / windows (PE).

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
// Use env_get (os.envs scan) — do not rely on package init() filling `envs`
// before the first call (cross-package init order is not guaranteed).
fn target_default() i32 {
    v = env_get("TU_TARGET")
    if v != "" {
        t<i32> = target_parse(v)
        if t >= 0 {
            return t
        }
    }
    v = env_get("CO_TARGET")
    if v != "" {
        t<i32> = target_parse(v)
        if t >= 0 {
            return t
        }
    }
    return runtime.host_os()
}

// linux, darwin and windows object/link backends are wired.
fn target_ready(t<i32>) i32 {
    if t == TARGET_LINUX {
        return 1
    }
    if t == TARGET_DARWIN {
        return 1
    }
    if t == TARGET_WINDOWS {
        return 1
    }
    return 0
}
