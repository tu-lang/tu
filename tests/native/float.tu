use string
// base op
//<< <<= >> >>= , & ,|, ^, !=, ~
//== != > >=, < <=, || , &&
//+ +=, - -=, * *=,/ /=
//*pointer
// mem op
fn test_base1(){
	fmt.println("test_base1 double to string")
	//1.test 34723453.23453264 
	s<string.String> = string.f64tostring(4719929312858361058.(u64))
	fmt.println(s.dyn())
	if s.dyn() == "34723453" {} else {
		os.dief("%s should be 34723453",s.dyn())
	}
	//2. 123457.76543210
	s = string.f64tostring(4683220366250064589.(u64),8.(i8))
	fmt.println(s.dyn())
	if s.dyn() == "123457.76543210" {} else {
		os.dief("%s should be 123457.76543210",s.dyn())
	} 
	//3. 0.3456789
	s = string.f64tostring(4599898817378825292.(u64),7.(i8))
	fmt.println(s.dyn())
	if s.dyn() == "0.3456789" {} else {
		os.dief("%s should be 0.3456789",s.dyn())
	} 
	//3. 0.000001 ~= 0.0000009999
	s = string.f64tostring(4517329193108106637.(u64),10.(i8))
	fmt.println(s.dyn())
	if s.dyn() == "0.0000009999" {} else {
		os.dief("%s should be 0.0000009999",s.dyn())
	} 
	//4. 1.222222  ~= 1.222221
	s = string.f64tostring(4608183217716410934.(u64),6.(i8))
	fmt.println(s.dyn())
	if s.dyn() == "1.222221" {} else {
		os.dief("%s should be 1.222221",s.dyn())
	} 	
	fmt.println("test_base1 double to string success")
}

fn test_base2(){//test conversion
    fmt.println("test_base2")
    //assign
    v<f32> = 0.45
    v2<f64> = v //f32 - f64
	s<string.String> = string.f64tostring(v2,2.(i8))
	fmt.println(s.dyn())
    if s.dyn() == "0.44" {} else {
        os.dief("%s != 0.44",s.dyn())
    }
	//pointer
	vf3<f64> = *tb_v2p
	s = string.f64tostring(vf3,2.(i8))
	fmt.println(s.dyn())
	if s.dyn() == "1234567.87" {} else {
		os.dief("%s != 1234567.87",s.dyn())
	}

	l_v1<f64> = 87654321.123456
	l_v1p<i64*> = &l_v1
	l_v2<i64> = *l_v1p
	l_v2p<f64*> = &l_v2
	vf3 = *l_v2p
	s = string.f64tostring(vf3,4.(i8))
	fmt.println(s.dyn())
	if s.dyn() == "87654321.1234" {} else {
		os.dief("%s != 87654321.1234",s.dyn())
	}
    fmt.println("test_base2 success")
}
tb_v1<f64> = 1234567.876
tb_v1p<i64*> = &tb_v1
tb_v2<i64> = *tb_v1p
tb_v2p<f64*> = &tb_v2
fn test_bitop(){
    fmt.println("test bit op")
    v<f32> = 91.45
    v1<i32> = !v
    v2<f64> = !v
	s<string.String> = string.f64tostring(v2,2.(i8))
	if s.dyn() == "0.00" {} else {
		os.dief("should be 0 %s",s.dyn())
	}
	v = 0.0
	v1 = !v
	int8<i8> = v1
	if int8 == 1 {} else {
		os.die("i8 should be 1")
	}
	int64<i64> = v1
	if int64 == 1 {} else {
		os.die("i64 should be 1")
	}
	
    fmt.println("test bit op success")
}
fn test_add(){
	fmt.println("test_add")
	vf32<f32> = 221221.222
	vf64<f64> = 88888888888.33333
	vi32<i32> = -2004318071
	vu32<u32> = 0x77777777 
	vi64<i64> = -9223372036854775808
	vu64<u64> = 0x88888888888888
	//f32 i32 
	r<f64> = vf32 + vi32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-2004096896.0000" {} else {
		os.dief("%s != -2004096896.000",rs.dyn())
	}
	r = vi32 + vf32
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-2004096896.0000" {} else {
		os.dief("%s != -2004096896.0000",rs.dyn())
	}
	//f32 u32
	r = vf32 + vu32
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "2004539264.0000" {} else {
		os.dief("%s != 2004539264.0000",rs.dyn())
	}
	r = vu32 + vf32 
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "2004539264.0000" {} else {
		os.dief("%s != 2004539264.0000",rs.dyn())
	}
	//f32 i64
	r = vf32 + vi64
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-9223372036854775808.0000" {} else {
		os.dief("%s != -9223372036854775808.0000",rs.dyn())
	}
	r = vi64 + vf32
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-9223372036854775808.0000" {} else {
		os.dief("%s != -9223372036854775808.0000",rs.dyn())
	}
	//f32 u64
	r = vf32 + vu64
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "38430718824546304.0000" {} else {
		os.dief("%s != 38430718824546304.0000",rs.dyn())
	}
	r = vu64 + vf32 
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "38430718824546304.0000" {} else {
		os.dief("%s != 38430718824546304.0000",rs.dyn())
	}
	//f64 i32
	r = vf64 + vi32
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "86884570817.3333" {} else {
		os.dief("%s != 86884570817.3333",rs.dyn())
	}
	r = vi32 + vf64
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "86884570817.3333" {} else {
		os.dief("%s != 86884570817.3333",rs.dyn())
	}
	//f64 u32
	r = vf64 + vu32
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "90893206959.3333" {} else {
		os.dief("%s != 90893206959.3333",rs.dyn())
	}
	r = vu32 + vf64
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "90893206959.3333" {} else {
		os.dief("%s != 90893206959.3333",rs.dyn())
	}
	//f64 i64
	r = vf64 + vi64
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-9223371947965886464.0000" {} else {
		os.dief("%s != -9223371947965886464.0000",rs.dyn())
	}
	r = vi64 + vf64
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-9223371947965886464.0000" {} else {
		os.dief("%s != -9223371947965886464.0000",rs.dyn())
	}
	//f64 u64
	r = vf64 + vu64
	rs= string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "38430805709117120.0000" {} else {
		os.dief("%s != 38430805709117120.0000",rs.dyn())
	}
	r = vu64 + vf64
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "38430805709117120.0000" {} else {
		os.dief("%s != 38430805709117120.0000",rs.dyn())
	}
	//f32 f32
	r = vf32 + vf32
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "442442.4375" {} else {
		os.dief("%s != 442442.4375",rs.dyn())
	}
	//f32 f64
	r = vf32 + vf64
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "88889110109.5520" {} else {
		os.dief("%s != 88889110109.5520",rs.dyn())
	}
	r = vf64 + vf32
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "88889110109.5520" {} else {
		os.dief("%s != 88889110109.5520",rs.dyn())
	}
	//f64 f64
	r = vf64 + vf64
	rs = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "177777777776.6666" {} else {
		os.dief("%s != 177777777776.6666",rs.dyn())
	}

	//f32 = f32 i64
	r_<f32> = vf32 + vi64
	r2<f64> = r_
	rs<string.String> = string.f64tostring(r2,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-9223372036854775808.0000" {} else {
		os.dief("%s != -9223372036854775808.0000",rs.dyn())
	}

	fmt.println("test_add success")
}

