use io
use netio

// Event source registered with the Poll reactor. Method names avoid `.register` / `.deregister`
// type-assert traps (same class as register_sfd / park_iod).
api Source {
	fn enroll(registry<netio.Registry>, token<netio.Token>, interests<netio.Interest>) i32 {
		return io.Uncategorized
	}
	fn reenroll(registry<netio.Registry>, token<netio.Token>, interests<netio.Interest>) i32 {
		return io.Uncategorized
	}
	fn detach(registry<netio.Registry>) i32 {
		return io.Uncategorized
	}
}

fn source_register_default() i32 {
	return io.Uncategorized
}
