use io
use netio
use netio.poll
use netio.interest
use os

api Source {
	fn register(registry<poll.Registry>, token<netio.Token>, interests<interest.Interest>) i32 {
		os.die("need impl")
	}
	fn reregister(registry<poll.Registry>, token<netio.Token>, interests<interest.Interest>) i32 {
		os.die("need impl")
	}
	fn deregister(registry<poll.Registry>) i32 {
		os.die("need impl")
	}
}

fn source_register_default() i32 {
	return io.Uncategorized
}
