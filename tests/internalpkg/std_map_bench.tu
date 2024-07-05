use std
use os
use std.map
use string
use runtime

strings<map.Rbtree> = null

func string_insert(temp<map.RbtreeNode>, node<map.RbtreeNode>,sentinel<map.RbtreeNode>)
{
    p<u64*> = null
	loop {
        if  node.key == temp.key {
            if node.k != temp.k  
                fmt.printf("[kv_update] hash conflict %s %s\n",node.v,temp.v)
            temp.v = node.v
            return map.Update
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
    node.color = 1
    return map.Insert
}
func bench1(){
	fmt.println("test bench1")
    start<i64> = std.ntime()
    for i<i32> = 0 ; i < 1000000 ; i += 1  {
        s<string.Str> = string.stringfmt(*"str-%d",i)
        node<map.RbtreeNode> = new map.RbtreeNode {
            key : s.hash64(),
            v   : s
        }
        strings.insert(node)
    }
    end<i64> = std.ntime()
    lat<i64> = end - start
    lat /= 1000000 // ms
	if lat > 10000 {
		os.dief("map bench latency over 10sec :%d",int(lat))
	}
    fmt.println(int(lat),"ms")
    for i<i32> = 0 ; i < 1000000 ; i += 1  {
        s<string.Str> = string.stringfmt(*"str-%d",i)
        ps<u64> = strings.find(s.hash64())
        if ps == 0 {
            runtime.printf(s)
            os.die("s not exist")
        }
    }
	fmt.println("test bench1 success")
    return true
}
func main(){
	strings = map.map_create(string_insert.(i64))
    bench1()
}