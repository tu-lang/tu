// os.shell runs /bin/sh -c and returns the shell's exit status as a dynamic int.
use os
use fmt

// Normal exit codes: success, explicit non-zero, last command wins.
func test_exit_codes(){
	if os.shell("echo yes") != 0 os.die("shell echo should return 0")
	if os.shell("true") != 0 os.die("shell true should return 0")
	if os.shell("false") != 1 os.die("shell false should return 1")
	rc = os.shell("exit 3")
	if rc != 3 os.dief("shell exit 3 returned %d", rc)
	if os.shell("exit 255") != 255 os.die("shell exit 255 should return 255")
	if os.shell("true; exit 7") != 7 os.die("shell last exit should win")
	fmt.println("test_exit_codes ok")
}

// Killed by a signal: 128 + signal number (shell convention).
func test_signal_exit(){
	rc = os.shell("kill -9 $$")
	if rc != 137 os.dief("shell killed by SIGKILL returned %d", rc)
	rc = os.shell("kill -15 $$")
	if rc != 143 os.dief("shell killed by SIGTERM returned %d", rc)
	fmt.println("test_signal_exit ok")
}

// The return value composes with ordinary dynamic expressions.
func test_expr_contexts(){
	total = 0
	total += os.shell("exit 2")
	total += os.shell("exit 5")
	if total != 7 os.dief("accumulated exit codes = %d", total)
	ok = os.shell("test -d /") == 0
	if !ok os.die("shell test -d / should succeed")
	codes = [os.shell("exit 1"), os.shell("exit 0")]
	if codes[0] != 1 || codes[1] != 0 os.die("exit codes in array literal")
	fmt.println("test_expr_contexts ok")
}

// Each call reaps only its own child, so back-to-back calls stay ordered.
func test_sequential(){
	i = 0
	while i < 20 {
		rc = os.shell(fmt.sprintf("exit %d", i % 4))
		if rc != i % 4 os.dief("iteration %d returned %d", i, rc)
		i += 1
	}
	fmt.println("test_sequential ok")
}

// `tu run` exits with the program's status and removes its private
// TMPDIR/tu-build-<stem>-* workdir afterwards.
func test_tu_run_status(){
	rc = os.shell("tu run tu_run/tu_run_exit3.tu > /dev/null 2>&1")
	if rc != 3 os.dief("tu run exit3 returned %d", rc)
	rc = os.shell("tu run tu_run/tu_run_exit0.tu > /dev/null 2>&1")
	if rc != 0 os.dief("tu run exit0 returned %d", rc)
	left = os.shell("ls -d \"${TMPDIR:-/tmp}\"/tu-build-tu_run_exit* > /dev/null 2>&1")
	if left == 0 os.die("tu run left its tu-build workdir behind")
	fmt.println("test_tu_run_status ok")
}

func main(){
	test_exit_codes()
	test_signal_exit()
	test_expr_contexts()
	test_sequential()
	test_tu_run_status()
}