fn test_sub(){
	fmt.println("test_sub")
	vf32<f32> = 221221.222
	vf64<f64> = 88888888888.33333
	vi32<i32> = -2004318071
	vu32<u32> = 0x77777777 
	vi64<i64> = -9223372036854775808
	vu64<u64> = 0x88888888888888
	//f32 i32 
	r<f64> = vf32 - vi32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "2004539264.0000" {} else {
		os.dief("%s != 204539264.0000",rs.dyn())
	}
	r<f64> = vi32 - vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-2004539264.0000" {} else {
		os.dief("%s != -204539264.0000",rs.dyn())
	}
	//f32 u32
	r<f64> = vf32 - vu32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-2004096896.0000" {} else {
		os.dief("%s != -2004096896..0000",rs.dyn())
	}
	r<f64> = vu32 - vf32 
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "2004096896.0000" {} else {
		os.dief("%s != 2004096896.0000",rs.dyn())
	}
	//f32 i64
	r<f64> = vf32 - vi64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "9223372036854775808.0000" {} else {
		os.dief("%s != 9223372036854775808.0000",rs.dyn())
	}
	r<f64> = vi64 - vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-9223372036854775808.0000" {} else {
		os.dief("%s != -9223372036854775808.0000",rs.dyn())
	}
	//f32 u64
	r<f64> = vf32 - vu64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-38430718824546304.0000" {} else {
		os.dief("%s != -38430718824546304.0000",rs.dyn())
	}
	r<f64> = vu64 - vf32 
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "38430718824546304.0000" {} else {
		os.dief("%s != 38430718824546304.0000",rs.dyn())
	}
	//f64 i32
	r<f64> = vf64 - vi32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "90893206959.3333" {} else {
		os.dief("%s != 90893206959.3333",rs.dyn())
	}
	r<f64> = vi32 - vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-90893206959.3333" {} else {
		os.dief("%s != -90893206959.3333",rs.dyn())
	}
	//f64 u32
	r<f64> = vf64 - vu32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "86884570817.3333" {} else {
		os.dief("%s != 86884570817.3333",rs.dyn())
	}
	r<f64> = vu32 - vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-86884570817.3333" {} else {
		os.dief("%s != -86884570817.3333",rs.dyn())
	}
	//f64 i64
	r<f64> = vf64 - vi64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "9223372125743665152.0000" {} else {
		os.dief("%s != 9223372125743665152.0000",rs.dyn())
	}
	r<f64> = vi64 - vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-9223372125743665152.0000" {} else {
		os.dief("%s != -9223372125743665152.0000",rs.dyn())
	}
	//f64 u64
	r<f64> = vf64 - vu64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-38430627931339344.0000" {} else {
		os.dief("%s != -38430627931339344.0000",rs.dyn())
	}
	r<f64> = vu64 - vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "38430627931339344.0000" {} else {
		os.dief("%s != 38430627931339344.0000",rs.dyn())
	}
	//f32 f32
	r<f64> = vf32 - vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "0.0000" {} else {
		os.dief("%s != 0.0000",rs.dyn())
	}
	//f32 f64
	r<f64> = vf32 - vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-88888667667.1145" {} else {
		os.dief("%s != -88888667667.1145",rs.dyn())
	}
	r<f64> = vf64 - vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "88888667667.1145" {} else {
		os.dief("%s != 88888667667.1145",rs.dyn())
	}
	//f64 f64
	r<f64> = vf64 - vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "0.0000" {} else {
		os.dief("%s != 0.0000",rs.dyn())
	}

	//f32 = f32 i64
	r_<f32> = vf32 - vi64
	r2<f64> = r_
	rs<string.String> = string.f64tostring(r2,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "9223372036854775808.0000" {} else {
		os.dief("%s != 9223372036854775808.0000",rs.dyn())
	}

	fmt.println("test_sub success")

}

