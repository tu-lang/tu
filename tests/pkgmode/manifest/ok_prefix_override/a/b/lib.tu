// Dyn subtree (longest prefix "a/b" beats "a"): dyn symbols are natively
// visible, so no export facade here (export is a static-package-only syntax).

func two() {
    return 2
}
