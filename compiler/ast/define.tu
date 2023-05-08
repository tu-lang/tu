use compiler.compile

# auto increment closure id
closureidx = 0
# auto increment count
labelidx   = 0

enum {
   Var_Obj_Member , //成员函数调用
   Var_Extern_Global, Var_Local_Global,Var_Local_Mem_Global, // 内部全局变量，外部全局变量,内部复合meme结构体变量
   Var_Global_Extern, Var_Global_Local,// 内部全局变量，外部全局变量,内部复合meme结构体变量
   Var_Local, //本地变量
   Var_Func,
   Var_Global_Local_Static_Field, //内部全局 静态成员访问
   Var_Local_Static, //本地静态变量
   Var_Local_Static_Field,//本地静态 成员访问
   Var_Global_Extern_Static,
}

func GP(){
   return compile.currentParser
}
func GF(){
   return compile.currentFunc
}