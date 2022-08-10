use compile
use std
use parser

parser.Parser::compile()
{    
    asm = new std.File(this.asmfile)
	if !asm.IsOpen() {
        panic("genrate assembly file failed package:%s file:%s",
            pkg.package,filename
        )
	}
    //asm file generate start
    compile.out = asm
    compile.parser = this

    compile.writeln(".data")
    compile.funcs_offsets()
    compile.registerVars()
    compile.registerStrings()
    compile.writeln(".text")
    
    compile.registerFuncs()
    compile.parser = null

    asm.Close()
    compile.out = null

}