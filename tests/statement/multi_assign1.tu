use fmt
use string

class C1 {
    a = 77
}
mem M1 {
    i32 v
}
M1::init(v<i32>){
    this.v = v
}
M1::get(){
    return this.v
}
fn test_dyn(){
    fmt.println("test multi assign dyn ")
    //base type
    {
        v1,v2,v3,v4,v5,v6,v7,v8,v9,v10 = null,333,44.5,"hello",true,'f',[4],{"world":55} ,new C1() ,fn(){
            return 88
        }
        if v1 == null {} else os.die("v1 != null")
        if v2 == 333 {} else os.die("v2 != 333")
        if v3 == 44.5 {} else os.die("v3 != 44.5")
        if v4 == "hello" {} else os.die("v4 != hello")
        if v5 == true {} else os.die("v5 != true")
        if v6 == 'f' {} else os.die("v6 != f")
        if v7[0] == 4 {} else os.die("v7[0] != 4") 
        if v8["world"] == 55 {} else os.die("v8[world] != 55")
        if v9.a == 77 {} else os.die("v9.a != 77")
        if v10() == 88 {} else os.die("v10() != 88")

        v2,v4 += 333,"world"
        if v2 == 666 {} else os.die("v2 != 666")
        if v4 == "helloworld" {} else os.die("v4 != helloworld")
    }
    //native
    {
        v1<i8>,v2<u8>,v3<string.String>,v4<f64>,v5<M1> = 'a',-127, string.S(*"xxx"),10.32,new M1(33.(i8))
        if v1 == 'a' {} else os.die("v1 != a")
        if v2 == 129 {} else os.dief("v2:%d != 129 " ,int(v2))
        if v3.dyn() == "xxx" {} else os.die("v3 != xxx")
        if v4 == 10.32 {} else os.die("v4 != 10.32")
        //OPTMIZE: mem func is native 
        // if v5.get() == 33 {} else os.die("v5 != 33")
        v51<i32> = v5.get()
        if v51 == 33 {} else os.die("v51 != 33")
    }
    fmt.println("test multi assign dyn success")
}
class C3{
    p = 2
}
class C2 {
    a = 1
    b = [1,2]
    c = [new C3(),new C3()]
}
mem M2 {
    i32 a,b
    i32 arr[3]
    i32* p
}
fn test_complex(){
    fmt.println("test complex ")
    {
        v = new C2()
        v1 = {}
        v2 = []
        v.a , v.b[1] , v.c[1].p , v1["test"] , v2[]  = 11, 22 ,33,44 ,55

        if v.a == 11 {} else os.die("v.a != 11")
        if v.b[1] == 22 {} else os.die("v.b[1] != 22")
        if v.c[1].p == 33 {} else os.die("v.c[1].p != 33")
        if v1["test"] == 44 {} else os.die("v1[test] != 44")
        if v2[0] == 55 {} else os.die("v2[0] == 55")
    }
    {
        v1<M2> = new M2
        v2<i32> = 0
        v1.p = &v2

        v1.a,v1.b,v1.arr[0],*v1.p = 111,222,333,444
        if v1.a == 111 {} else os.die("v1.a != 111")
        if v1.b == 222 {} else os.die("v1.b != 222")
        if v1.arr[0] == 333 {} else os.die("v1.arr[0] != 333")
        if v2 == 444 {} else os.die("v2 != 444")
    }
    fmt.println("test complex success")
}

fn main(){
    test_dyn()
    test_complex()
}