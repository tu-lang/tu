use fmt
use string

fn test_base(){
    fmt.println("test base")
    f1 = 123.456
    fmt.print(f1)
    f2 = 456.123
    arr = [f1,f2]
    fmt.println(arr[0])
    if arr[0] == f1 {} else os.die("arr[0] != f1")
    //map
    map = {f1:f2}
    fmt.println("map[f1]:",map[f1])
    if map[f1] == f2 {} else os.die("map[f1] != f2")
    map[f2] = f1
    if map[f1] == f2 {} else os.die("map[f1] != f2")
    //string
    str = string.tostring(f1)
    fmt.println(str)
    if str == "123.45600" {} else os.die("str != 123.45600")
    //number
    nstr = "56787.432"
    n64 = string.tonumber(nstr)
    fmt.println(n64)
    if n64 == 56787 {} else os.dief("!= 56787")
    nf64 = string.tofloat(nstr)
    fmt.println("float:",nf64)
    nf64str = string.tostring(nf64)
    fmt.println(nf64str)
    if nf64str == "56787.43200" {} else os.dief("!= 56787.43200")

    arr = [f1,f2,1,2,3]
    fmt.println(arr)
    //+ - * /
    v1 = 1000.112 + 1000.223
    fmt.println(string.tostring(v1))
    if string.tostring(v1) == "2000.33500" {} else os.die("v1 != 2000.3350")
    v1 = 200 + 1000.111
    fmt.println(v1)
    if string.tostring(v1) == "1200.11099" {} else os.die("v1 != 1200.1110")
    v1 = 1000.111 + 200 
    fmt.println(v1)
    if string.tostring(v1) == "1200.11099" {} else os.die("v1 != 1200.1110")

    v1 = 888.222 - 666.111
    fmt.println(string.tostring(v1))
    if string.tostring(v1) == "222.11099" {} else os.die("v1 != 222.111")
    v1 = 888.222 - 333
    fmt.println(string.tostring(v1))
    if string.tostring(v1) == "555.22199" {} else os.die("v1 != 555.22200")
    v1 = 888 - 333.222
    fmt.println(string.tostring(v1))
    if string.tostring(v1) == "554.77800" {} else os.die("v1 != 554.77800")

    v1 = 100.33 * 200.22
    fmt.println(string.tostring(v1))
    if string.tostring(v1) == "20088.07259" {} else os.die("v1 != 20088.07259")
    v1 = 100 * 200.22
    fmt.println(string.tostring(v1))
    if string.tostring(v1) == "20022.00000" {} else os.die("v1 != 20022,00000")
    v1 = 200.22 * 100 
    fmt.println(string.tostring(v1))
    if string.tostring(v1) == "20022.00000" {} else os.die("v1 != 20022.00000")

    v1 = 99.33 / 3.3
    fmt.println(string.tostring(v1))
    if string.tostring(v1) == "30.10000" {} else os.die("v1 != 30.10000")
    v1 = 99.33 / 3
    fmt.println(string.tostring(v1))
    if string.tostring(v1) == "33.10999" {} else os.die("v1 != 33.11000")
    v1 = 100 / 3.3
    fmt.println(string.tostring(v1))
    if string.tostring(v1) == "30.30303" {} else os.die("v1 != 30.30303")
    // == !=  > >= < <=
    if 1.12 == 1.12 {} else os.dief("1.12 != 1.12")
    if 1.12 != 1.12 os.dief("1.12 == 1.12")
    if 1.13 != 2.23 {} else os.dief("1.13 != 2.23")
    if 4.12 > 4.10 {} else os.dief("4.12 > 4.10")
    if 4.12 > 4.15 os.dief("4.12 > 4.15")
    if 4.12 >= 4.12 {} else os.dief("4.12 >= 4.12")
    if 5.33 < 5.44 {} else os.dief("5.33 < 5.44")
    if 5.33 < 5.30 os.dief("5.33 < 5.30")
    if 5.33 <= 5.33 {} else os.dief("5.33 <= 5.33")
    // if true 
    if 0.0 os.dief("if 0.0")
    if 1.1 {} else os.dief("if 1.1")

    fmt.println("test base success")
}

fn main(){
    test_base()
}