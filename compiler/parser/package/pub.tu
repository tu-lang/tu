use compiler.compile
use std

packages = {} // map{name: Package}
gstrs = {}

fn add_string(str){
    if gstrs[str.lit] != null 
        return true

    gstrs[str.lit] = str
}

fn get_string(str){
    return gstrs[str.lit]
}

func getStruct(packagename,name) {    
    pkgname = packagename
    if GP().pkg.imports[packagename] != null {
        pkgname = GP().pkg.imports[packagename]
    }
    if pkgname == "" || pkgname == null pkgname = compile.currentParser.getpkgname() 

    if packages[pkgname] == null {
        return null
    }
    pkg = packages[pkgname]
    return pkg.getStruct(name)
}