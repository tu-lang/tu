use string
use std
use fmt

EOF<i32> = -1
Blank<i8> = ' '
Lower<i8> = '<'

mem ParseHexBytes {
    i8* buffer
    i32 buffersize
    i32 pos
    std.Array* vs
}
ParseHexBytes::print(){
    buf_o<i8:10> = null
    buf<i8*>	 = &buf_o

    arr<u8*> = this.vs.addr
    // fmt.println(
        // "vs.len:"
        // int(this.vs.len())
    // )
    for(i<i32> = 0 ; i < this.vs.len() ; i += 1){
        std.itoa(arr[i],buf,16.(i8))
        printf("%s ".(i8),buf)
    }
    fmt.println("")
}

ParseHexBytes::next() {
    if(this.pos >= this.buffersize){
        return EOF
    }
    p<i32> = this.pos
    this.pos += 1
    return this.buffer[p]
}
char ParseHexBytes::peek() {
    if this.pos >= this.buffersize{
        return EOF
    }
    return this.buffer[this.pos]
}
ParseHexBytes::isvalid(cn<i8>){
    if( (cn >= 'a' && cn <= 'f') || (cn >= '0' && cn <= '9')){
        return true
    }
    return false
}

ParseHexBytes::init(filepath){
    this.vs = std.array_create(0.(i8),1.(i8)) //1 byte
    printf("ParseHexBytes::init() %s\n".(i8),*filepath)
    this.pos      = 0
    fs = new std.File(filepath)

    if !fs.IsOpen() {
        os.die("error opening file :" + filepath )
    }

    this.buffer = fs.ReadAllNative()
    if this.buffer == 0 {
        os.die("error reade file:" + filepath)
    }
    this.buffersize = fs.osize
    debug("ParseHexBytes::init() end %s".(i8),*filepath)
}
ParseHexBytes::parse(){
    cn<i8> = this.next()
    while(cn != EOF){
        if ((cn == ' '||cn == '\t') && this.isvalid(this.peek()) ){
            cn = this.next()
            //eat firstn
            a<string.String> = string.S("0x".(i8))
            a.putc(cn)
            if(this.isvalid(this.peek())){
                a.putc(this.next())
                if(this.peek() == Blank){
                    dd<i8> = a.tonumber()
                    cn = this.next()
                    if(this.peek() != Lower){
                        e<i8*> = this.vs.push()
                        *e = dd
                    }
                }else{
                    cn = this.next()
                }
            }else{//eat
                this.next()
            }
        }else{
            cn = this.next()
        }
    }
    return this.vs
}
