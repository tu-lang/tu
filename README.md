<p>
<!--<img alt="GitHub" src="https://img.shields.io/github/license/tu-lang/tu">-->
<img alt="GitHub code size in bytes" src="https://img.shields.io/github/languages/code-size/tu-lang/tu">
</p>

tu-lang(凸）是一种编程语言，旨在创造一种非常简单的零依赖(no glibc)动态&&静态语言,全静态链接，已屏蔽了基于c/c++实现的compiler、asmer、linker，目前正在自举中...
```asciidoc
tu      [options] file.tu        
    -s    file  ast -> asm       编译.tu代码 生成.s汇编文件
    -run  file  ast -> asm       基于gcc编译链接后运行(no libc)
    -p    file                   打印token
    -g                           段错误时打印详细栈信息
ta      [options] file.s        
    -c    file.s  -> file.tu      编译.s自定义汇编语言,翻译机器码并生成.o elf|pe/coff文件
    -p    path path...           批量扫描目录编译.s文件生成.o elf文件
    -print                       打印token
tl      [options|file.o...] 
    -p    path ... -> a.out      指定多个目录,自动扫描所有.0文件进行链接生成可执行程序
    file.o  ...-> a.out          指定多个file.o进行链接    
```
## @自举进度
更多语法测试用例在`/tests`目录下，包含了各种数据结构、运算、gc、demo测试

- [ ] tu(compiler)
  - [x]     自举代码编译成功
  - [x] run 自动编译链接后执行
  - [x] -s  编译为低等级汇编码
- [ ] ta(asmer)
  - [ ] -c  翻译指定汇编码为linux(elf),windows(pe/coff)
  - [ ] -p  批量扫描路径下的汇编
- [x] tl([linker/demo](./linker))
  - [x] *.o 链接指定的linux(elf) 文件生成可执行linux程序
  - [ ] *.o 链接指定的windows(pe) 文件生成可执行windows程序
  - [ ] *.o 链接指定的mac(MachO) 文件生成可执行mac程序
  - [x] -p  链接指定目录生成可执行程序
- [x] runtime
  - [x] garbage collect
  - [x] standard library
  - [x] syscall
  - [x] stack unwind
 
  
## env & install & tests 
`NOTICE`:environment install first
```asciidoc
....
> sh tests_compiler.sh
> sh tests_asmer.sh
> sh tests_linker.sh

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