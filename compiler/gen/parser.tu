use compile
use std

Parser::compile()
{    
    out = new std.File(this.asmfile)
	if !out.IsOpen() {
		os.die("open file failed")
	}
    compile.C.out = out
    if out <= 0 
        parse_err("genrate assembly file failed package:%s file:%s",pkg.package,
        filename)

    compile.C.parser = this
    writeln(".data")
    Compiler::funcs_offsets()
    Compiler::registerVars()
    Compiler::registerStrings()
    Compiler::writeln(".text")
    
    Compiler::registerFuncs()
    Compiler::parser = null

    std.fclose(out)
    Compiler::out = null

}