use sys
use string

//module
MOD_STD_ID:i32 =  1;
MOD_NETIO_ID:i32 =  2;
MOD_ASYNC_RUNTIME_ID:i32     = 3;
MOD_WS_ID:i32     = 4;
// layer
MOD_OS<i32> = 1
MOD_CUSTOM<i32> = 2
MOD_IO_SIMPLE<i32> = 3
MOD_SIMPLE<i32> = 4
MOD_IO<i32> = 5
MOD_PROTOCOL<i32> = 6
MOD_SEND_QUEUE<i32> = 7
MOD_CAPCITY<i32> = 8
MOD_URL<i32> = 9
MOD_TLS<i32> = 10


fn encode_error(layer<i32>, module<i32>, error<i32>) i32 {
    return ((layer & 0xFF) << 24) |
    ((module & 0xFF) << 16) |
    (error & 0xFFFF)
}

fn decode_error(code<i32>)  i32, i32, i32{
    layer<i32>  = (code >> 24) & 0xFF
    module<i32> = (code >> 16) & 0xFF
    error<i32>  =  code        & 0xFFFF
    return layer, module, error
}

fn decode_error_code(code<i32>) i32 {
    return code        & 0xFFFF
}

pub fn last_error(code<i32>)  i32 {
    sys.decode_error_code(code)
}

pub fn errormsg(code<i32>)  {
    layer<i32>, module<i32> = decode_error(code)

    layer_name<i8*> = layer_name(layer)
    module_name<i8*> = module_name(module)
    message<i8*> = error_message(code)

    return fmt.sprintf(
        "%s :: %s :: %s",
        string.new(layer_name),
        string.new(module_name),
        string.new(message)
    )
}


// paths must not contain interior null bytes
InvalidInputPathContainInteriorNullByte<i32> = -16908341
// parse error
OtherParse<i32> = -16908354