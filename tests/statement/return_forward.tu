// Multi-return `return callee()` forwarding matrix.
// Covers static / dynamic / member / chain / pad-truncate / async poll /
// cross-pkg / non-call must-not-raise paths that Wave A1 must keep correct.

use fmt
use os
use runtime
use return_fwd_owner as owner

// ---------------------------------------------------------------------------
// Static: package-level callees
// ---------------------------------------------------------------------------

fn static_pair() i32,i32 {
	return 7, 11
}
fn static_triple() i32,i32,i32 {
	return 1, 2, 3
}
fn static_mixed_iu() i32,u64 {
	return 9, 100.(u64)
}
fn static_mixed_if() i32,f64 {
	return 4, 3.5
}
fn static_one() i32 {
	return 42
}
fn static_with_args(a<i32>, b<i32>) i32,i32 {
	return a + 1, b + 2
}

fn fwd_static_pair() i32,i32 {
	return static_pair()
}
fn fwd_static_triple() i32,i32,i32 {
	return static_triple()
}
fn fwd_static_mixed_iu() i32,u64 {
	return static_mixed_iu()
}
fn fwd_static_mixed_if() i32,f64 {
	return static_mixed_if()
}
fn fwd_static_with_args() i32,i32 {
	return static_with_args(10, 20)
}
// Caller wants 3; callee returns 2 → pad third with default 0.
fn fwd_pad_to_three() i32,i32,i32 {
	return static_pair()
}
// Caller wants 2; callee returns 3 → truncate to first two.
fn fwd_trunc_to_two() i32,i32 {
	return static_triple()
}
// Multi-return fn forwarding a single-return call: first slot only, rest default.
fn fwd_single_into_multi() i32,i32 {
	return static_one()
}
// Explicit unpack still works (control / non-forward path).
fn unpack_then_return() i32,i32 {
	a<i32>, b<i32> = static_pair()
	return a, b
}
// Nested forward: return another forwarder.
fn fwd_nested_forward() i32,i32 {
	return fwd_static_pair()
}

fn test_static_forward(){
	fmt.println("test_static_forward")
	a<i32>, b<i32> = fwd_static_pair()
	if a != 7 || b != 11 os.die("fwd_static_pair")

	x<i32>, y<i32>, z<i32> = fwd_static_triple()
	if x != 1 || y != 2 || z != 3 os.die("fwd_static_triple")

	i<i32>, u<u64> = fwd_static_mixed_iu()
	if i != 9 || u != 100.(u64) os.die("fwd_static_mixed_iu")

	fi<i32>, ff<f64> = fwd_static_mixed_if()
	if fi != 4 os.die("fwd_static_mixed_if i")
	if ff < 3.4 || ff > 3.6 os.die("fwd_static_mixed_if f")

	wa<i32>, wb<i32> = fwd_static_with_args()
	if wa != 11 || wb != 22 os.die("fwd_static_with_args")

	p0<i32>, p1<i32>, p2<i32> = fwd_pad_to_three()
	if p0 != 7 || p1 != 11 || p2 != 0 os.die("fwd_pad_to_three")

	t0<i32>, t1<i32> = fwd_trunc_to_two()
	if t0 != 1 || t1 != 2 os.die("fwd_trunc_to_two")

	s0<i32>, s1<i32> = fwd_single_into_multi()
	if s0 != 42 || s1 != 0 os.die("fwd_single_into_multi")

	c0<i32>, c1<i32> = unpack_then_return()
	if c0 != 7 || c1 != 11 os.die("unpack_then_return")

	n0<i32>, n1<i32> = fwd_nested_forward()
	if n0 != 7 || n1 != 11 os.die("fwd_nested_forward")

	fmt.println("test_static_forward success")
}

// ---------------------------------------------------------------------------
// Static: mem member + chain
// ---------------------------------------------------------------------------

mem PairBox {
	i32 a
	i32 b
}
PairBox::as_pair() i32,i32 {
	return this.a, this.b
}
PairBox::as_triple() i32,i32,i32 {
	return this.a, this.b, this.a + this.b
}

