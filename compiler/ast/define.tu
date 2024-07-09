use compiler.compile

class ConfigOpts {
   base_static = false
}

# auto increment closure id
closureidx = 0
# auto increment count
labelidx   = 0

enum {
   Var_Obj_Member , 
   Var_Extern_Global, Var_Local_Global,Var_Local_Mem_Global, 
   Var_Global_Extern, Var_Global_Local,
   Var_Local, 
   Var_Func,
   Var_Global_Local_Static_Field, 
   Var_Local_Static, 
   Var_Local_Static_Field,
   Var_Global_Extern_Static,
}

func GP(){
   return compile.currentParser
}
func GF(){
   return compile.currentFunc
}
fn isfloattk(tk<i32>){
    if(tk == F32 || tk == F64) return true
    return false
}

fn cfg_static(){
   if GP().cfgs.base_static return true

   if GP().pkg.cfgs.base_static return true
   
   return false
}

