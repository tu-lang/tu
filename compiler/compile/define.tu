use utils

# object
obj 

# label id generate
count

# the func that is generating
current_func

# out is the filename of assembly file 

# the parser object that is processing
parser

// dynamic: args registers
args8   # 8bit
args16  # 16bit
args32  # 32bit
args64  # 64bit


func init() {
    utils.debug("init")
    # TODO: init global object
    obj = new Compiler()

    # init registers
    args8  = ["%dil" , "%sil" , "%dl"  , "%cl"  , "%r8b" , "%r9b"]
    args16 = ["%di"  , "%si"  , "%dx"  , "%cx"  , "%r8w" , "%r9w"]
    args32 = ["%edi" , "%esi" , "%edx" , "%ecx" , "%r8d" , "%r9d"]
    args64 = ["%rdi" , "%rsi" , "%rdx" , "%rcx" , "%r8"  , "%r9" ]

    # init global var
    count = 0
    current_func = null
    out = null
    parser = null

    init_cast()
}