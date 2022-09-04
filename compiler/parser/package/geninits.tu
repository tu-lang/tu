 use parser
 use internal
 use ast
 use std
 use utils
 
 Package::InsertInitFunc(p){
	f = new ast.Function()
    //set parser
    f.name = "init"
    f.block = new ast.Block()
    f.parser = p
    f.package = this
    p.addFunc(f.name,f)
	return f
}
 hashInit = {} # map{string:bool}
 Package::parseinit(pkg){
	 if std.exist(pkg.getFullName(),hashInit)
		 return hashInit[pkg.getFullName()]
	 
	 hashInit[pkg.getFullName()] = std.len(pkg.inits)  > 0
 
	 for(p : pkg.parsers)
	 {
		 for(fullpackage : p.import )
		 {
			 if parseinit(packages[fullpackage]) && 
			 	!std.exist(pkg.getFullName() , hashInit)
			 {
				 hashInit[pkg.getFullName()] = true
				 this.InsertInitFunc(p)
			 }
		 }
	 }
	 
	 if (pkg.package == "main" && std.len(pkg.inits) == 0){
		this.panic("main_init0 should be created before")
	 }
	 
	 return hashInit[pkg.getFullName()] 
 }
func  geninit(pkg){
	 if std.exist(pkg.getFullName(),HasGen)
	 	return false
	 HasGen[pkg.getFullName()] = true

	 if std.len(pkg.inits) <= 0 return false
	 mf = pkg.inits[0]
	 for(filepath,parser : pkg.parsers){
		 for(fullpackage : parser.import){
			 if !std.exist(fullpackage,packages) utils.panic("not exist: %s" , fullpackage)
			 dpkg = packages[fullpackage]
			 if(geninit(dpkg)){
				 for(init : dpkg.inits){
					mf.InsertFuncall(fullpackage,init.name)
				 }
			 }
		 }
	 }
	 
	 if pkg.package == "main" {
		 for(init : pkg.inits){
			if init.funcname == mf.funcname continue
			mf.InsertFuncall(fullpackage,init.name)
		 }
 
	 }
	 return true
 } 