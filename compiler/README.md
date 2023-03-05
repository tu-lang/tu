基于tu-lang自举 compiler 编译器

# 环境准备
```
> cd tu-lang
> make install-bin
```
# 编译测试
```
> vim hello.tu
use fmt
func main(){
    fmt.println("hello tulang")
}
> tu run hello.tu
```
![image](../assets/compiler_helloworld.png#w50)

# 自举测试
```
> cd tu-lang
> cd compiler
> tu run main.tu
```
![image](../assets/compiler_compiler.png#w50)