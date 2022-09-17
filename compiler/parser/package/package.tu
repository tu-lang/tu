use std
use std.regex
use utils
use ast
use parser

class Package {
    parsers # parsers map[filepath + name] = parser
    package = name
    path    = path
    full_package = path

    inits = []
    initid = 0
    initvars 
    classes = {} # map{string : Class  }
    structs = {} # map{string : Struct }
}

Package::init(name , path , multi) {
    utils.debugf("parser.package.Package::init() name:%s path:%s multi:%d",
        name,path,multi
    )
    if multi {
        this.path = regex.replace(path,"_","/")
    }
}
Package::parse()
{
    utils.debug("found import.start parser..")

    abpath = utils.pwd()
    abpath += "/" + this.path

    if !std.is_dir(abpath) {
        abpath = "/usr/local/lib/copkg/" + this.path
        utils.debug("Parser: package import:%s",abpath)
        if !std.is_dir(abpath) {
            utils.debug("Parser: global pkg path not exist!")
            return false  
        }
    }

    fd = std.opendir(abpath)
    while true {
        file = std.readdir(fd)
        if !file break
        if !file.isFile() continue

        filepath = file.path
        if string.sub(filepath,std.len(filepath) - 2) == ".tu" {
            parser = new parser.Parser(filepath,this,this.package,this.full_package)
            
            parser.fileno = 1
            this.parsers[filepath] = parser
            parser.parse()
        }
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
    for(parser : this.parsers){
        ret  = parser.getFunc(name,is_extern)
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
    this.classes[name] = f
}

Package::addStruct(name, f)
{
    if std.exist(name,this.structs) {
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
    if std.exist(name,this.clsses) 
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
