use fmt
use std
use string
use os

class Con {
  arr
  map
}
Con::test_inner(){
  fmt.println("test_inner")
  if this.arr[1] != 23 os.die("this.arr[1] should eq 23")
  if this.map["sec"] != 24 os.die("this.map[sec] should eq 24")

  fmt.println("test_inner success " + this.arr)

}
//测试直接访问成员数组,map
func test_local(obj){
  fmt.println("test_local")
  if obj.arr[1] != 23 os.die("obj.arr[1] should eq 23")
  if obj.map["sec"] != 24 os.die("obj.map[sec] should eq 24")
  fmt.println("test_local success" + obj.arr)
}

gvar = new Con()
func test_global(){
  gvar.arr = [0,1,2]
  for k,v : gvar.arr {
    if k != v os.die(
      fmt.sprintf("kv:%d should be v:%d",k,v)
    )
  }
  if 0 != gvar.arr[0] os.die("gvar.arr[0] != 0")
  gvar.arr[1] = 11
  if 11 != gvar.arr[1] os.die("gvar.arr[1] != 11")
  if 2 != gvar.arr[2] os.die("gvar.arr[2] != 2")
  fmt.println("test global var object member access success")
}
func main(){
  obj = new Con() 
  obj.arr = [1,23]
  obj.map = {"fir":23,"sec":24,"arr":obj.arr}
  test_local(obj)
  obj.test_inner()

  test_global()
}
