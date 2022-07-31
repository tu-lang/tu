use string

mem Rbtree {
    Rbtree_node* root
    Rbtree_node* sentinel
	u64          insert
}

mem Rbtree_node {
    u64  key

    Rbtree_node* left
    Rbtree_node* right
    Rbtree_node* parent

    Value* k
    Value* v
    u8   color
}

func rbtree_min(node<Rbtree_node>,sentinel<Rbtree_node>){
    while node.left != sentinel {
        node = node.left
    }
    return node
}
func rbtree_next(tree<Rbtree>,node<Rbtree_node>){

    sentinel<Rbtree_node> = tree.sentinel

    if  node.right != sentinel  {
        return rbtree_min(node.right, sentinel)
    }

    root<Rbtree_node> = tree.root
    parent<Rbtree_node> = 0
    while true {
        parent = node.parent
        if  node == root  
            return Null
        if  node == parent.left  
            return parent

        node = parent
    }
}
func map_find(map<Value>, key<Value>){

    tree<Rbtree>          = map.data
    node<Rbtree_node>     = null
    sentinel<Rbtree_node> = null

    hk<u64> = 0
    match key.type {
        Bool   : hk = key.data
        Int    : hk = key.data
        String : hk = hash_key(key.data,string.stringlen(key.data))
    }
    node = tree.root
    sentinel = tree.sentinel

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
        //FIXME: k<u64>;k.type == key.type 会进入obj.member 访问
        if  node.k.type == key.type {
            return node.v
        }
    }
    return Null
}
func map_insert_or_update(temp<Rbtree_node>, node<Rbtree_node>,sentinel<Rbtree_node>)
{
    // **p
    // FIXME: p<rebtree_node*> parser报错
    p<u64*> = null

    while True {
        if  node.key == temp.key {
            if  temp.v.type == node.v.type {
                temp.v = node.v
                return Null
            }
        }
        if  node.key < temp.key {
            p = &temp.left 
        }else{
            p = &temp.right
        }
        if  *p == sentinel  {
            break
        }
        temp = *p
    }

    *p = node
    node.parent = temp
    node.left = sentinel
    node.right = sentinel

    // make red
    node.color = 1
}
func map_insert(map<Value>, k<Value>,v<Value>)
{

    tree<Rbtree> = map.data
    node<Rbtree_node> = new Rbtree_node
    hk<u64> = 0
    if  k.type == Bool || k.type == Int {
        hk = k.data
    }
    if  k.type == String {
        hk = hash_key(k.data,string.stringlen(k.data))
    }
    node.key = hk
    node.k = k
    node.v = v
    rbtree_insert(tree,node)
}

func rbtree_init(tree<Rbtree>, s<u64>, i<u64>){
    rbtree_sentinel_init(s)
    tree.root = s
    tree.sentinel = s
    tree.insert = i
}
func map_create(){
    tree<Rbtree> = new Rbtree
    sentinel<Rbtree_node> = new Rbtree_node

    rbtree_init(tree,sentinel,map_insert_or_update)
    return tree
}


func rbtree_left_rotate(root<u64*>, sentinel<Rbtree_node>,node<Rbtree_node>)
{
    temp<Rbtree_node> = node.right
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


func rbtree_right_rotate(root<u64*>, sentinel<Rbtree_node>,node<Rbtree_node>)
{
    temp<Rbtree_node> = node.left

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
func rbtree_insert(tree<Rbtree>, node<Rbtree_node>)
{
    root<u64*> = null
    temp<Rbtree_node> = null
    sentinel<Rbtree_node> = null
    //a binary tree insert 

    root = &tree.root
    sentinel = tree.sentinel

    if  *root == sentinel  {
        node.parent = null
        node.left = sentinel
        node.right = sentinel
        black(node)
        *root = node
        return Null
    }

    //TODO: tree.insert(*root,node,sentinel)
    insert<u64> = tree.insert
    insert(*root, node, sentinel)

    // re-balance tree 
    //TODO: condition可以判断返回值是否是memtype决定是否需要isTrue
    //FIXME: 最左原则，如果第一个表达式失败，则后续不需要再继续判断了
    //while node != *root && node.parent.color == 1 {
    while node != *root {
        if  node.parent.color != 1  {break}

        if  node.parent == node.parent.parent.left  {
            temp = node.parent.parent.right

            if  temp.color == 1  {
                black(node.parent)
                black(temp)
                red(node.parent.parent)
                node = node.parent.parent

            } else {
                if  node == node.parent.right  {
                    node = node.parent
                    rbtree_left_rotate(root, sentinel, node)
                }

                black(node.parent)
                red(node.parent.parent)
                rbtree_right_rotate(root, sentinel, node.parent.parent)
            }

        } else {
            temp = node.parent.parent.left

            if  temp.color == 1  {
                black(node.parent)
                black(temp)
                red(node.parent.parent)
                node = node.parent.parent

            } else {
                if  node == node.parent.left  {
                    node = node.parent
                    rbtree_right_rotate(root, sentinel, node)
                }

                black(node.parent)
                red(node.parent.parent)
                rbtree_left_rotate(root, sentinel, node.parent.parent)
            }
        }
    }

    black(*root)
}