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

func main(){
  obj = new Con() 
  obj.arr = [1,23]
  obj.map = {"fir":23,"sec":24,"arr":obj.arr}
  test_local(obj)
  obj.test_inner()
}
