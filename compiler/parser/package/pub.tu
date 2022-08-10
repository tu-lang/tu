use compile
use std

packages # map{name: Package}

func init(){ 
    packages = {} 
}

func getStruct(package,name) {    
    pkgname = package
    if pkgname == "" pkgname = compile.currentFunc.parser.getpkgname() 

    if std.exist(pkgname,packages) < 1 {
        return null
    }
    pkg = packages[pkgname]
    return pkg.getStruct(name)
}