mem NestHold {
	PairBox* inner
}
NestHold::forward_inner_pair() i32,i32 {
	return this.inner.as_pair()
}

fn fwd_member_pair() i32,i32 {
	p<PairBox> = new PairBox
	p.a = 3
	p.b = 5
	return p.as_pair()
}
fn fwd_member_triple() i32,i32,i32 {
	p<PairBox> = new PairBox
	p.a = 8
	p.b = 9
	return p.as_triple()
}
fn fwd_chain_member() i32,i32 {
	h<NestHold> = new NestHold
	h.inner = new PairBox
	h.inner.a = 13
	h.inner.b = 17
	return h.forward_inner_pair()
}
fn fwd_nested_chain_call() i32,i32 {
	h<NestHold> = new NestHold
	h.inner = new PairBox
	h.inner.a = 21
	h.inner.b = 22
	return h.inner.as_pair()
}

fn test_member_chain_forward(){
	fmt.println("test_member_chain_forward")
	a<i32>, b<i32> = fwd_member_pair()
	if a != 3 || b != 5 os.die("fwd_member_pair")

	x<i32>, y<i32>, z<i32> = fwd_member_triple()
	if x != 8 || y != 9 || z != 17 os.die("fwd_member_triple")

	c0<i32>, c1<i32> = fwd_chain_member()
	if c0 != 13 || c1 != 17 os.die("fwd_chain_member")

	n0<i32>, n1<i32> = fwd_nested_chain_call()
	if n0 != 21 || n1 != 22 os.die("fwd_nested_chain_call")

	fmt.println("test_member_chain_forward success")
}

// ---------------------------------------------------------------------------
// Static: mem pointer second return (must not drop / null the pointer)
// ---------------------------------------------------------------------------

mem Node {
	i32 tag
}
fn make_node_pair(tag<i32>) i32, Node {
	n<Node> = new Node
	n.tag = tag
	return 1, n
}
fn fwd_make_node_pair(tag<i32>) i32, Node {
	return make_node_pair(tag)
}

fn test_mem_second_return(){
	fmt.println("test_mem_second_return")
	err<i32>, n<Node> = fwd_make_node_pair(55)
	if err != 1 os.die("fwd_make_node_pair err")
	if n == null os.die("fwd_make_node_pair null node")
	if n.tag != 55 os.die("fwd_make_node_pair tag")
	fmt.println("test_mem_second_return success")
}

// ---------------------------------------------------------------------------
// Static: cross-package forward
// ---------------------------------------------------------------------------

fn fwd_cross_pkg_pair() i32,i32 {
	return owner.owner_pair()
}
fn fwd_cross_pkg_member() i32,i32 {
	return owner.owner_member_pair()
}

fn test_cross_pkg_forward(){
	fmt.println("test_cross_pkg_forward")
	a<i32>, b<i32> = fwd_cross_pkg_pair()
	if a != 100 || b != 200 os.die("fwd_cross_pkg_pair")

	c<i32>, d<i32> = fwd_cross_pkg_member()
	if c != 30 || d != 40 os.die("fwd_cross_pkg_member")

	// Direct cross-pkg multi-return still works (control).
	e<i32>, f<i32> = owner.owner_pair()
	if e != 100 || f != 200 os.die("direct owner_pair")

	fmt.println("test_cross_pkg_forward success")
}

// ---------------------------------------------------------------------------
// Non-call sole return must not be treated as multi-forward
// (field chain ending in value, not call).
// ---------------------------------------------------------------------------

mem Leaf {
	i32 v
}
Leaf::get() Leaf {
	return this
}
fn field_chain_value() i32 {
	l<Leaf> = new Leaf
	l.v = 77
	// Chain ends in field `.v` after a call — must remain single-return
	// (must not raise mcount as if forwarding multi-return).
	return l.get().v
}

fn test_non_call_chain_not_forward(){
	fmt.println("test_non_call_chain_not_forward")
	// If mcount were wrongly raised, compile/runtime would break.
	got<i32> = field_chain_value()
	if got != 77 os.die("field_chain_value")
	fmt.println("test_non_call_chain_not_forward success")
}

