基于tu-lang自举实现的tol链接器,0依赖glibc,目前已支持任意amd64-linux下的编译执行，见:`linker/bin/amd64_bin`
- [x] amd64
    - [x] linux
    - [ ] mac
    - [ ] windows

# 链接测试demo
```
$ cd linker/demo
$ tu -c .
```
链接生成可执行文件生成可执行文件
```
$ cd linker
$ ./bin/amd64_linux_tl1 -p ./demo # v1 基于std.malloc版编译,比较慢
$ chmod 777 a.out

$ ./bin/amd64_linux_tl2 -p ./demo # v2 基于高性能版runtime.malloc版编译,非常快
$ chmod 777 a.out

$ ./a.out
> hello tu-lang!
```
![image](./asserts/linker-demo.png#w50)

# 自举测试
![image](./asserts/linker-compile.png#w50)