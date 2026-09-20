use compiler.compile

class ConfigOpts {
   base_static = false
}

// auto increment closure id
closureidx = 0
// auto increment count
labelidx   = 0

Var_Obj_Member = 0
Var_Extern_Global = 1
Var_Local_Global = 2
Var_Local_Mem_Global = 3
Var_Global_Extern = 4
Var_Global_Local = 5
Var_Local = 6
Var_Func = 7
Var_Global_Local_Static_Field = 8
Var_Local_Static = 9
Var_Local_Static_Field = 10
Var_Global_Extern_Static = 11


func GP() {
   return compile.currentParser
}
func GF() {
   return compile.currentFunc
}
func isfloattk(tk) {
    if(tk == F32 || tk == F64) return true
    return false
}

func cfg_static() {
   if GP().cfgs.base_static return true

   if GP().pkg.cfgs.base_static return true
   
   return false
}

