use io
use netio

api Source {
	fn register(registry<netio.Registry>, token<netio.Token>, interests<netio.Interest>) i32 {
		return io.Uncategorized
	}
	fn reregister(registry<netio.Registry>, token<netio.Token>, interests<netio.Interest>) i32 {
		return io.Uncategorized
	}
	fn deregister(registry<netio.Registry>) i32 {
		return io.Uncategorized
	}
}

fn source_register_default() i32 {
	return io.Uncategorized
}
