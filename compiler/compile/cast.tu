use internal
use runtime


# map[runtime.type] = int
types

# the table for type casts
i32i8  i32u8 i32i16 i32u16 i32i64 u32i64

# the casts table
casts

func init_cast(){
  types = {
    int(runtime.I8):0 , int(runtime.I16):1 , int(runtime.I32):2 , int(runtime.I64):3,
    int(runtime.U8):4 , int(runtime.U16):5 , int(runtime.U32):6 , int(runtime.U64):7
  }
  i32i8  = "movsbl %al, %eax"
  i32u8  = "movzbl %al, %eax"
  i32i16 = "movswl %ax, %eax"
  i32u16 = "movzwl %ax, %eax"
  i32i64 = "movsxd %eax, %rax"
  u32i64 = "mov %eax, %eax"

  casts[] = [null,null,null,i32i64]

  // i8   i16     i32     i64     u8     u16     u32     u64    
  casts[] = [null,  null,   null,   i32i64, i32u8, i32u16, null,   i32i64 ]  // i8
  casts[] = [i32i8, null,   null,   i32i64, i32u8, i32u16, null,   i32i64 ]  // i16
  casts[] = [i32i8, i32i16, null,   i32i64, i32u8, i32u16, null,   i32i64 ]  // i32
  casts[] = [i32i8, i32i16, null,   null,   i32u8, i32u16, null,   null  ]   // i64

  casts[] = [i32i8, null,   null,   i32i64, null,  null,   null,   i32i64 ]  // u8
  casts[] = [i32i8, i32i16, null,   i32i64, i32u8, null,   null,   i32i64 ]  // u16
  casts[] = [i32i8, i32i16, null,   u32i64, i32u8, i32u16, null,   u32i64 ]  // u32
  casts[] = [i32i8, i32i16, null,   null,   i32u8, i32u16, null,   null   ]  // u64

}


Compiler::Cast(from ,to) {
  f = types[from]
  t = types[to]
  if cast_table[f][t] != null {
    this.writeln("  %s", cast_table[f][t])
  }
}
