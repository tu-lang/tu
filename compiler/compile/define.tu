use compiler.utils

// dynamic: args registers
args8  = ["%dil" , "%sil" , "%dl"  , "%cl"  , "%r8b" , "%r9b"] # 8bit
args16 = ["%di"  , "%si"  , "%dx"  , "%cx"  , "%r8w" , "%r9w"] # 16bit
args32 = ["%edi" , "%esi" , "%edx" , "%ecx" , "%r8d" , "%r9d"] # 32bit
args64 = ["%rdi" , "%rsi" , "%rdx" , "%rcx" , "%r8"  , "%r9" ] # 64bit

GP_MAX  = 6
FP_MAX  = 8
