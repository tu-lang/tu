use fmt
use os

class T1{ a b}
fn f1_2(){return 88,"t3"}
T1::test(){
    if this.a == "t1" {} else os.die("this.a != t1")
    if this.b[1] == "t2" {} else os.die("this.b != t2") 
    fmt.println("case 1 var.assign success")

    this.a,this.b = f1_2()
    if this.a == 88 {} else os.die("this .a != 88")
    if this.b == "t3" {} else os.die("this.b != t3")
    fmt.println("case 2 member.assign success")
}
T1::test2(){
    this.a ,this.b = f1_3()
    if this.a != "f13" os.die("thisa != f13")
    if this.b != null os.die("this.b != null")

    this.a,this.b = f1_4()
    if this.a != null os.die("this.a != null")
    if this.b != null os.die("this.b != null")
    fmt.println("T1::test2 success")
}
T1::test3(){
    this.a,this.b = f1_5()
    if this.a != 1 os.die("this.1 != 1")
    if this.b != "2" os.die("this.b != 2")
    this.a = f1_5()
    if this.a != 1 os.die("this.a != 1")
    fmt.println("T3::test3 success")
}

fn f1_1(){return "t1",[1,"t2"]}
fn f1_3(){return "f13"}
fn f1_4(){}
fn f1_5(){
    return 1,"2",3.4,[5]
}
fn test_objmember(){
    fmt.println("test obj member")
    //1. base
    obj = new T1()
    obj.a,obj.b = f1_1()
    obj.test()
    //2. little  
    obj.a ,obj.b = f1_3()
    if obj.a != "f13" os.die("obja != f13")
    if obj.b != null os.die("obj.b != null")

    obj.a,obj.b = f1_4()
    if obj.a != null os.die("obja != null")
    if obj.b != null os.die("obj.b != null")

    obj.test2()
    //3. over
    obj.a,obj.b = f1_5()
    if obj.a != 1 os.die("obj.1 != 1")
    if obj.b != "2" os.die("obj.b != 2")
    obj.a = f1_5()
    if obj.a != 1 os.die("obj.a != 1")
    obj.test3()

    fmt.println("test obj member success")
}

fn tm_1(){
    f<f32> = 3.3
    return 2.(i32) , f , 4.(i32)
}
fn tm_2(){
    f<f32> = 3.3
    return f,2.(i32)
}
fn test_memvar() {
    fmt.println("test mem var")
    // eq
    a<i32> ,b<f32>,c<i32> = tm_1()
    if a != 2 os.die("a != 2") 
    // fmt.println(float(b))
    if b > 3.299 && b < 3.3 {} else {
        os.die("b != 3.3")
    }
    fmt.println(int(c))
    if c != 4 os.die("c != 4")
    //little
    a = tm_1()
    if a != 2 os.die("a != 2")
    //over
    a,b,c,d<i32> = tm_1()
    if d != 0 os.die("d != 0")

    //float
    v<f32> = tm_2()
    if v > 3.299 && v < 3.3 {} else {
        os.die("v != 3.3")
    }
    v,v2<i32> = tm_2()
    if v > 3.299 && v < 3.3 {} else {
        os.die("v != 3.3")
    }
    if v2 != 2 os.die("v2 != 2")

    fmt.println("test mem var success")
}
fn td_1(){
    return 1
}
fn td_2(){
    return "1",2,3.3
}

fn test_dynvar(){
    fmt.println("test dyn var")
    //eq
    a,b,c = td_2()
    if a != "1" os.die("a != 1")
    if b != 2 os.die("b != 2")
    if c != 3.3 os.die("c != 3.3")
    //litte
    a = td_2()
    if a != "1" os.die("a != 1")
    a,b = td_1()
    if a != 1 os.die("a != 1")
    if b != null os.die("a != null")
    //over
    a,b,c,d = td_2()
    fmt.println(c)
    if c != 3.3 os.die("c != 3.3")
    if d != null os.die("d != null")
    fmt.println("test dyn var success")
}

