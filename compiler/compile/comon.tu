
use ast
use utils
use parser
use parser.package


out    = null # current file fd
parser = null # current parser
ctx = [] # arr[Context*,Context*..]
currentFunc = null # the func that is generating

func genast(filename)
{
    mpkg = new parser.Packge("main","main",false)
    mparser = new parser.Parser(filename,mpkg,"main","main")
    mparser.fileno = 1
    mpkg.parsers[filename] = mparser
    mparser.parser()    # token parsering
    package.packages["main"] = mpkg
    //check runtime has been parsered
    if std.exist("runtime",package.packages) {
        pkg = new package.Package("runtime","runtime",false) 
        package.packages["runtime"] = pkg 
        //recursively scan code files
        if !pkg.parse() utils.error("AsmError: runtime lib import failed")
    }
}
func editast(){
    mpkg = package.packages["main"]
    mpkg.genvarsinit()
    mpkg.parseinit()
    mpkg.geninit()
    mpkg.classinit()
}
func writeln(count,args...) {
    str = fmt.sprintf(args) 
    out.Write(str)
}
func panic(args...){
    err = fmt.sprintf(args)
    cfunc = currentFunc
    parse_err("asmgen error: %s line:%d column:%d file:%s\n",err,line,column,cfunc.parser.filepath)
}