// Toolchain target selection: linux (ELF) / darwin (Mach-O) / windows (PE).

use std
use runtime

TARGET_LINUX   = 0
TARGET_DARWIN  = 1
TARGET_WINDOWS = 2

// Parse "linux" / "darwin" / "windows" (plus aliases). Unknown → -1.
func target_parse(name) {
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
func target_name(t) {
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
func target_default() {
    v = env_get("TU_TARGET")
    if v != "" {
        t = target_parse(v)
        if t >= 0 {
            return t
        }
    }
    v = env_get("CO_TARGET")
    if v != "" {
        t = target_parse(v)
        if t >= 0 {
            return t
        }
    }
    unsafe {
        return int(runtime.host_os())
    }
}

// linux, darwin and windows object/link backends are wired.
func target_ready(t) {
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
