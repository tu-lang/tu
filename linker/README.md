基于tu-lang自举实现的tol链接器,0依赖glibc,目前已支持任意amd64-linux下的编译执行，见:`linker/bin/amd64_bin`
- [x] amd64
    - [x] linux
    - [ ] mac
    - [ ] windows

# 链接测试demo
因为compiler和asmer还未自举完成，目前需要靠gcc生成elf对象文件
```
$ cd linker/demo
$ gcc -c *.s -static -nostdlib -e main
```
链接生成可执行文件生成可执行文件
```
$ cd linker
$ ./bin/amd64_linux -p ./demo
$ chmod 777 a.out

$ ./a.out
> hello tu-lang!
```
![image](./asserts/linker-demo.png#w50)

# 自举测试
![image](./asserts/linker-compile.png#w50)