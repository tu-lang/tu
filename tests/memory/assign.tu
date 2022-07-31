
use fmt
use os

mem Test
{
	i8  a,b
	i16 c
	u32 d,e,f
	i64 g,h
}
func i8_assign(p<Test>){
	p.a = 100
	fmt.assert(int(p.a),100)

	p.b = 100
	fmt.assert(int(p.b),100)
	fmt.println("test i8_assign successful")
}
func plus_agan(p<Test>){
	p.a = 0
	for(i = 1; i < 10 ; i += 1){
		p.a += 1
		fmt.assert(int(p.a),i)
	}
	fmt.println(" pulus_agan success")
}
func main(){
	p<Test> = new Test
	plus_agan(p)
	i8_assign(p)
}