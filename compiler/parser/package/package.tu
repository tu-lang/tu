use std
use std.regex
use utils

class Package {
    parsers # parsers map[filepath + name] = parser
    package
    path
    full_package

    inits
    initid
    initvars 
    classes # map[string] Class
    structs # map[string] Struct
}

Package::init(name , path , multi) {
    this.inits = []
    this.initid = 0
    this.package      = name
    this.path         = path
    this.full_package = path
    if multi {
        this.path = regex.replace(path,"_","/")
    }

    this.classes = {}
    this.structs = {}

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

    fd = std.opendir(dir){
    while true {
        p = std.readdir(fd)
        if !file break
        if !file.isFile() continue

        filepath = p.path
        if string.sub(filepath,std.len(filepath) - 2) == ".tu" {
            parser = new Parser(filepath,this,package,full_package)
            
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
    for(parser : parsers){
        ret  = parser.getFunc(name,is_extern)
        if ret != null return ret
    }
    return null
}

Package::addClass(name, f)
{
    if std.exist(name,this.classes) {
        for(i : classes[name].funcs)
            f.funcs[] = i
    }
    this.classes[name] = f
}

Package::addStruct(name, f)
{
    if std.exist(name,structs) {
        return true
    }
    this.structs[name] = f
}
Package::getStruct(name)
{    
    if std.exist(name,structs) 
        return f.second
    return null
}

Package::addClassFunc(name,f,p)
{
    if std.exist(name,classes) {
        this.classes[name].funcs[] = f
        return null
    }
    
    s = new ast.Class(package)
    s.name  = name
    s.parser = p
    s.funcs[] = f
    classes[name] = s
}
Package::hasClass(name)
{
    return std.exist(name,classes)
}

Package::getGlobalVar(name){
    for(parser : parsers){
        if std.exist(name,parser.gvars){
            return parser.gvars[name]
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
    cs = classes[name]
    for(var : cs.funcs){
        if var.name == fc
            return true
    }
    return false
}
