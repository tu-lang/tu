
func test_while(){
    a = 4
    while a != 2 {
        a = a - 1
    }
}
func test_dead_while(){
    i = 1
    loop {
        if i == 10 break
        i += 1
    }
}

func main(){
    test_while()
    test_dead_while()
}