mem IoSourceState {
	i64 pad
}

const IoSourceState::new() IoSourceState {
	return new IoSourceState { pad: 0 }
}

IoSourceState::do_io(callable, io_obj) {
	return callable(io_obj)
}
