use compiler.internal
use runtime
use fmt
use os
use compiler.utils
use compiler.parser
use compiler.ast

# the table for type casts
i32i8  = "movsbl %al, %eax"
i32u8  = "movzbl %al, %eax"
i32i16 = "movswl %ax, %eax"
i32u16 = "movzwl %ax, %eax"
i32i64 = "movsxd %eax, %rax"
u32i64 = "mov %eax, %eax"

# the casts table
casts = [ 
	// i8   i16     i32     i64     u8     u16     u32     u64    
	[null,  null,   null,   i32i64, i32u8, i32u16, null,   i32i64 ],  // i8
	[i32i8, null,   null,   i32i64, i32u8, i32u16, null,   i32i64 ],  // i16
	[i32i8, i32i16, null,   i32i64, i32u8, i32u16, null,   i32i64 ],  // i32
	[i32i8, i32i16, null,   null,   i32u8, i32u16, null,   null   ],   // i64

	[i32i8, null,   null,   i32i64, null,  null,   null,   i32i64 ],  // u8
	[i32i8, i32i16, null,   i32i64, i32u8, null,   null,   i32i64 ],  // u16
	[i32i8, i32i16, null,   u32i64, i32u8, i32u16, null,   u32i64 ],  // u32
	[i32i8, i32i16, null,   null,   i32u8, i32u16, null,   null   ]  // u64
]
types = {
	int(ast.I8) : 0 , int(ast.I16) : 1 , int(ast.I32) : 2 , int(ast.I64) : 3,
	int(ast.U8) : 4 , int(ast.U16) : 5 , int(ast.U32) : 6 , int(ast.U64) : 7,
}


func Cast(from<i32> ,to<i32>) {
	ff = int(from)
	tt = int(to)
	f = types[ff]
	t = types[tt]
	utils.debugf("compile.Cast ff:%d tt:%d f:%d t:%d",ff,tt,f,t)
	// if f == null || t == null {
		// utils.errorf("compile.Cast() f:%d or t:%d is null",int(from),int(to))
	// }
	if casts[f][t] != null {
		writeln("  %s", casts[f][t])
	}
}
