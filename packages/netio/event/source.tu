use io
use netio

// Mother mio::event::Source. Method names avoid `.register` / `.deregister`
// type-assert traps (same class as register_sfd / park_iod).
api Source {
	// Mother: register.
	fn enroll(registry<netio.Registry>, token<netio.Token>, interests<netio.Interest>) i32 {
		return io.Uncategorized
	}
	// Mother: reregister.
	fn reenroll(registry<netio.Registry>, token<netio.Token>, interests<netio.Interest>) i32 {
		return io.Uncategorized
	}
	// Mother: deregister.
	fn detach(registry<netio.Registry>) i32 {
		return io.Uncategorized
	}
}

fn source_register_default() i32 {
	return io.Uncategorized
}
