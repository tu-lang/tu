// Compile-time negative: path must not contain '..'.
// Expect: tuc fails (see neg_compile.sh).
fn main() {
	s = embed("../secret.txt")
}
