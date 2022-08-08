
out    # current file fd
parser # current parser
ctx # arr[Context*,Context*..]

func init(filename) 
{
    utils.debug("Compiler::init:",filename)
    ctx = [] # arr[Context*,Context*]

    pkg = new parser.Packge("main","main",false)

    mparser = new parser.Parser(filename,pkg,"main","main")
    mparser.fileno = 1
    mparser.parser()    # token parsering

    pkg.parsers[filename] = mparser

    parser.packages["main"] = pkg

    //check runtime has been parsered
    if std.exist("runtime",parser.packages) {
        pkg = new parser.Package("runtime","runtime",false) 
        //recursively scan code files
        if !pkg.parse() utils.error("AsmError: runtime lib import failed")
        parser.packages["runtime"] = pkg 
    }
}
func writeln(count,args...) {
    str = fmt.sprintf(args) 
    out.Write(str)
}
