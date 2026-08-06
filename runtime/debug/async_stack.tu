// Phase6 optional: async Future logical stack (default off / stub).
// OS-thread capture_stack remains the production backtrace path.

// Returns empty frames until async stack capture is enabled.
func async_stack(max){
	return []
}

// Whether async logical stack is enabled (always off in this stub).
fn async_stack_enabled() i32 {
	return 0
}
