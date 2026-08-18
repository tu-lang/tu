// Package-level i32 load/store (compiler emits .long + RIP-relative).
// RFC-107 D3.2 runtime coverage alongside asmer/peff/cases/data_rip.s.
use os
use fmt

// RFC-107 D3.2: package-level i32 (compiler .long) load/store via RIP-relative.
g_before<i32> = 286331153
g_after<i32> = 305419896

fn main() {
	if g_before != 286331153 os.die("g_before load")
	if g_after != 305419896 os.die("g_after load")
	g_after = 1
	if g_after != 1 os.die("g_after store")
	g_before = g_before + 1
	if g_before != 286331154 os.die("g_before store")
	fmt.println("data_rip_long success")
}
