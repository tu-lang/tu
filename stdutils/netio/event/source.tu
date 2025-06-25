use netio

api Source {
    fn register(
        registry<netio.Registry>,
        token<u64>,
        interests<netio.Interest>,
    ) (i32)

    fn reregister(
        registry<netio.Registry>,
        token<u64>,
        interests<netio.Interest>,
    ) (i32)

    fn deregister(registry<netio.Registry>)(i32)
}