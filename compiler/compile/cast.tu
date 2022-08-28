use internal
use runtime


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


func Cast(from ,to) {
  f = int(parser.typesize[int(from)])
  t = int(parser.typesize[int(to)])
  if cast_table[f][t] != null {
    writeln("  %s", cast_table[f][t])
  }
}
