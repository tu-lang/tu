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
    compile.funcs_offsets()
    compile.registerVars()
    compile.registerStrings()
    compile.writeln(".text")
    
    compile.registerFuncs()
    compile.parser = null

    std.fclose(out)
    compile.out = null

}