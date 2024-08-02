
use compiler.ast
use compiler.utils
use compiler.parser
use compiler.parser.package


out    = null # current file fd
currentParser = null # current parser
currentFunc = null # the func that is generating
fileno = 1

debug  = false
sdebug = false
nostd  = true
trace  = false

func genast(filename)
{
    utils.debugf("compile.genast filename:%s",filename)
    mpkg = new package.Package("main","main",false)
    mparser = new parser.Parser(filename,mpkg)

    mparser.fileno = fileno
    mpkg.parsers[filename] = mparser
    mparser.parse()    # token parsering
    package.packages["main"] = mpkg
    //check runtime has been parsered
    if package.packages["runtime"] != null {
        pkg = new package.Package("runtime","runtime",false) 
        package.packages["runtime"] = pkg 
        //recursively scan code files
        if !pkg.parse() utils.error("AsmError: runtime lib import failed")
    }

    phase = FunctionPhase
    ast.resetTypeId()
    for( pkg : package.packages ){
        pkg.parse2()
    }
}
func editast(){
    utils.debug("ast.editast()")
    mpkg = package.packages["main"]
    mpkg.defaultvarsinit()
    mpkg.genvarsinit()
    mpkg.parseinit()
    mpkg.geninit()
    mpkg.classinit()
}
func writeln(args...) {
    str = fmt.sprintf(args) 
    if !out.Write(str + "\n"){
        os.dief(
            "writeln failed file:%s body:%s",
            out.filepath,
            str,
        )
    }
    
}
func panic(args...){
    err = fmt.sprintf(args)
    cfunc = currentFunc
    os.die("asmgen error: " + fmt.sprintf(args))
}