fn ti_1(){
    return "1","2","3"
}
fn ti_2(){ return "4" }
class T2 {
    a = []
    b = []
    c = []
    d = []
}
T2::test1(){
    fmt.println("T2::test1() dyn")
    //eq
    this.a[],this.b[],this.c[] =  ti_1()
    if this.a[0] != "1" os.die("this.a[0] != 1")
    if this.b[0] != "2" os.die("this.b[0] != 2")
    if this.c[0] != "3" os.die("this.c[0] != 3")
    //less
    this.a[],this.b[] = ti_1()
    if this.a[1] != "1" os.die("this.a[1] != 1")
    if this.b[1] != "2" os.die("this.b[1] != 2")

    this.a[1],this.b[1] = ti_2()
    if this.a[1] != "4" os.die("this.a[1] != 4")
    if this.b[1] != null os.die("this.b[1] != null")
    //over
    this.a[],this.b[],this.c[],this.d[] = ti_1()
    if this.a[2] != "1" os.die("this.a[2] != 1")
    if this.b[2] != "2" os.die("this.b[2] != 2")
    if this.a[0] != "1" os.die("this.a[0] != 1")
    if this.b[0] != "2" os.die("this.b[0] != 2")
    if this.c[0] != "3" os.die("this.c[0] != 3")
    if this.d[0] != null os.die("this.d[0] != null")

    fmt.println("T2::test1() success")
}

mem TIs {
    u64* arr1
    u64  arr2[3]
    u64  arr3[3]
}
fn newtis_1(){
    return new TIs{
        arr1 : new 24,
    }
}
fn ti_3(){
    return 1.(i32),2.(i32),3.(i32)
}
fn ti_32(){
    return 11.(i32),22.(i32),33.(i32)
}
//obj.member index
//type assert index
fn test_index(){
    fmt.println("test arr index")
    obj = new T2()
    obj.test1()
    //static

    obj = newtis_1()
    obj.(TIs).arr1[0],
    obj.(TIs).arr2[0],
    obj.(TIs).arr3[0] = ti_3()    

    if obj.(TIs).arr1[0] != 1 os.die("tis.arr1[0] != 1")
    if obj.(TIs).arr2[0] != 2 os.die("tis.arr2[0] != 1")
    if obj.(TIs).arr3[0] != 3 os.die("tis.arr3[0] != 1")

    obj.(TIs).arr1[1],
    obj.(TIs).arr2[1],
    obj.(TIs).arr3[1] = ti_32()    
    if obj.(TIs).arr1[1] != 11 os.die("tis.arr1[1] != 11")
    if obj.(TIs).arr2[1] != 22 os.die("tis.arr2[1] != 22")
    if obj.(TIs).arr3[1] != 33 os.die("tis.arr3[1] != 33")

    if obj.(TIs).arr1[0] != 1 os.die("tis.arr1[0] != 1")
    if obj.(TIs).arr2[0] != 2 os.die("tis.arr2[0] != 1")
    if obj.(TIs).arr3[0] != 3 os.die("tis.arr3[0] != 1")

    fmt.println("test arr index success")
}
//var pointer
//struct member
mem Ti2 {
    u64 arr2[3]
    u64 arr3[3]
}
fn ti2_1(){
    return 11.(i32),22.(i32),33.(i32)
}
fn ti2_2(){
    return 44.(i32)
}
fn ti2_3(){
    return 55.(i32),66.(i32)
}
fn test_index2(){
    fmt.println("test index2")
    arr1<u64*> = new 24
    v<Ti2> = new Ti2 {}
    //eq
    arr1[0],v.arr2[0],v.arr3[0] = ti2_1() 
    if arr1[0] != 11 os.die("arr1[0] != 11")
    if v.arr2[0] != 22 os.die("v.arr2[0] != 22")
    if v.arr3[0] != 33 os.die("v.arr3[0] != 33")
    //little
    arr1[1],v.arr2[1],v.arr3[1] = ti2_3()
    if arr1[1] != 55 os.die("arr1[1] != 55")
    if v.arr2[1] != 66 os.die("v.arr2[1] != 66")
    if v.arr3[1] != 0 os.die("v.arr3[1] != 0")

    arr1[1],v.arr2[1] = ti2_2()
    if arr1[1] != 44 os.die("arr1[1] != 55")
    if v.arr2[1] != 0 os.die("v.arr2[1] != 66")
    //over
    arr1[2] = ti2_1()
    if arr1[2] != 11 os.die("arr1[2] != 11")

    if arr1[0] != 11 os.die("arr1[0] != 11")
    if v.arr2[0] != 22 os.die("v.arr2[0] != 22")
    if v.arr3[0] != 33 os.die("v.arr3[0] != 33")

    fmt.println("test index2 success")
}

