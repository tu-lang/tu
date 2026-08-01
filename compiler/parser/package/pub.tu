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
    // imports alias first, then full_package key in packages[]
    if GP().pkg != null && GP().pkg.imports[packagename] != null {
        pkgname = GP().pkg.imports[packagename]
    } else if packages[packagename] != null {
        pkgname = packagename
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
    if GP().pkg != null && GP().pkg.imports[package] != null {
        pkgname = GP().pkg.imports[package]
    } else if packages[package] != null {
        pkgname = package
    }
    if pkgname == ""
        pkgname = GP().getpkgname()

    if packages[pkgname] == null {
        return null
    }
    pkg = packages[pkgname]
    return pkg.getClass(name)
}