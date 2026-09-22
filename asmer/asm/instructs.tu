use asmer.ast
use asmer.utils
use asmer.instruct

Asmer::InstWrite() {
    utils.debug("Asmer::InstWrite".(i8))
    for(i<i32> = 0 ; i < this.parser.funcs.used ; i += 1){

        f<ast.Function> = this.parser.funcs.addr[i]
        for(j<i32> = 0 ; j < f.instructs.used ; j += 1){
            
            inst<instruct.Instruct> = f.instructs.addr[j]
            this.writeBytes(&inst.bytes,inst.size)
        }
    }
}