// ---------------------------------------------------------------------------
// Dynamic: func multi-return forward
// ---------------------------------------------------------------------------

func dyn_pair(){
	return 88, "t3"
}
func dyn_triple(){
	return 1, "two", 3
}
func fwd_dyn_pair(){
	return dyn_pair()
}
func fwd_dyn_triple(){
	return dyn_triple()
}
func dyn_with_args(a, b){
	return a + 1, b + 2
}
func fwd_dyn_with_args(){
	return dyn_with_args(5, 6)
}

fn test_dynamic_forward(){
	fmt.println("test_dynamic_forward")
	a, b = fwd_dyn_pair()
	if a != 88 || b != "t3" os.die("fwd_dyn_pair")

	x, y, z = fwd_dyn_triple()
	if x != 1 || y != "two" || z != 3 os.die("fwd_dyn_triple")

	p, q = fwd_dyn_with_args()
	if p != 6 || q != 8 os.die("fwd_dyn_with_args")

	fmt.println("test_dynamic_forward success")
}

// ---------------------------------------------------------------------------
// Dynamic: class member multi-return forward
// ---------------------------------------------------------------------------

class DynBox {
	a = 0
	b = 0
	func init(x, y){
		this.a = x
		this.b = y
	}
	func as_pair(){
		return this.a, this.b
	}
	func forward_self(){
		return this.as_pair()
	}
}

func fwd_class_member(){
	o = new DynBox(14, 15)
	return o.forward_self()
}
func fwd_class_direct(){
	o = new DynBox(16, 17)
	return o.as_pair()
}

fn test_class_member_forward(){
	fmt.println("test_class_member_forward")
	a, b = fwd_class_member()
	if a != 14 || b != 15 os.die("fwd_class_member")

	c, d = fwd_class_direct()
	if c != 16 || d != 17 os.die("fwd_class_direct")
	fmt.println("test_class_member_forward success")
}

// ---------------------------------------------------------------------------
// Async: return this.inner.poll(ctx) must forward PollReady + value
// ---------------------------------------------------------------------------

mem InnerReady: async {
	i64 val
}
InnerReady::poll(ctx){
	return runtime.PollReady, this.val
}

mem OuterFwd: async {
	InnerReady* inner
}
OuterFwd::poll(ctx){
	// Critical: must forward both status and value (not drop to 0).
	return this.inner.poll(ctx)
}

fn make_outer_fwd(v<i64>) OuterFwd {
	o<OuterFwd> = new OuterFwd
	o.inner = new InnerReady
	o.inner.val = v
	return o
}

fn test_async_poll_forward(){
	fmt.println("test_async_poll_forward")
	o<OuterFwd> = make_outer_fwd(99.(i64))
	got<i64> = runtime.block(o)
	if got != 99.(i64) os.die("async poll forward value")
	fmt.println("test_async_poll_forward success")
}

// Nested async: package-level style via member that forwards another leaf.
mem LeafReady: async {
	i32 n
}
LeafReady::poll(ctx){
	return runtime.PollReady, this.n
}
mem MidFwd: async {
	LeafReady* leaf
}
MidFwd::poll(ctx){
	return this.leaf.poll(ctx)
}
mem TopFwd: async {
	MidFwd* mid
}
TopFwd::poll(ctx){
	return this.mid.poll(ctx)
}

fn test_async_poll_forward_two_hops(){
	fmt.println("test_async_poll_forward_two_hops")
	top<TopFwd> = new TopFwd
	top.mid = new MidFwd
	top.mid.leaf = new LeafReady
	top.mid.leaf.n = 123
	got<i32> = runtime.block(top)
	if got != 123 os.die("two-hop async poll forward")
	fmt.println("test_async_poll_forward_two_hops success")
}

fn main(){
	test_static_forward()
	test_member_chain_forward()
	test_mem_second_return()
	test_cross_pkg_forward()
	test_non_call_chain_not_forward()
	test_dynamic_forward()
	test_class_member_forward()
	test_async_poll_forward()
	test_async_poll_forward_two_hops()
}
