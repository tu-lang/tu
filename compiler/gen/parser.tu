use compiler.compile
use std
use compiler.parser
use compiler.utils

parser.Parser::compile()
{    
    utils.debug("gen.parser.Parser::compile()")
    asm = new std.File(this.asmfile,"w")
	if asm == null || !asm.IsOpen() {
        this.panic(
            "genrate assembly file failed package:%s file:%s",
            this.pkg.package,this.filename
        )
	}
    //asm file generate start
    compile.out = asm
    compile.currentParser = this
    if compile.debug
        compile.writeln("    .file %d \"%s\"",this.fileno,this.filepath)

    compile.writeln(".data")
    compile.funcs_offsets()
    compile.registerVars()
    compile.registerStrings(true)
    compile.registerObjects()

    compile.writeln(".text")
    
    compile.registerFuncs()
    compile.currentParser = null

    asm.Close()
    compile.out = null

}