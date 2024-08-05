use compiler.compile
use std

packages = {} // map{name: Package}

Package::add_string(str){
    if this.gstrs[str.lit] != null 
        return true

    this.gstrs[str.lit] = str
}

Package::get_string(str){
    return this.gstrs[str.lit]
}

func getStruct(packagename,name) {    
    pkgname = packagename
    if GP().pkg.imports[packagename] != null {
        pkgname = GP().pkg.imports[packagename]
    }
    if pkgname == "" || pkgname == null 
        pkgname = GP().getpkgname() 

    if packages[pkgname] == null {
        return null
    }
    pkg = packages[pkgname]
    return pkg.getStruct(name)
}

fn getClass(package,name)
{    
    pkgname = package
    if GP().pkg.imports[package] != null {
        pkgname = GP().pkg.imports[package]
    }
    if pkgname == ""
        pkgname = GP().getpkgname()

    if packages[pkgname] == null {
        return null
    }
    pkg = packages[pkgname]
    return pkg.getClass(name)
}