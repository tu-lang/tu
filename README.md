<p>
<!--<img alt="GitHub" src="https://img.shields.io/github/license/tu-lang/tu">-->
<img alt="GitHub code size in bytes" src="https://img.shields.io/github/languages/code-size/tu-lang/tu">
</p>

tu-lang(凸）是一种编程语言，旨在创造一种非常简单的零依赖(no glibc)动态&&静态语言,全静态链接，已屏蔽了基于c/c++实现的compiler、asmer、linker，`目前已自举完成: compiler纯动态语法，asmer纯静态语法，linker动静混合语法`.
```
tu  [options] file.tu        
    build *.tu              编译成汇编后进行链接生成二进制可执行文件
    -s  *.tu|dir            编译为tulang代码为linux-amd64汇编文件
    -c  *.s |dir            编译汇编为elf&pecoff跨平台可重定向cpu指令集文件
    -o  *.o |dir            链接elf&pecofff可重定向文件生成最终执行程序
    -d                      开启trace日志打印编译详细过程
    -gcc                    支持通过gcc链接生成最终可执行程序
    -g                      编译tu文件时带上debug段信息,支持栈回溯
    -std                    编译runtime&std相关内置库代码
```
## demo
![gif](./assets/tulang.gif)
  
## env & install
`linux`: 环境安装
```asciidoc
$ git clone https://github.com/tu-lang/tu.git
$ cd tu
$ make install
```
## compiler&asmer&linker测试
更多语法测试用例在`/tests`目录下，包含了各种数据结构、运算、gc、demo测试
- 单元测试
```
> sh tests_compiler.sh
> sh tests_asmer.sh
> sh tests_linker.sh
> make test -j10 //并发测试
```

## @数据结构
- [x] 动态类型 int string bool null array map closure object
- [x] 原生类型 pointer i8 u8 i16 u16 i32 u32 i64 i64 struct
```
use fmt
class Http{
    # member
    request
    func handler(){
        fmt.println("hello world!",this.request)
    }
}
Http::closure(){
    return func(){
        return ["arr1","arr2",3,4]
    }
}
func main(){
    a = "this is a string" #string
    fmt.println(a)
    a = 1000 # int
    fmt.println(a)
    a = ["1",2,"33",4,"some string word"] #array
    fmt.print(a[0],a[1],a[2],a[3],a[4]) #or fmt.print(a)
    b = {"sdfds":"sdfsd",1:2,"sdfds":3,"a":a} #map
    fmt.print(b["a"],b["sdfds"])
    obj = new Http() #object
    obj.request = {"method":"POST"}
    obj.handler()
    cfunc = obj.closure() #closure
    fmt.println(cfunc())
}
```
## @关键字
- [x] func(函数定义),goto(代码跳转),class(动态class),mem(原生结构体)
- [x] return,type,use,if,continue,break
- [x] while,for|range for,loop
- [x] match

```
use fmt
use os
func main(){
    arr = [0,1,2,3,4]
    map = {"1":"a","hello":"world","2":"b",3:"c","map":arr}
    for( k,v : map)
    {
        if k == "map" {
            for(v2 : v){}
        }
        fmt.println(k,v)
    }

    match map["hello"] {
        arr[0] : os.die("not this one")
        999    : os.die("not this one")

        "hello" | "world": {
            fmt.println("got it",map["hello"])
        }
        _      : {
            os.die("not default")
        }
    }
}
```
## License
Copyright @2016-2022 The tu-lang author. All rights reserved.
