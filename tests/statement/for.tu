
use fmt
use time
use os


func test_tri_for(){
    arr = []
    for(a = 1 ; a < 10 ; a += 2){
        arr[] = a
    }
    i = 0
    for(a = 1 ; a < 10 ; a += 2){
        if  arr[i] != a {
            fmt.printf("failed arr[i]:%d should be %d \n",i,a)
            os.exit(1)
        }
        fmt.printf("arr[%d]=%d a=%d\n",i,arr[i],a)
        i += 1
    }
    fmt.println("test for statment passed!")
}

fn test_for_range_break(){
    fmt.println("test for range break")
    state = 2
    arr = [1,2,3]
    v = null
    v2 = null
    match state {
        1 : {
            state_1:
            fmt.println("state_1:",v,v2)
            fmt.println("out:", v)
            goto state_4
        }
        2 : {
            state_2:
            fmt.println("state_2:",v,v2)
            for v : arr {
                goto state_1
                main_continue00:
            }
        }
        4 : {
            state_4:
            fmt.println("state_4:",v,v2)
            for v2 : arr {
                fmt.println("state_3:",v,v2)
                goto main_end11
            }
            main_end11:
            goto main_continue00
        }
    }
    fmt.println("test for range break sucess ")
}


fn main(){
    test_tri_for()
    test_for_range_break()
}