// fn members are illegal inside a class of a dyn package; use func.
class Box {
    v = 0
    fn get() { return this.v }
}
