use io
use netio
use os

api Source {
	fn register(registry<netio.Registry>, token<netio.Token>, interests<netio.Interest>) i32 {
		os.die("need impl")
	}
	fn reregister(registry<netio.Registry>, token<netio.Token>, interests<netio.Interest>) i32 {
		os.die("need impl")
	}
	fn deregister(registry<netio.Registry>) i32 {
		os.die("need impl")
	}
}

fn source_register_default() i32 {
	return io.Uncategorized
}