fn test_mul(){
	fmt.println("test_mul")
	vf32<f32> = 5341.431
	vf64<f64> = 3064184521.33333
	vi32<i32> = -10
	vu32<u32> = 0x77
	vi64<i64> = -9223372036854775808
	vu64<u64> = 0x88888888888888
	//f32 i32 
	r<f64> = vf32 * vi32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-53414.3125" {} else {
		os.dief("%s != -53414.3125",rs.dyn())
	}
	r<f64> = vi32 * vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-53414.3125" {} else {
		os.dief("%s != -53414.3125",rs.dyn())
	}
	//f32 u32
	r<f64> = vf32 * vu32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "635630.3125" {} else {
		os.dief("%s != 635630.3125",rs.dyn())
	}
	r<f64> = vu32 * vf32 
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "635630.3125" {} else {
		os.dief("%s != 635630.3125",rs.dyn())
	}
	//f32 i64
	r<f64> = vf32 * vi64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-49266006727312325738496.0000" {} else {
		os.dief("%s != -49266006727312325738496.0000",rs.dyn())
	}
	r<f64> = vi64 * vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-49266006727312325738496.0000" {} else {
		os.dief("%s != -49266006727312325738496.0000",rs.dyn())
	}
	//f32 u64
	r<f64> = vf32 * vu64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "205275038585779650560.0000" {} else {
		os.dief("%s != 205275038585779650560.0000",rs.dyn())
	}
	r<f64> = vu64 * vf32 
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "205275038585779650560.0000" {} else {
		os.dief("%s != 205275038585779650560.0000",rs.dyn())
	}
	//f64 i32
	r<f64> = vf64 * vi32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-30641845213.3333" {} else {
		os.dief("%s != -30641845213.3333",rs.dyn())
	}
	r<f64> = vi32 * vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-30641845213.3333" {} else {
		os.dief("%s != -30641845213.3333",rs.dyn())
	}
	//f64 u32
	r<f64> = vf64 * vu32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "364637958038.6662" {} else {
		os.dief("%s != 364637958038.6662",rs.dyn())
	}
	r<f64> = vu32 * vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "364637958038.6662" {} else {
		os.dief("%s != 364637958038.6662",rs.dyn())
	}
	//f64 i64
	r<f64> = vf64 * vi64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-28262113829829073581107052544.0000" {} else {
		os.dief("%s != -28262113829829073581107052544.0000",rs.dyn())
	}
	r<f64> = vi64 * vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-28262113829829073581107052544.0000" {} else {
		os.dief("%s != -28262113829829073581107052544.0000",rs.dyn())
	}
	//f64 u64
	r<f64> = vf64 * vu64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "117758807624287805442621440.0000" {} else {
		os.dief("%s != 117758807624287805442621440.0000",rs.dyn())
	}
	r<f64> = vu64 * vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "117758807624287805442621440.0000" {} else {
		os.dief("%s != 117758807624287805442621440.0000",rs.dyn())
	}
	//f32 f32
	r<f64> = vf32 * vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "28530886.0000" {} else {
		os.dief("%s != 886.00000",rs.dyn())
	}
	//f32 f64
	r<f64> = vf32 * vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "16367130658779.3710" {} else {
		os.dief("%s != 16367130658779.3710",rs.dyn())
	}
	r<f64> = vf64 * vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "16367130658779.3710" {} else {
		os.dief("%s != 16367130658779.3710",rs.dyn())
	}
	//f64 f64
	r<f64> = vf64 * vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "9389226780778770432.0000" {} else {
		os.dief("%s != 9389226780778770432.0000",rs.dyn())
	}

	//f32 = f32 i64
	r_<f32> = vf32 * vi64
	r2<f64> = r_
	rs<string.String> = string.f64tostring(r2,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-49266006727312325738496.0000" {} else {
		os.dief("%s != -49266006727312325738496.0000",rs.dyn())
	}

	fmt.println("test_mul success")

}


fn test_div(){
	fmt.println("test_div")
	tmp<i32>  = 5
	vf32<f32> = 762.432
	vf64<f64> = 3031451.43112
	vi32<i32> = -20
	vu32<u32> = 0x100
	vi64<i64> = -8263505978427528
	vu64<u64> = 0x66666666666666

	r<f64> = tmp / 2.0
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "2.5000" {} else {
		os.dief("%s != 2.5000",rs.dyn())
	}

	//f32 i32 
	r<f64> = vf32 / vi32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-38.1216" {} else {
		os.dief("%s != -38.1216",rs.dyn())
	}
	r<f64> = vi32 / vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-0.0262" {} else {
		os.dief("%s != -0.0262",rs.dyn())
	}
	//f32 u32
	r<f64> = vf32 / vu32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "2.9782" {} else {
		os.dief("%s != 2.9782",rs.dyn())
	}
	r<f64> = vu32 / vf32 
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "0.3357" {} else {
		os.dief("%s != 0.3357",rs.dyn())
	}
	//f32 i64
	r<f64> = vf32 / vi64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-0.0000" {} else {
		os.dief("%s != -0.0000",rs.dyn())
	}
	r<f64> = vi64 / vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-10838351020032.0000" {} else {
		os.dief("%s != -10838351020032.0000",rs.dyn())
	}
	//f32 u64
	r<f64> = vf32 / vu64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "0.0000" {} else {
		os.dief("%s != 0.0000",rs.dyn())
	}
	r<f64> = vu64 / vf32 
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "37804075646976.0000" {} else {
		os.dief("%s != 37804075646976.0000",rs.dyn())
	}
	//f64 i32
	r<f64> = vf64 / vi32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-151572.5715" {} else {
		os.dief("%s != -151572.5715",rs.dyn())
	}
	r<f64> = vi32 / vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-0.0000" {} else {
		os.dief("%s != -0.0000",rs.dyn())
	}
	//f64 u32
	r<f64> = vf64 / vu32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "11841.6071" {} else {
		os.dief("%s != 11841.6071",rs.dyn())
	}
	r<f64> = vu32 / vf64
	rs<string.String> = string.f64tostring(r,5.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "0.00008" {} else {
		os.dief("%s != 0.00008",rs.dyn())
	}
	//f64 i64
	r<f64> = vf64 / vi64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-0.0000" {} else {
		os.dief("%s != -0.0000",rs.dyn())
	}
	r<f64> = vi64 / vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-2725923923.3051" {} else {
		os.dief("%s != -2725923923.3051",rs.dyn())
	}
	//f64 u64
	r<f64> = vf64 / vu64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "0.0000" {} else {
		os.dief("%s != 0.0000",rs.dyn())
	}
	r<f64> = vu64 / vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "9507999144.9911" {} else {
		os.dief("%s != 9507999144.9911",rs.dyn())
	}
	//f32 f32
	r<f64> = vf32 / vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "1.0000" {} else {
		os.dief("%s != 1.0000",rs.dyn())
	}
	//f32 f64
	r<f64> = vf32 / vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "0.0002" {} else {
		os.dief("%s != 0.0002",rs.dyn())
	}
	r<f64> = vf64 / vf32
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "3976.0285" {} else {
		os.dief("%s != 3976.0285",rs.dyn())
	}
	//f64 f64
	r<f64> = vf64 / vf64
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "1.0000" {} else {
		os.dief("%s != 1.0000",rs.dyn())
	}

	//f32 = f32 i64
	r_<f32> = vf32 / vi64
	r2<f64> = r_
	rs<string.String> = string.f64tostring(r2,40.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "-0.0000000000000922649543572129360313738288" {} else {
		os.dief("%s != -0.0000000000000922649543572129360313738288",rs.dyn())
	}

	fmt.println("test_div success")

}

