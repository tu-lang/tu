use string
use runtime

True<i64> = 1
Null<i64> = 0
End<i64>  = 0

enum {
    Insert,
    Update
}

mem Rbtree {
    RbtreeNode* root
    RbtreeNode* sentinel
	u64         insert
}

Rbtree::next(node<RbtreeNode>){

    sentinel<RbtreeNode> = this.sentinel
    if  node.right != sentinel  {
        return node.right.min(sentinel)
    }

    root<RbtreeNode> = this.root
    parent<RbtreeNode> = 0

    loop {
        parent = node.parent
        if  node == root  
            return Null
        if  node == parent.left  
            return parent

        node = parent
    }
}
Rbtree::find(hk<u64>){

    node<RbtreeNode>     = this.root
    sentinel<RbtreeNode> = this.sentinel

    while node != sentinel 
    {
        if  hk != node.key  {
            if  hk < node.key {
                node = node.left
            }else{
                node = node.right
            }
            continue
        }
        // if  node.k.type == key.type {
            return node.v
        // }
    }
    return Null
}

Rbtree::init(s<RbtreeNode>, i<RbtreeNode>){
    s.black()
    this.root = s
    this.sentinel = s
    this.insert = i
}

Rbtree::rbtree_left_rotate(root<u64*>, sentinel<RbtreeNode>,node<RbtreeNode>)
{
    temp<RbtreeNode> = node.right
    node.right = temp.left

    if  temp.left != sentinel  {
        temp.left.parent = node
    }

    temp.parent = node.parent

    if      node == *root  
        *root = temp
    else if node == node.parent.left  
        node.parent.left = temp
    else 
        node.parent.right = temp

    temp.left = node
    node.parent = temp
}


Rbtree::rbtree_right_rotate(root<u64*>, sentinel<RbtreeNode>,node<RbtreeNode>)
{
    temp<RbtreeNode> = node.left

    node.left = temp.right

    if  temp.right != sentinel  
        temp.right.parent = node

    temp.parent = node.parent

    if  node == *root  
        *root = temp
    else if  node == node.parent.right  
        node.parent.right = temp
    else 
        node.parent.left = temp

    temp.right = node
    node.parent = temp
}

Rbtree::head()
{
    node<RbtreeNode>     = this.root
    sentinel<RbtreeNode> = this.sentinel


    if  node == sentinel  {
        return Null
    }
    return node.v
}
Rbtree::insert(node<RbtreeNode>)
{
    root<u64*> = null
    temp<RbtreeNode> = null
    sentinel<RbtreeNode> = null
    //a binary tree insert 

    root = &this.root
    sentinel = this.sentinel

    if  *root == sentinel  {
        node.parent = null
        node.left = sentinel
        node.right = sentinel
        node.black()
        *root = node
        return Null
    }

    //TODO: tree.insert(*root,node,sentinel)
    insert<type_insert_or_update> = this.insert
    if Update == insert(*root, node, sentinel) {
        //update value do nothing here
        return Null
    }

    // re-balance tree 
    while node != *root && node.parent.color == 1 {

        if  node.parent == node.parent.parent.left  {
            temp = node.parent.parent.right

            if  temp.color == 1  {
                node.parent.black()
                temp.black()
                node.parent.parent.red()
                node = node.parent.parent

            } else {
                if  node == node.parent.right  {
                    node = node.parent
                    this.rbtree_left_rotate(root, sentinel, node)
                }
                node.parent.black()
                node.parent.parent.red()
                this.rbtree_right_rotate(root, sentinel, node.parent.parent)
            }

        } else {
            temp = node.parent.parent.left

            if  temp.color == 1  {
                node.parent.black()
                temp.black()
                node.parent.parent.red()
                node = node.parent.parent

            } else {
                if  node == node.parent.left  {
                    node = node.parent
                    this.rbtree_right_rotate(root, sentinel, node)
                }

                node.parent.black()
                node.parent.parent.red()
                this.rbtree_left_rotate(root, sentinel, node.parent.parent)
            }
        }
    }
    tn<RbtreeNode> = *root
    tn.black()
}