
use fmt
use std
use os

func test_open_read(){
    fmt.println("test open/read dir")

    fd = std.opendir("./dir")
    while true {
        file = std.readdir(fd)
        if !file break

        match file.name {
            "a" : fmt.assert(file.type,"file","a should be file")
            "b" : fmt.assert(file.type,"file","b should be file")
            "." : fmt.assert(file.type,"directory", ". should be directory")
            "..": fmt.assert(file.type,"directory",".. should be directory")
            _   : os.die("should be a,b,.,..")
        }
        fmt.println(file.name,file.type)
    }
    fmt.println("test open/read dir passed")
}
func test_tell(){
    fmt.println("test is_dir && is_file")
    if !std.is_dir("./dir") {
        os.die("./dir should be directory")
    }
    if std.is_dir("./dir1") {
        os.die("./dir1 not exist")
    }
    if !std.is_file("./std_dir.tu") {
        os.die("./std_dir.tu is file")
    }
    if std.is_file("./std_dir.tu1") {
        os.die("./std_dir.tu1 not exist")
    }

    //test file or directory
    if std.is_dir("./std_dir.tu") {
        os.die("./std_dir.tu is file")
    }
    fmt.println("test is_dir && is_success")
}
func main(){
    test_open_read()
    test_tell()
}