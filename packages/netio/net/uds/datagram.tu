use netio
use io
use netio.event
use netio.sys as nsys
use net
use sys as libsys
use netio.sys.uds as sysuds

mem UnixDatagram {
	u64 iosrc_bits
}

const UnixDatagram::bind(path<string.String>) i32, UnixDatagram {
	err<i32>, socket<net.UnixDatagram> = sysuds.bind(path)
	if err != io.Ok
		return err, null
	return io.Ok, UnixDatagram::from_std(socket)
}

const UnixDatagram::from_std(socket<net.UnixDatagram>) UnixDatagram {
	d<UnixDatagram> = new UnixDatagram
	d.iosrc_bits = netio.iosource_new_bits(socket.(u64), socket.as_raw_fd())
	return d
}

UnixDatagram::std_socket() net.UnixDatagram {
	bits<u64> = netio.iosource_fd_holder_bits(this.iosrc_bits)
	return bits.(net.UnixDatagram)
}

UnixDatagram::recv_from(buf<io.Buf>) i32, u64, u64 {
	err<i32>, n<u64>, addr = sysuds.recv_from(this.std_socket(), buf)
	bits<u64> = addr.(u64)
	return err, n, bits
}

UnixDatagram::recv(buf<io.Buf>) i32, u64 {
	std_d<net.UnixDatagram> = this.std_socket()
	err<i32>, n<u64> = std_d.recv(buf)
	return err, n
}

UnixDatagram::send_to(buf<io.Buf>, path<string.String>) i32, u64 {
	std_d<net.UnixDatagram> = this.std_socket()
	err<i32>, n<u64> = std_d.send_to(buf, path)
	return err, n
}

impl event.Source for UnixDatagram {
	fn enroll(registry<netio.Registry>, t<netio.Token>, interests<netio.Interest>) i32 {
		return netio.iosource_register_bits(this.iosrc_bits, registry, t, interests)
	}
	fn reenroll(registry<netio.Registry>, t<netio.Token>, interests<netio.Interest>) i32 {
		return netio.iosource_reregister_bits(this.iosrc_bits, registry, t, interests)
	}
	fn detach(registry<netio.Registry>) i32 {
		return netio.iosource_deregister_bits(this.iosrc_bits, registry)
	}
}
