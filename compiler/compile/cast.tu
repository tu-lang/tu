use compiler.internal
use runtime
use fmt
use os
use compiler.utils
use compiler.parser
use compiler.ast

// the table for type casts
i32i8  = "movsbl %al, %eax"
i32u8  = "movzbl %al, %eax"
i32i16 = "movswl %ax, %eax"
i32u16 = "movzwl %ax, %eax"
i32i64 = "movsxd %eax, %rax"
u32i64 = "mov %eax, %eax"

i32f32 = "cvtsi2ssl %eax, %xmm0"
u32f32 = "mov %eax, %eax\n cvtsi2ssq %rax, %xmm0"
i32f64 = "cvtsi2sdl %eax, %xmm0"
u32f64 = "mov %eax, %eax\n cvtsi2sdq %rax, %xmm0"
i64f32 = "cvtsi2ssq %rax, %xmm0"
i64f64 = "cvtsi2sdq %rax, %xmm0" 
u64f32 = "cvtsi2ssq %rax, %xmm0"
u64f64 = "cvtsi2sdq %rax, %xmm0"
f32i8 = "cvttss2sil %xmm0, %eax\n movsbl %al, %eax"
f32u8 = "cvttss2sil %xmm0, %eax\n movzbl %al, %eax"
f32i16 = "cvttss2sil %xmm0, %eax\n movswl %ax, %eax"
f32u16 = "cvttss2sil %xmm0, %eax\n movzwl %ax, %eax"
f32i32 = "cvttss2sil %xmm0, %eax"
f32u32 = "cvttss2siq %xmm0, %rax"
f32i64 = "cvttss2siq %xmm0, %rax"
f32u64 = "cvttss2siq %xmm0, %rax"
f32f64 = "cvtss2sd %xmm0, %xmm0"
f64i8 = "cvttsd2sil %xmm0, %eax\n movsbl %al, %eax"
f64u8 = "cvttsd2sil %xmm0, %eax\n movzbl %al, %eax"
f64i16 = "cvttsd2sil %xmm0, %eax\n movswl %ax, %eax"
f64u16 = "cvttsd2sil %xmm0, %eax\n movzwl %ax, %eax"
f64i32 = "cvttsd2sil %xmm0, %eax"
f64u32 = "cvttsd2siq %xmm0, %rax"
f64i64 = "cvttsd2siq %xmm0, %rax"
f64u64 = "cvttsd2siq %xmm0, %rax"
f64f32 = "cvtsd2ss %xmm0, %xmm0"

// the casts table
casts = [ 
	// i8   i16     i32     i64     u8     u16     u32     u64     f32	   f64
	[null,  null,   null,   i32i64, i32u8, i32u16, null,   i32i64, i32f32, i32f64], // i8
	[i32i8, null,   null,   i32i64, i32u8, i32u16, null,   i32i64, i32f32, i32f64], // i16
	[i32i8, i32i16, null,   i32i64, i32u8, i32u16, null,   i32i64, i32f32, i32f64], // i32
	[i32i8, i32i16, null,   null,   i32u8, i32u16, null,   null,   i64f32, i64f64], // i64

	[i32i8, null,   null,   i32i64, null,  null,   null,   i32i64, i32f32, i32f64], // u8
	[i32i8, i32i16, null,   i32i64, i32u8, null,   null,   i32i64, i32f32, i32f64], // u16
	[i32i8, i32i16, null,   u32i64, i32u8, i32u16, null,   u32i64, u32f32, u32f64], // u32
	[i32i8, i32i16, null,   null,   i32u8, i32u16, null,   null,   u64f32, u64f64], // u64
	[f32i8, f32i16, f32i32, f32i64, f32u8, f32u16, f32u32, f32u64, null,   f32f64], // f32
	[f64i8, f64i16, f64i32, f64i64, f64u8, f64u16, f64u32, f64u64, f64f32, null],   // f64
]
types = {
	int(ast.I8) : 0 , int(ast.I16) : 1 , int(ast.I32) : 2 , int(ast.I64) : 3,
	int(ast.U8) : 4 , int(ast.U16) : 5 , int(ast.U32) : 6 , int(ast.U64) : 7,
	int(ast.F32): 8 , int(ast.F64) : 9
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
