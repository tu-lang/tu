use std
use std.regex
use compiler.utils
use compiler.ast
use compiler.parser
use compiler.compile
use os
use string

class Package {
    parsers = {} // parsers map[filepath + name] = parser
    package = name
    path    = path
    full_package = path
    fparser    = null
    gc_moudles = ""

    inits = []   // string,func
    initid = 0
    initvars 
    classes = {} // map{string : Class  }
    structs = {} // map{string : Struct }
    impls   = {}
    imports = {} // map[string: string}
    gstrs = {}

    cfgs    = new ast.ConfigOpts()
}

Package::init(name , path , multi) {
    utils.debugf("parser.package.Package::init() name:%s path:%s multi:%d",
        name,path,multi
    )
    // Do not self-map short name into imports (poisons top-level io/sys).
    if multi {
        this.path = regex.replace(path,"_","/")
    }

    this.gc_moudles = "gc." + this.full_package + ".ms"
    this.fparser = null

}
Package::parse()
{

    abpath = utils.pwd()
    abpath += "/" + this.path
    utils.debugf("found import.start parser.. %s",abpath)

    if !std.is_dir(abpath) {
        utils.debugf("Parser: current package import not exist :%s",abpath)
        pkgroot = "/usr/local/lib/copkg/"
        for (ek, ev : os.envs()) {
            arr = string.split(ev, "=")
            if std.len(arr) >= 2 && arr[0] == "CO_PKG" && arr[1] != "" {
                // Keep host separators for std.is_dir on Windows.
                pkgroot = arr[1]
                last = pkgroot[std.len(pkgroot) - 1]
                if last != '/' && last != utils.char1(92.(i8)) {
                    // Prefer /; Win32 accepts both.
                    pkgroot = pkgroot + "/"
                }
                break
            }
        }
        abpath = pkgroot + this.path
        if !std.is_dir(abpath) {
            utils.debugf("Parser: global pkg path not exist! :%s %s",abpath,this.path)
            return false  
        }
    }
    utils.notice("start scan the package:%s",abpath)
    names = utils.list_dir_basenames(abpath)
    if std.len(names) <= 0 {
        utils.error("file|dir not exist " +abpath)
    }
    for name : names {
        if name == "." || name == ".." {
            continue
        }
        nlen = std.len(name)
        if nlen < 3 {
            continue
        }
        if string.sub(name, nlen - 3) != ".tu" {
            continue
        }
        filepath = abpath
        last = filepath[std.len(filepath) - 1]
        bs = utils.char1(92.(i8))
        if last != '/' && last != bs {
            filepath = filepath + "/"
        }
        filepath = utils.norm_slash(filepath + name)
        if !std.is_file(filepath) {
            continue
        }
        p = new parser.Parser(filepath,this)
        p.fileno = compile.fileno
        this.parsers[filepath] = p
        utils.notice("start parse the package:%s file:%s",abpath,filepath)
        p.parse()
    }
    return true
}
Package::getFullName(){
    return this.full_package
}
Package::geninitid(){
    id = this.initid
    this.initid += 1
    return id
}
Package::getFunc(name , is_extern){
    for(p : this.parsers){
        ret  = p.getFunc(name,is_extern)
        if ret != null return ret
    }
    return null
}

Package::addClass(name, f)
{
    if this.classes[name] {
        if this.classes[name].type_id != 0 {
            f.parser.panic("class define duplicate " + name)
        }
        for(i : this.classes[name].funcs)
            f.funcs[] = i
    }
    f.type_id = ast.getTypeId()
    this.classes[name] = f
}

Package::addStruct(name, f)
{
    if std.exist(name,this.structs) {
        this.structs[name] = f
        return true
    }
    this.structs[name] = f
}

Package::addAsyncStruct(name, f)
{

    f.isasync = true
    if std.exist(name,this.structs) {
        this.structs[name] = f
        return true
    }
    this.structs[name] = f
}

Package::getStruct(name)
{    
    if std.exist(name,this.structs) 
        return this.structs[name]
    return null
}
Package::addStructFunc(name , fcname , f, s)
{
    if std.exist(name,this.structs) {
        this.structs[name].funcs[fcname] = f
        this.structs[name].order_funcs[] = f
        return null
    }
    this.structs[name] = s
    s.funcs[fcname] = f
    s.order_funcs[] = f
}
Package::addClassFunc(name,f,p)
{
    if std.exist(name,this.classes) {
        this.classes[name].funcs[] = f
        return null
    }
    
    s = new ast.Class(this.package)
    s.name  = name
    s.parser = p
    s.funcs[] = f
    this.classes[name] = s
}
Package::hasClass(name)
{
    return std.exist(name,this.classes)
}

Package::getGlobalVar(name){
    for(p : this.parsers){
        if std.exist(name,p.gvars){
            return p.gvars[name]
        }
    }
    return null
}
Package::getClass(name)
{    
    if std.exist(name,this.classes) 
        return this.classes[name]
    return null
}

Package::checkClassFunc(name , fc)
{
    if std.exist(name,this.classes)
        return false
    cs = this.classes[name]
    for(var : cs.funcs){
        if var.name == fc
            return true
    }
    return false
}
