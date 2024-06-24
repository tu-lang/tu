use fmt
use os

fn test_clos(){
    fmt.println("test_clos")
    start = "start"
    //miss
    fc = fn(a,b){
        if a != 1 os.die("a != 1")
        if b == null { } else {
            os.die("b != null")
        }
    }
    fc(1)

    fc = fn(a,b){
        if a == 1 {} else os.die("a != 1")
        if b == 2 {} else os.die("b != 2")
    }
    //over
    fc(1,2,3,4,5,6,7)
    //eq
    fc(1,2)

    //varadic
    fc = fn(args...){
        p<u64*> = args
        if p[0] == 4 {} else os.die("args != 4")
        v1 = p[1]
        if v1 == 1 {} else os.die("v1 != 1")
        v2 = p[2]
        if v2 == 2 {} else os.die("v2 != 2")
        v3 = p[3]
        if v3 == 3 {} else os.die("v3 != 3")
        v4 = p[4]
        if v4 == 4 {} else os.die("v4 != 4")
    }
    fc(1,2,3,4)
    //varadic2
    fc = fn(a,b,args...){
        if a != 1 os.die("a != 1")
        if b != 2 os.die("a != 2")
        p<u64*> = args
        if p[0] != 0 os.die("p[0] != 0")
    }
    fc(1,2)
    //varadic3
    fc = fn(a,args...){
        if a != 1 os.die("a != 1 ")
        p<u64*> = args
        if p[0] != 3 os.die("p[0] != 3")
        v1 = p[1]
        if v1 != 2 os.die("v1 != 2")
        v2 = p[2]
        if v2 != 3 os.die("v2 != 3")
        v3 = p[3]
        if v3 != 4 os.die("v3 != 4")
    }
    fc(1,2,3,4)

    //pass varadic

    fc = fn(a,fc,args...){
        if a != 1 os.die("pass varf a != 1")
        fc(a,2,args)
    }
    fc2 = fn(a,b,args...){
        if a != 1 os.die("passvarf a != 1")
        if b != 2 os.die("passvarf b != 2")
        p<u64*> = args
        if p[0] != 2 os.die("passvarf p[0] != 2")
        s1 = p[1]
        if s1 == "s1" {} else os.die("s1 != s1")
        s2 = p[2]
        if s2 == "s2" {} else os.die("s2 != s2")
    }
    fc(1,fc2,"s1","s2")

    if start == "start" {} else os.die("start")

    fmt.println("test_clos success")
}

class T1{a b}
T1::eq(a,b){
    if a != 1 os.die("a != 1")
    if b != 2 os.die("b != 2")
}
T1::over(a,b){
    if a != 1 os.die("a != 1")
    if b != 2 os.die("b != 2")
}
T1::miss(a,b){
    if a != 1 os.die("a != 1")
    if b != null os.die("b != null")
}
T1::vardic_miss(a,b,args...){
    if a != 1 os.die("a != 1")
    if b != null os.die("b != null")
    p<u64*> = args
    if p[0] != 0 os.die("p[0] != 0")
}
T1::vardic_eq(a,b,args...){
    if a != 1 os.die("a != 1")
    if b != 2 os.die("b != 2")
    p<u64*> = args
    if p[0] != 1 os.die("p[0] != 1")
    v1 = p[1]
    if v1 != 3 os.die("v1 != 3")
}
T1::vardic_over(a,b,args...){
    if a != 1 os.die("a != 1")
    p<u64*> = args
    if p[0] != 3 os.die("p[0] != 3")
    v1 = p[1]
    if v1 != 3 os.die("v1 != 3")
    v2 = p[2]
    if v2 != 4 os.die("v2 != 4")
    v3 = p[3]
    if v3 != 5 os.die("v3 != 5")
}
T1::vardic_pass(a,fc,args...){
    fc("test",args)
}
fn test_chain(){
    fmt.println("test chain")
    obj = new T1()
    obj.a = new T1() 
    obj.a.a = new T1()
    obj.a.a.b = 1

    obj.a.a.eq(1,2)
    obj.a.a.over(1,2,3,4)
    obj.a.a.miss(1)
    obj.a.a.vardic_miss(1)
    obj.a.a.vardic_over(1,2,3,4,5)
    obj.a.a.vardic_eq(1,2,3)

    fc = fn(v1,args...){
        if v1 != "test" os.die("v1 != test")
        p<u64*> = args
        if p[0] != 2 os.die("p[0] != 2")

        v3 = p[1]
        if v3 != 3 os.die("v3 != 3")
        v4 = p[2]
        if v4 != 4 os.die("v4 != 4")
    }

    obj.a.a.vardic_pass(1,fc,3,4)

    fmt.println("test chain success")
}
fn test_chain2(){
    fmt.println("test chain 2")
    fc = fn(){
        return fn(a,b,c){
            if a != 1 os.die("a != 1")
            if b != 2 os.die("a != 2") 
            if c != null os.die("a != 3")
        }
    }
    fc()(1,2)
    fmt.println("test chain 2 success")
}
class T2{}
T2::test(a,b,args...){
    if a != 1 os.die("a != 1")
    if b != "test" os.die("b != test")
    p<u64*> = args
    if p[0] != 1 os.die("p[0] != 1")
    v1 = p[1]
    if v1 != 3 os.die("v1 != 3")
}
fn test_obj(){
    fmt.println("test obj")
    obj = new T2()
    obj.test(1,"test",3)
    fmt.println("test obj success")
}

mem T3 {
	T3* inner
}
T3::dyn(v1<i64>){
	if this == null {
		os.die("v1 == null")
	}
	if v1 != 0 os.die("v1 != 0")
}
v<T3> = new T3{
	inner: new T3{}
}
fn test_common(){
    fmt.println("test common")
	v.inner.dyn()
    fmt.println("test common success")
}
fn main(){
    test_clos()
    test_chain()
    test_chain2()
    test_obj()
    test_common()
}