//== != > >= < <=

fn test_cond(){
	fmt.println("test_cond")
	vf32<f32> = 123.456
	vf32e<f32> = 123.0
	vf64<f64> = 123456789.123
	vf64e<f64> = 123456789.0
	vi32<i32> = -123
	vu32<u32> = 123
	vi64<i64> = -123456789
	vu64<u64> = 123456789

	//f32 i32 
	if vf32 == vi32 os.dief("vf32 == i32 failed")
	if vi32 == vf32 os.dief("i32 == vf32 failed")
	if vf32 != vi32 {} else os.dief("vf32 != i32 failed")
	if vi32 != vf32 {} else os.dief("i32 != vf32 failed")

	if vf32 > vi32 {} else os.dief("vf32 > vi32 failed")
	if vi32 >  vf32 os.dief("vi32 > vf32 failed")
	if vf32 >= vi32 {} else os.dief("vf32 >= vi32 failed")
	if vi32 >=  vf32 os.dief("i32 > i32 failed")
	if vu32 > vf32e  os.dief("vu32 > vf32e failed")
	if vu32 >= vf32e {} else os.dief("vu32 >= vf32e failed")

	if vf32 < vi32 os.dief("vf32 < i32 failed")
	if vi32 <  vf32 {} else os.dief("vi32 > i32 failed")
	if vf32 <= vi32 os.dief("vf32 <= i32 failed")
	if vi32 <=  vf32 {} else os.dief("vi32 <= vfi32 failed")
	if vf32 < vf32e  os.dief("vf32 < vf32e failed")
	if vf32 <= vf32e  os.dief("vf32 <= vf32e failed")

	//f32 u32
	if vf32 == vu32 os.dief("vf32 == u32 failed")
	if vu32 == vf32 os.dief("u32 == vf32 failed")
	if vf32 != vu32 {} else os.dief("vf32 != u32 failed")
	if vu32 != vf32 {} else os.dief("u32 != vf32 failed")

	if vf32 > vu32 {} else os.dief("vf32 > u32 failed")
	if vu32 >  vf32 os.dief("vf32 > u32 failed")
	if vf32 >= vu32 {} else os.dief("vf32 > u32 failed")
	if vu32 >=  vf32 os.dief("u32 > u32 failed")
	if vf32 > vf32e  {} else os.dief("vf32 > vf32e failed")
	if vf32 >= vf32e {} else os.dief("vf32 >= vf32e failed")

	if vf32 < vu32 os.dief("vf32 < u32 failed")
	if vu32 <  vf32 {} else os.dief("vu32 > u32 failed")
	if vf32 <= vu32 os.dief("vf32 <= u32 failed")
	if vu32 <=  vf32 {} else os.dief("vu32 <= vfi32 failed")
	if vf32 < vf32e  os.dief("vf32 < vf32e failed")
	if vf32 <= vf32e os.dief("vf32 <= vf32e failed")

	//f32 i64
	if vf32 == vi64 os.dief("vf32 == i64 failed")
	if vi64 == vf32 os.dief("i64 == vf32 failed")
	if vf32 != vi64 {} else os.dief("vf32 != i64 failed")
	if vi64 != vf32 {} else os.dief("i64 != vf32 failed")

	if vf32 > vi64 {} else os.dief("vf32 > i64 failed")
	if vi64 >  vf32 os.dief("vf32 > i64 failed")
	if vf32 >= vi64 {} else os.dief("vf32 > i64 failed")
	if vi64 >=  vf32 os.dief("i64 > i64 failed")
	if vf32 > vf32e  {} else os.dief("vf32 > vf32e failed")
	if vf32 >= vf32e {} else os.dief("vf32 >= vf32e failed")

	if vf32 < vi64 os.dief("vf32 < i64 failed")
	if vi64 <  vf32 {} else os.dief("vi64 > i64 failed")
	if vf32 <= vi64 os.dief("vf32 <= i64 failed")
	if vi64 <=  vf32 {} else os.dief("vi64 <= vfi64 failed")
	if vf32 < vf32e  os.dief("vf32 < vf32e failed")
	if vf32 <= vf32e os.dief("vf32 <= vf32e failed")

	//f32 u64
	if vf32 == vu64 os.dief("vf32 == u64 failed")
	if vu64 == vf32 os.dief("u64 == vf32 failed")
	if vf32 != vu64 {} else os.dief("vf32 != u64 failed")
	if vu64 != vf32 {} else os.dief("u64 != vf32 failed")

	if vf32 > vu64 os.dief("vf32 > u64 failed")
	if vu64 >  vf32 {} else os.dief("vf32 > u64 failed")
	if vf32 >= vu64 os.dief("vf32 > u64 failed")
	if vu64 >=  vf32 {} else os.dief("u64 > u64 failed")
	if vu32 > vf32e  os.dief("vu32 > vf32e failed")
	if vu32 >= vf32e {} else os.dief("vu32 >= vf32e failed")

	if vf32 < vu64 {} else os.dief("vf32 < u64 failed")
	if vu64 <  vf32 os.dief("vu64 > u64 failed")
	if vf32 <= vu64 {} else os.dief("vf32 <= u64 failed")
	if vu64 <=  vf32 os.dief("vu64 <= vfu64 failed")
	if vu32 < vf32e  os.dief("vf32 < vf32e failed")
	if vu32 <= vf32e {} else os.dief("vf32 <= vf32e failed")

	//f64 i32
	if vf64 == vi32 os.dief("vf64 == vi32 failed")
	if vi32 == vf64 os.dief("vi32 == vf64 failed")
	if vf64 != vi32 {} else os.dief("vf32 != i32 failed")
	if vi32 != vf64 {} else os.dief("i32 != vf64 failed")

	if vf64 > vi32 {} else os.dief("vf32 > i32 failed")
	if vi32 >  vf64 os.dief("vi32 > vf64 failed")
	if vf64 >= vi32 {} else os.dief("vf64 > i32 failed")
	if vi32 >=  vf64 os.dief("vi32 > i32 failed")

	if vf64 < vi32 os.dief("vf64 < i32 failed")
	if vi32 <  vf64 {} else os.dief("vi32 > i32 failed")
	if vf64 <= vi32 os.dief("vf64 <= i32 failed")
	if vi32 <=  vf64 {} else os.dief("vi32 <= vfi32 failed")

	//f64 u32
	if vf64 == vu32 os.dief("vf64 == vu32 failed")
	if vu32 == vf64 os.dief("vu32 == vf64 failed")
	if vf64 != vu32 {} else os.dief("vf32 != vu32 failed")
	if vu32 != vf64 {} else os.dief("vu32 != vf64 failed")

	if vf64 > vu32 {} else os.dief("vf32 > i32 failed")
	if vu32 >  vf64 os.dief("vu32 > vf64 failed")
	if vf64 >= vu32 {} else os.dief("vf64 > vu32 failed")
	if vu32 >=  vf64 os.dief("vu32 >= vf64 failed")

	if vf64 < vu32 os.dief("vf64 < i32 failed")
	if vu32 <  vf64 {} else os.dief("vu32 > i32 failed")
	if vf64 <= vu32 os.dief("vf64 <= i32 failed")
	if vu32 <=  vf64 {} else os.dief("vu32 <= vfi32 failed")

	//f64 i64
	if vf64 == vi64 os.dief("vf64 == i64 failed")
	if vi64 == vf64 os.dief("i64 == vf64 failed")
	if vf64 != vi64 {} else os.dief("vf32 != i64 failed")
	if vi64 != vf64 {} else os.dief("i64 != vf64 failed")

	if vf64 > vi64 {} else os.dief("vf32 > i32 failed")
	if vi64 >  vf64 os.dief("i64 > vf64 failed")
	if vf64 >= vi64 {} else os.dief("vf64 > i64 failed")
	if vi64 >=  vf64 os.dief("i64 >= vf64 failed")

	if vf64 < vi64 os.dief("vf64 < i32 failed")
	if vi64 <  vf64 {} else os.dief("i64 > i32 failed")
	if vf64 <= vi64 os.dief("vf64 <= i32 failed")
	if vi64 <=  vf64 {} else os.dief("i64 <= vfi32 failed")

	//f64 u64
	if vf64 == vu64 os.dief("vf64 == i64 failed")
	if vu64 == vf64 os.dief("i64 == vf64 failed")
	if vu64 == vf64e {} else os.dief("vf64e == vu64 failed")
	if vf64e == vu64 {} else os.dief("vf64e == vu64 2 failed")

	if vf64 != vu64 {} else os.dief("vf32 != i64 failed")
	if vu64 != vf64 {} else os.dief("i64 != vf64 failed")
	if vf64e != vu64 os.dief("vf64e != vu64 faield")
	if vu64 != vf64e os.dief("vf64e != vu642 failed")

	if vf64 > vu64 {} else os.dief("vf64 > vu64 failed")
	if vu64 >  vf64 os.dief("vu64 > vf64 failed")
	if vf64e > vu64 os.dief("vf64e > vu64 failed")
	if vu64 >  vf64e os.dief("vu64 > vf64e failed")

	if vf64 >= vu64 {} else os.dief("vf64 > i64 failed")
	if vu64 >=  vf64 os.dief("i64 >= vf64 failed")
	if vf64e >= vu64 {} else os.dief("vf64e >= vu64")
	if vu64 >= vf64e {} else os.dief("vu64 >= vf64e")

	if vf64 < vu64 os.dief("vf64 < vu64 failed")
	if vu64 <  vf64 {} else os.dief("vu64 > vf64 failed")
	if vf64e < vu64 os.dief("vf64e < vu64 failed")
	if vu64 < vf64 {} else os.dief("vf64e < vu64 failed 2")

	if vf64 <= vu64 os.dief("vf64 <= vu64 failed")
	if vu64 <=  vf64 {} else os.dief("i64 <= vfi32 failed")
	if vf64e <= vu64 {} else os.dief("vf64e <= vu64 failed")
	if vu64 <= vf64e {} else os.dief("vf64e <= vu64 failed")

	//f32 f32  f64 f64
	if vf32 == vf32 {} else os.dief("vf32 == vf32 failed")
	if vf64 == vf64 {} else os.dief("vf64 == vf64 failed")
	if vf32 != vf32 os.dief("vf32 != vf32 failed")
	if vf64 != vf64 os.dief("vf64 != vf64 failed")
	if vf32 < vf32 os.dief("vf32 < vf32 failed")
	if vf64 < vf64 os.dief("vf64 < vf64 failed")
	if vf32 <= vf32 {} else os.dief("vf32 <= vf32 failed")
	if vf64 <= vf64 {} else os.dief("vf64 <= vf64 failed")
	if vf32 > vf32 os.dief("vf32 > vf32 failed")
	if vf64 > vf64 os.dief("vf64 > vf64 failed")
	if vf32 >= vf32 {} else os.dief("vf32 >= vf32 failed")
	if vf64 >= vf64 {} else os.dief("vf64 >= vf64 failed")
	//f32 f64
	if vf32 == vf64 os.dief("vf32 == vf64 failed")
	if vf64 == vf32 os.dief("vf64 == vf32 failed")
	if vf32 != vf64 {} else os.dief("vf32 != vf64 failed")
	if vf64 != vf32 {} else os.dief("vf64 != vf32 failed")
	if vf32 > vf64 os.dief("vf32 > vf64 failed")
	if vf64 > vf32 {} else os.dief("vf64 > vf32 failed")
	if vf32 >= vf64 os.dief("vf32 >= vf64 failed")
	if vf64 >= vf32 {} else os.dief("vf64 >= vf32 failed")
	if vf32 < vf64 {} else os.dief("vf32 < vf64 failed")
	if vf64 < vf32 os.dief("vf64 < vf32 failed")
	if vf32 <= vf64 {} else os.dief("vf32 <= vf64 failed")
	if vf64 <= vf32 os.dief("vf64 <= vf32 failed")

	fmt.println("test_cond success")

}
fn test_log_or_and(){
	fmt.println("test_|| &&")
	vi8o<i8> = 9
	vi8n<i8> = -9
	vi16o<i16> = 66
	vi16n<i16> = -66
	vi32o<i32> = 999
	vi32n<i32> = -999
	vi64o<i64> = 33333333
	vi64n<i64> = -33333333
	vf32o<f32> = 123.456
	vf32n<f32> = -123.456
	vf64o<f64> = 123456789.123
	vf64n<f64> = -123456789.123
	//i8 i8
	if vi8o || vi8o {} else os.dief("1: i8 || i8  failed")
	if vi8o || vi8n {} else os.dief("2: i8 || i8  failed")
	if vi8n || vi8n os.dief("3: i8 || i8  failed")
	if vi8o && vi8o {} else os.dief("4: i8 && i8  failed")
	if vi8o && vi8n os.dief("5: i8 && i8  failed")
	if vi8n && vi8n os.dief("6: i8 && i8  failed")
	//i8 i16
	if vi8o || vi16o {} else os.dief("1: i8 || i16  failed")
	if vi8o || vi16n {} else os.dief("2: i8 || i16  failed")
	if vi8n || vi16n os.dief("3: i8 || i16  failed")
	if vi8o && vi16o {} else os.dief("4: i8 && i16  failed")
	if vi8o && vi16n os.dief("5: i8 && i16  failed")
	if vi8n && vi16n os.dief("6: i8 && i16  failed")
	//i8 i32
	if vi8o || vi32o {} else os.dief("1: i8 || i32  failed")
	if vi8o || vi32n {} else os.dief("2: i8 || i32  failed")
	if vi8n || vi32n os.dief("3: i8 || i32  failed")
	if vi8o && vi32o {} else os.dief("4: i8 && i32  failed")
	if vi8o && vi32n os.dief("5: i8 && i32  failed")
	if vi8n && vi32n os.dief("6: i8 && i32  failed")
	//i8 i64
	if vi8o || vi64o {} else os.dief("1: i8 || i64  failed")
	if vi8o || vi64n {} else os.dief("2: i8 || i64  failed")
	if vi8n || vi64n os.dief("3: i8 || i64  failed")
	if vi8o && vi64o {} else os.dief("4: i8 && i64  failed")
	if vi8o && vi64n os.dief("5: i8 && i64  failed")
	if vi8n && vi64n os.dief("6: i8 && i64  failed")
	//i8 f32
	if vi8o || vf32o {} else os.dief("1: i8 || f32  failed")
	if vi8o || vf32n {} else os.dief("2: i8 || f32  failed")
	if vi8n || vf32n os.dief("3: i8 || f32  failed")
	if vi8o && vf32o {} else os.dief("4: i8 && f32  failed")
	if vi8o && vf32n os.dief("5: i8 && f32  failed")
	if vi8n && vf32n os.dief("6: i8 && f32  failed")

	//i8 f64
	if vi8o || vf64o {} else os.dief("1: i8 || f64  failed")
	if vi8o || vf64n {} else os.dief("2: i8 || f64  failed")
	if vi8n || vf64n os.dief("3: i8 || f64  failed")
	if vi8o && vf64o {} else os.dief("4: i8 && f64  failed")
	if vi8o && vf64n os.dief("5: i8 && f64  failed")
	if vi8n && vf64n os.dief("6: i8 && f64  failed")

	//i16 i16 
	if vi16o || vi16o {} else os.dief("1: i16 || vi16  failed")
	if vi16o || vi16n {} else os.dief("2: i16 || vi16  failed")
	if vi16n || vi16n os.dief("3: i16 || vi16  failed")
	if vi16o && vi16o {} else os.dief("4: i16 && i16  failed")
	if vi16o && vi16n os.dief("5: i16 && i16  failed")
	if vi16n && vi16n os.dief("6: i16 && i16  failed")
	//i16 i32 
	if vi16o || vi32o {} else os.dief("1: i16 || vi32  failed")
	if vi16o || vi32n {} else os.dief("2: i16 || vi32  failed")
	if vi16n || vi32n os.dief("3: i16 || vi32  failed")
	if vi16o && vi32o {} else os.dief("4: i16 && i32  failed")
	if vi16o && vi32n os.dief("5: i16 && i32  failed")
	if vi16n && vi32n os.dief("6: i16 && i32  failed")

	//i16 i64
	if vi16o || vi64o {} else os.dief("1: i16 || vi64  failed")
	if vi16o || vi64n {} else os.dief("2: i16 || vi64  failed")
	if vi16n || vi64n os.dief("3: i16 || vi64  failed")
	if vi16o && vi64o {} else os.dief("4: i16 && i64  failed")
	if vi16o && vi64n os.dief("5: i16 && i64  failed")
	if vi16n && vi64n os.dief("6: i16 && i64  failed")

	//i16 f32
	if vi16o || vf32o {} else os.dief("1: i16 || vf32  failed")
	if vi16o || vf32n {} else os.dief("2: i16 || vf32  failed")
	if vi16n || vf32n os.dief("3: i16 || vf32  failed")
	if vi16o && vf32o {} else os.dief("4: i16 && f32  failed")
	if vi16o && vf32n os.dief("5: i16 && f32  failed")
	if vi16n && vf32n os.dief("6: i16 && f32  failed")
	//i16 f64
	if vi16o || vf64o {} else os.dief("1: i16 || vf64  failed")
	if vi16o || vf64n {} else os.dief("2: i16 || vf64  failed")
	if vi16n || vf64n os.dief("3: i16 || vf64  failed")
	if vi16o && vf64o {} else os.dief("4: i16 && f64  failed")
	if vi16o && vf64n os.dief("5: i16 && f64  failed")
	if vi16n && vf64n os.dief("6: i16 && f64  failed")

	//i32 i32
	if vi32o || vi32o {} else os.dief("1: i32 || i32  failed")
	if vi32o || vi32n {} else os.dief("2: i32 || i32  failed")
	if vi32n || vi32n os.dief("3: i32 || i32  failed")
	if vi32o && vi32o {} else os.dief("4: i32 && i32  failed")
	if vi32o && vi32n os.dief("5: i32 && i32  failed")
	if vi32n && vi32n os.dief("6: i32 && i32  failed")
	//i32 i64
	if vi32o || vi64o {} else os.dief("1: i32 || i64  failed")
	if vi32o || vi64n {} else os.dief("2: i32 || i64  failed")
	if vi32n || vi64n os.dief("3: i32 || i64  failed")
	if vi32o && vi64o {} else os.dief("4: i32 && i64  failed")
	if vi32o && vi64n os.dief("5: i32 && i64  failed")
	if vi32n && vi64n os.dief("6: i32 && i64  failed")
	//i32 f32
	if vi32o || vf32o {} else os.dief("1: i32 || f32  failed")
	if vi32o || vf32n {} else os.dief("2: i32 || f32  failed")
	if vi32n || vf32n os.dief("3: i32 || f32  failed")
	if vi32o && vf32o {} else os.dief("4: i32 && f32  failed")
	if vi32o && vf32n os.dief("5: i32 && f32  failed")
	if vi32n && vf32n os.dief("6: i32 && f32  failed")
	//i32 f64
	if vi32o || vf64o {} else os.dief("1: i32 || f64  failed")
	if vi32o || vf64n {} else os.dief("2: i32 || f64  failed")
	if vi32n || vf64n os.dief("3: i32 || f64  failed")
	if vi32o && vf64o {} else os.dief("4: i32 && f64  failed")
	if vi32o && vf64n os.dief("5: i32 && f64  failed")
	if vi32n && vf64n os.dief("6: i32 && f64  failed")
	//i64 i64
	if vi64o || vi64o {} else os.dief("1: i64 || i64  failed")
	if vi64o || vi64n {} else os.dief("2: i64 || i64  failed")
	if vi64n || vi64n os.dief("3: i64 || i64  failed")
	if vi64o && vi64o {} else os.dief("4: i64 && i64  failed")
	if vi64o && vi64n os.dief("5: i64 && i64  failed")
	if vi64n && vi64n os.dief("6: i64 && i64  failed")
	//i64 f32
	if vi64o || vf32o {} else os.dief("1: i64 || f32  failed")
	if vi64o || vf32n {} else os.dief("2: i64 || f32  failed")
	if vi64n || vf32n os.dief("3: i64 || f32  failed")
	if vi64o && vf32o {} else os.dief("4: i64 && f32  failed")
	if vi64o && vf32n os.dief("5: i64 && f32  failed")
	if vi64n && vf32n os.dief("6: i64 && f32  failed")
	//i64 f64
	if vi64o || vf64o {} else os.dief("1: i64 || f64  failed")
	if vi64o || vf64n {} else os.dief("2: i64 || f64  failed")
	if vi64n || vf64n os.dief("3: i64 || f64  failed")
	if vi64o && vf64o {} else os.dief("4: i64 && f64  failed")
	if vi64o && vf64n os.dief("5: i64 && f64  failed")
	if vi64n && vf64n os.dief("6: i64 && f64  failed")

	//f32 f32
	if vf32o || vf32o {} else os.dief("1: f32 || f32  failed")
	if vf32o || vf32n {} else os.dief("2: f32 || f32  failed")
	if vf32n || vf32n os.dief("3: f32 || f32  failed")
	if vf32o && vf32o {} else os.dief("4: f32 && f32  failed")
	if vf32o && vf32n os.dief("5: f32 && f32  failed")
	if vf32n && vf32n os.dief("6: f32 && f32  failed")
	//f32 f64
	if vf32o || vf64o {} else os.dief("1: f32 || f64  failed")
	if vf32o || vf64n {} else os.dief("2: f32 || f64  failed")
	if vf32n || vf64n os.dief("3: f32 || f64  failed")
	if vf32o && vf64o {} else os.dief("4: f32 && f64  failed")
	if vf32o && vf64n os.dief("5: f32 && f64  failed")
	if vf32n && vf64n os.dief("6: f32 && f64  failed")

	//f64 f64
	if vf64o || vf64o {} else os.dief("1: f64 || f64  failed")
	if vf64o || vf64n {} else os.dief("2: f64 || f64  failed")
	if vf64n || vf64n os.dief("3: f64 || f64  failed")
	if vf64o && vf64o {} else os.dief("4: f64 && f64  failed")
	if vf64o && vf64n os.dief("5: f64 && f64  failed")
	if vf64n && vf64n os.dief("6: f64 && f64  failed")

	fmt.println("test_|| && success")
}
mem A{
	f32 a,b
	i32 c
	i8  d
	f64 e
	i64 f
}
gv<A:> = new A {
	a: 1.1234,
	b: 5.6789,
	c: 111111,
	d: 22,
	e: 12345.6789,
	f: 6789
}
fn test_struct(){
	fmt.println("test struct")
	//struct init
    tmp<f64> = gv.a
	rs<string.String> = string.f64tostring(tmp,4.(i8))
	fmt.println(rs.dyn())
	if gv.a >= 1.1230 {} else os.dief("gv.a != 1.1234")
    tmp<f64> = gv.b
	rs<string.String> = string.f64tostring(tmp,4.(i8))
	fmt.println(rs.dyn())
	if gv.b >= 5.6780 {} else os.dief("gv.b != 5.6789")
	if gv.c == 111111 {} else os.dief("gv.c != 11111")
	if gv.d == 22 {} else 	  os.dief("gv.d != 22")
    tmp<f64> = gv.e
	rs<string.String> = string.f64tostring(tmp,4.(i8))
	fmt.println(rs.dyn())
	if gv.e >= 12345.6780 {} else os.dief("gv.e != 12345.6789")
	if gv.f == 6789 {} else os.dief("gv.f != 6789.12345")
	//struct get
	v<A> = new A{
		a: 11234.123,
		b: 56789.123,
		c: 22222,
		d: 33,
		e: 789.1234567,
		f: 11111
	}
    tmp<f64> = v.a
	rs<string.String> = string.f64tostring(tmp,4.(i8))
	fmt.println(rs.dyn())
	if v.a >= 11234.120 {} else os.dief("gv.a != 11234.123")
    tmp<f64> = v.b
	rs<string.String> = string.f64tostring(tmp,4.(i8))
	fmt.println(rs.dyn())
	if v.b >= 56789.120 {} else os.dief("gv.b != 56789.123")
	if v.c == 22222 {} else os.dief("gv.c != 22222")
	if v.d == 33 {} else 	  os.dief("gv.d != 33")
    tmp<f64> = v.e
	rs<string.String> = string.f64tostring(tmp,4.(i8))
	fmt.println(rs.dyn())
	if v.e >= 789.1234560 {} else os.dief("gv.e != 789.1234567")
	if v.f == 11111 {} else os.dief("gv.f != 11111.3333333")
	//struct update
	v.a = 3.5
	if v.a == 3.5 {} else os.dief("v.a != 3.5")
	v.b = 7.91234
    tmp<f64> = v.b
	rs<string.String> = string.f64tostring(tmp,4.(i8))
	fmt.println(rs.dyn())
	if v.b >= 7.91230 {} else os.dief("v.b != 7.91234")
	v.d = 44
	if v.d == 44 {} else os.dief("v.d != 44")
	if v.e == 789.1234567 {} else os.dief("v.e == 789.1234567")

    arr<B> = new B {
        arr1: [1,2],
        arr2: [3.1,3.2],
        arr3: [4.1,4.2]
    }
    if arr.arr1[0] == 1 {} else os.dief("arr1[0] != 1")
    if arr.arr1[1] == 2 {} else os.dief("arr1[0] != 2")
    tmp<f64> = arr.arr2[1]
	rs<string.String> = string.f64tostring(tmp,4.(i8))
	fmt.println(rs.dyn())


    arr<B> = new B {
        arr1: [1,2],
        arr2: [3.1,3.2],
        arr3: [4.1,4.2]
    }
    if arr.arr1[0] == 1 {} else os.dief("arr1[0] != 1")
    if arr.arr1[1] == 2 {} else os.dief("arr1[0] != 2")
    tmp<f64> = arr.arr2[1]
	rs<string.String> = string.f64tostring(tmp,4.(i8))
	fmt.println(rs.dyn())
    if arr.arr2[1] >= 3.1 {} else os.dief("arr2[1] != 3.2")
    if arr.arr2[0] >= 3.0 {} else os.dief("arr2[1] != 3.1")
    if arr.arr3[1] >= 4.1 {} else os.dief("arr3[1] != 4.2")
    if arr.arr3[0] >= 4.0 {} else os.dief("arr3[0] != 4.1")
	//struct arr init
    if ga1.arr2[1] >= 3.0 {} else os.dief("ga1.arr2[1] != 3.2")
    if ga1.arr2[0] >= 2.0 {} else os.dief("ga1.arr2[1] != 3.1")
    if ga1.arr3[1] >= 5.0 {} else os.dief("ga1.arr3[1] != 4.2")
    if ga1.arr3[0] >= 4.0 {} else os.dief("ga1.arr3[0] != 4.1")
	if ga1.arr1[1] == 2 {} else os.dief("ga1.arr1[1] != 2")
	fmt.println("test struct success")
}
ga1<B:> = new B  {
	arr1: [1,2],
	arr2: [2.1,3.1],
	arr3: [4.1,5.1]
}
mem B{
    i32 arr1[2]
    f32 arr2[2]
    f64 arr3[2]
}
fn ret_f32(){v<f32> = 123.456789 return v}
fn ret_f64(){v<f64> = 123456789.123 return v}
fn test_call2(a<f64> , b<f32>){
	r<f64> = a
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "123456789.1229" {} else {
		os.dief("%s != 123456789.1229",rs.dyn())
	}
	r = b
	rs<string.String> = string.f64tostring(r,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "3.0999" {} else {
		os.dief("%s != 3.0999",rs.dyn())
	}
	vf32<f32> = ret_f32()
	vf64<f64> = vf32
	rs<string.String> = string.f64tostring(vf64,6.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "123.456787" {} else {
		os.dief("%s != 123.456787",rs.dyn())
	}

	vf64 = ret_f64()
	rs<string.String> = string.f64tostring(vf64,4.(i8))
	fmt.println(rs.dyn())
	if rs.dyn() == "123456789.1229" {} else {
		os.dief("%s != 123.456789.1229",rs.dyn())
	}
}
fn tc1(){
	v1<f32> = 123.456
	v2<f64> = 456.789
	return v1,5.(i8),v2,10.(i8)
}
fn test_call(){
	fmt.println("test call")
	b<f64> = 123456789.123
	test_call2(b,ga1.arr2[1])

	v1<f32>,n<i32>,v2<f64>,v3<i32> = tc1()
	if v1 >= 123.4 && v1 <= 123.5 {} else 
		os.die("v1 neq 123")
	if v2 >= 456.7 && v2 <= 456.8 {} else {
		os.die("v2 neq 456")
	}
	if n == 5 {} else 
		os.die("neq 5")
	if v3 == 10 {} else {
		os.die("v3 != 10")
	}
	fmt.println("test call success")
}

fn main(){
    test_base1()
    test_base2()
    test_bitop()
	test_add()
	test_sub()
	test_mul()
	test_div()
	test_cond()
	test_log_or_and()
	test_struct()
	test_call()
}