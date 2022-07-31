Parser::compile()
{    
    out = std.fopen(this.asmfile)
    Compiler::out = out
    if out <= 0 
        parse_err("genrate assembly file failed package:%s file:%s",pkg.package,
        filename)

    Compiler::parser = this
    Compiler::writeln(".data")
    Compiler::funcs_offsets()
    Compiler::registerVars()
    Compiler::registerStrings()
    Compiler::writeln(".text")
    
    Compiler::registerFuncs()
    Compiler::parser = null

    std.fclose(out)
    Compiler::out = null

}