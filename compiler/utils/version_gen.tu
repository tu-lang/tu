// Auto-generated from tu/VERSION + scripts/version_manifest.txt — do not edit.
// RFC-109 toolchain + component versions (string constants only; no package imports).

use fmt

TU_TOOL_VERSION = "1.2.49"

func tool_version() {
	return TU_TOOL_VERSION
}

// Full aligned report; target_os is short name: linux | darwin | windows.
func print_version_report(target_os) {
	fmt.printf("tu-lang version: %s\n", TU_TOOL_VERSION)
	fmt.printf("Target         : x86_64 %s\n", target_os)
	fmt.printf("\n")
	fmt.printf("Toolchain\n")
	fmt.printf("  compiler    : %s\n", "1.2.28")
	fmt.printf("  asmer       : %s\n", "1.2.18")
	fmt.printf("  linker      : %s\n", "1.2.11")
	fmt.printf("Runtime       : %s\n", "1.2.8")
	fmt.printf("Syscall       : %s\n", "1.2.3")
	fmt.printf("Platform      : %s\n", "1.2.3")
	fmt.printf("Library       : %s\n", "1.2.16")
	fmt.printf("\n")
	fmt.printf("Packages\n")
	fmt.printf("  asyncio     : %s\n", "1.2.7")
	fmt.printf("  netio       : %s\n", "1.2.6")
}