mem TS1 {
    i32  a
    f32  b
    i32* c
    i32  d
}
fn ts_1(){
    f<f32> = 22.2
    p<i32*> = new 4
    *p = 33
    return 11.(i32),f, p
}
fn ts_2(){
    return 55.(i32)
}
fn ts_3(){
    return 66.(i32),77.(i32)
}
fn test_struct(){
    fmt.println("test struct")
    v<TS1> = new TS1{}
    //eq
    v.a , v.b,v.c = ts_1()
    if v.a != 11 os.die("v.a != 11")
    if v.b > 22.2 && v.b < 22.21 {} else{
        os.die("v.b != 22.2")
    } 
    if *v.c != 33 os.die("*v.c != 33")
    //little
    v.a ,v.b = ts_1()
    if v.a != 11 os.die("v.a != 11")
    if v.b > 22.2 && v.b < 22.21 {} else{
        os.die("v.b != 22.2")
    } 
    //over
    v.a,v.d = ts_2()
    if v.a != 55 os.die("v.a != 55")
    if v.d != 0 os.die("v.a != 0")
    if v.b > 22.2 && v.b < 22.21 {} else{
        os.die("v.b != 22.2")
    } 
    if *v.c != 33 os.die("*v.c != 33")

    //del ref

    v2<i32> = 0
    p<i32*> = &v2

    *p,*v.c = ts_3()
    if *p != 66 os.die("*p != 66")
    if *v.c != 77 os.die("*v.c != 77")
    if v.d != 0 os.die("v.a != 0")
    fmt.println("test struct success")
}

