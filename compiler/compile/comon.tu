
use ast
use utils
use parser
use parser.package


out    # current file fd
parser # current parser
ctx # arr[Context*,Context*..]

func compiler(filename) 
{
    utils.debug("compile.init:",filename)
    ctx = [] # arr[Context*,Context*]

    mpkg = new parser.Packge("main","main",false)
    mparser = new parser.Parser(filename,mpkg,"main","main")
    mparser.fileno = 1
    mparser.parser()    # token parsering

    mpkg.parsers[filename] = mparser
    package.packages["main"] = mpkg
    //check runtime has been parsered
    if std.exist("runtime",package.packages) {
        pkg = new package.Package("runtime","runtime",false) 
        //recursively scan code files
        if !pkg.parse() utils.error("AsmError: runtime lib import failed")
        package.packages["runtime"] = pkg 
    }
    mpkg.parseinit()
    mpkg.geninit()
}
func writeln(count,args...) {
    str = fmt.sprintf(args) 
    out.Write(str)
}
func panic(args...){
    err = fmt.sprintf(args)
    cfunc = compile.currentFunc
    parse_err("asmgen error: %s line:%d column:%d file:%s\n",err,line,column,cfunc.parser.filepath)
}