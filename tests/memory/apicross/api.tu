// Lightweight cross-package API for memory api tests.
// Lives under tests/memory/apicross so `use apicross` does not pull library/sys
// (which transitively loads sys/net.tu and library/net).

api CrossApi {
	fn get_fd() (i32)
}
