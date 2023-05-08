use compiler.compile
use std

packages = {} # map{name: Package}


func getStruct(packagename,name) {    
    pkgname = packagename
    if pkgname == "" || pkgname == null pkgname = compile.currentParser.getpkgname() 

    if packages[pkgname] == null {
        return null
    }
    pkg = packages[pkgname]
    return pkg.getStruct(name)
}