class TCS {
    a b c d
}
fn tcs_1(){
    return 11,22.2,33
}
fn tcs_2(){
    return 44
}
fn test_class(){
    fmt.println("test class")
    obj = new TCS()
    //eq
    obj.a , obj.b,obj.c = tcs_1()
    if obj.a != 11 os.die("obj.a != 11")
    if obj.b > 22.1 && obj.b < 22.3 {} else{
        os.die("obj.b != 22.2")
    } 
    if obj.c != 33 os.die("obj.c != 33")
    //little
    obj.a ,obj.b = tcs_1()
    if obj.a != 11 os.die("obj.a != 11")
    if obj.b > 22.1 && obj.b < 22.3 {} else{
        os.die("obj.b != 22.2")
    } 
    //over
    obj.a,obj.d = tcs_2()
    if obj.a != 44 os.die("obj.a != 44")
    if obj.d != null os.die("obj.a != null")
    if obj.b > 22.1 && obj.b < 22.3 {} else{
        os.die("obj.b != 22.2")
    } 
    if obj.c != 33 os.die("obj.c != 33")
    fmt.println("test struct success")
}
mem MC2 {
    u64* arr1
    u64  arr2[3]
    u64  arr3[3]
}
mem MC1 {
    MC2  v1
    MC2* v2
}
fn newmc(){
    return new MC1 {
        v1 : MC2 {
            arr1 : new 24
        }
        v2 : new MC2{
            arr1 : new 24
        }
    }
}
fn tc1(){
    return 11.(i32),22.(i32),33.(i32)
}
fn tc2(){
    return 11.(i32)
}
fn test_chain(){
    fmt.println("test chain expr")
    obj<MC1> = newmc()
    //eq
    obj.v1.arr1[0],
    obj.v2.arr2[0],
    obj.v1.arr3[0] = tc1() 
    if obj.v1.arr1[0] != 11 os.die(" obj.v1.arr1[0] != 11")
    if obj.v2.arr2[0] != 22 os.die(" obj.v1.arr1[0] != 22")
    if obj.v1.arr3[0] != 33 os.die(" obj.v1.arr1[0] != 33")
    //little
    obj.v1.arr1[1],
    obj.v2.arr3[1] = tc1() 
    if obj.v1.arr1[1] != 11 os.die(" obj.v1.arr1[1] != 11")
    if obj.v2.arr3[1] != 22 os.die(" obj.v3.arr1[1] != 33")
    //over
    obj.v1.arr1[2],
    obj.v2.arr2[2],
    obj.v1.arr3[2] = tc2() 
    if obj.v1.arr1[2] != 11 os.die(" obj.v1.arr1[0] != 11")
    if obj.v2.arr2[2] != 0 os.die(" obj.v1.arr1[0] != 0")
    if obj.v1.arr3[2] != 0 os.die(" obj.v1.arr1[0] != 0")


    if obj.v1.arr1[0] != 11 os.die(" obj.v1.arr1[0] != 11")
    if obj.v2.arr2[0] != 22 os.die(" obj.v1.arr1[0] != 22")
    if obj.v1.arr3[0] != 33 os.die(" obj.v1.arr1[0] != 33")
    fmt.println("test chain expr success")
}

class Cc2 {
    arr1 = []
    arr2 = []
}
class Cc3 {
    v1 = null
    v2 = null
    v3
    v4
}

class Cc1 {
    v1 
    v2
}
Cc1::init(){
    this.v1 = new Cc2()
    this.v2 = new Cc3()
}

fn tcd1(){
    return 11,"22",33
}
fn tcd2(){
    return "44"
}
fn test_chain2(){
    fmt.println("test chain2 expr ")

    obj = new Cc1()
    //eq
    obj.v1.arr1[] ,
    obj.v2.v2 ,
    obj.v1.arr2[] = tcd1()
    if obj.v1.arr1[0] != 11 os.die("obj.v1.arr1[0] != 11")
    if obj.v2.v2 != "22" os.die("obj.v1.arr1[0] != 22")
    if obj.v1.arr2[0] != 33 os.die("obj.v1.arr1[0] != 33")
    //little
    obj.v1.arr1[],obj.v2.v1 = tcd1()
    if obj.v1.arr1[1] != 11 os.die("obj.v1.arr1[1] != 11")
    if obj.v2.v1 != "22" os.die("obj.v1.arr1[0] != 22")
    //over
    obj.v1.arr2[],
    obj.v2.v2,
    obj.v2.v3,
    obj.v2.v4 = tcd1()
    if obj.v1.arr2[1] != 11 os.die("obj.v1.arr2[1] != 11")
    if obj.v2.v2 != "22" os.die("obj.v2.v2 != 22")
    if obj.v2.v3 != 33 os.die("obj.v2.v2 != 33")
    if obj.v2.v4 != null os.die("obj.v2.v4 != null")

    obj.v1.arr1[],obj.v1.arr2[] = tcd2()
    if obj.v1.arr1[2] != "44" os.die("!= 44")
    if obj.v1.arr2[2] != null os.die("!= null")

    obj.v2.v1,obj.v2.v2 = tcd2()
    if obj.v2.v1 != "44" os.die("obj.v2.v1 != 44")
    if obj.v2.v2 != null os.die("obj.v2.v2 != null")
    fmt.println("test chain2 expr success")
}
//----------------------common
fn ta1(a,b){
    return 11.(i32),22.(i32),33.(i32)
}
fn test_argsl(){
    fmt.println("test argsl")
    v1<i32> , v2<i32>,v3<i32> = ta1(1.(i32))
    if v1 != 11  os.die("v1 != 11")
    if v2 != 22  os.die("v2 != 22")
    if v3 != 33  os.die("v3 != 33")
    fmt.println("test argsl success")
}

