use runtime


mem RbtreeNode {
    u64  key

    RbtreeNode* left
    RbtreeNode* right
    RbtreeNode* parent

    runtime.Value* k
    runtime.Value* v
    u8   color
}
RbtreeNode::red(){
	this.color = 1
}
RbtreeNode::black(){
	this.color = 0
}
RbtreeNode::min(sentinel<RbtreeNode>){
	node<RbtreeNode> = this
    while node.left != sentinel {
        node = node.left
    }
    return node
}