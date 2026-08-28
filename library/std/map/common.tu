use std
use runtime
use string
use fmt
// cfg(mod_static,true)

fn type_hash_key(k<string.String>)
fn type_insert_or_update(temp<RbtreeNode>, node<RbtreeNode>,sentinel<RbtreeNode>)

// Static-only map factory; insertfn is a typed tree callback pointer.
fn map_create(insertfn<u64>){
    fn_bits<u64> = insertfn
    if fn_bits == 0.(u64) {
        fn_bits = map_insert_or_update.(u64)
    }
    sentinel<RbtreeNode> = new RbtreeNode
	sentinel.black()

	return new Rbtree {
		root : sentinel,
		sentinel : sentinel,
		insert: fn_bits,
        count: 0,
	}
}

// Static tree callback — not an export facade (needs mem-typed params).
fn map_insert_or_update(temp<RbtreeNode>, node<RbtreeNode>, sentinel<RbtreeNode>)
{
    // **p
    // FIXME: p<rebtree_node*> parser
    p<u64*> = null

    loop {
        if  node.key == temp.key {
            equal<i32> = 0
            if node.k.type == runtime.String || temp.k.type == runtime.String {
                equal = runtime.value_string_equal(node.k,temp.k,1.(i8))
            } else if node.k.type == runtime.Int || temp.k.type == runtime.Int || node.k.type == runtime.Char {
                equal = runtime.value_int_equal(node.k,temp.k,1.(i8))
            }else{
                equal = runtime.value_int_equal(node.k,temp.k,1.(i8))
            }
            if !equal  {
                fmt.printf("[kv_update] hash conflict %s %s\n",node.k,temp.k)
            }
            //compatible with mem type var
            // if  temp.v.type == node.v.type {
                temp.v = node.v
                return Update
            // }
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

fn hash_key(data<u8*>, len<u64>){
    i<i64>   = 0
    key<i64> = 0
    for(i = 0 ; i < len ; i += 1){
        temp_key<u32> = key
        temp_data<u8*> = data + i
        key = temp_key * 31 + *temp_data
    }
    return key
}

export func map_insert(m, k, v)
{
    mv<runtime.Value> = m
    kv<runtime.Value> = k
    tree<Rbtree> = mv.data
    node<RbtreeNode> = new RbtreeNode
    hk<u64> = 0
    match kv.type {
        runtime.Bool | runtime.Int | runtime.Float : hk = kv.data
        runtime.String: hk = kv.data.(string.Str).hash64()
    }
    node.key = hk
    node.k = kv
    node.v = v
    tree.insert(node)
}

export func map_find(m, key){
    mv<runtime.Value> = m
    kv<runtime.Value> = key
    hk<u64> = 0
    match kv.type {
        runtime.Bool   | runtime.Int | runtime.Float : hk = kv.data
        runtime.String : {
            hk = kv.data.(string.Str).hash64()
        }
    }
    tree<Rbtree>  = mv.data
    return tree.find(hk)
}