fn ta2(a,b){
    return 11.(i32),22.(i32),33.(i32)
}
fn test_argsg(){
    fmt.println("test argsg")
    v1<i32> , v2<i32>,v3<i32> = ta2(1.(i32),2.(i32),3.(i32))
    if v1 != 11  os.die("v1 != 11")
    if v2 != 22  os.die("v2 != 22")
    if v3 != 33  os.die("v3 != 33")
    fmt.println("test argsg success")
}
fn tav_1(a<i32>,b<u64*>...){
    if a != 1 os.die("a != 1")
    if b[0] != 2 os.die("b[0] != 2")
    b += 8
    if b[0] != 2 os.die("b[0] != 2")
    if b[1] != 3 os.die("b[1] != 3")
    return 11.(i32),22.(i32)
}
fn test_argsv_withvariadic(a<i32>,args<u64*>...){
    fmt.println("test argsv variadic")
    if a != 1 os.die("a != 1")
    if args[0] != 2 os.die("args[0] != 2")
    if args[1] != 2 os.die("args[1] != 2")
    if args[2] != 3 os.die("args[2] != 3")

    v1<i32>,v2<i32> = tav_1(a,args)
    if v1 != 11 os.die("v1 != 11")
    if v2 != 22 os.die("v2 != 22")

    tav_1(a,args)
    fmt.println("test argsv with variadic success")
}
fn tav2_eq(a<i32>,b<u64*>...){
    if a != 1 os.die("eq a != 1")
    if b[0] != 1 os.die("eq b[0] != 1")
    if b[1] != 2 os.die("eq b[1] != 2")
    return 11.(i32),22.(i32)
}
fn tav2_over(a<i32>,b<u64*>...){
    if a != 1 os.die("over a != 1")
    if b[0] != 2 os.die("over b[0] != 1")
    if b[1] != 2 os.die("over b[1] != 2")
    if b[2] != 3 os.die("over b[2] != 3")
    return 11.(i32),22.(i32)
}
fn tav2_miss(a<i32>,b<u64*>...){
    if a != 1 os.die("over a != 1")
    if b[0] != 0 os.die("miss b[0] != 0")
    return 11.(i32),22.(i32)
}
fn test_argsv(){
    fmt.println("test argsv")
    //eq
    v1<i32>,v2<i32> = tav2_eq(1.(i32),2.(i32))
    if v1 != 11 os.die("v1 != 11")
    if v2 != 22 os.die("v2 != 22")
    tav2_eq(1.(i32),2.(i32))

    //over
    v1,v2 = tav2_over(1.(i32),2.(i32),3.(i32))
    if v1 != 11 os.die("v1 != 11")
    if v2 != 22 os.die("v2 != 22")
    tav2_over(1.(i32),2.(i32),3.(i32))
    //miss
    v1,v2 = tav2_miss(1.(i32))
    if v1 != 11 os.die("v1 != 11")
    if v2 != 22 os.die("v2 != 22")
    tav2_miss(1.(i32))

    fmt.println("test argsv success")
}

fn main(){
    test_objmember()
    test_memvar()
    test_dynvar()

    test_index()
    test_index2()

    test_struct()
    test_class()
    test_chain()
    test_chain2()

    test_argsl()
    test_argsg()
    test_argsv_withvariadic(1.(i32),2.(i32),3.(i32))
    test_argsv()
}
