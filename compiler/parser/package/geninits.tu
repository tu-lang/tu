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
 Package::parseinit(){
	 if std.exist(this.getFullName(),hashInit)
		 return hashInit[this.getFullName()]
	 
	 hashInit[this.getFullName()] = std.len(this.inits)  > 0
 
	 for(p : this.parsers)
	 {
		 for(fullpackage : p.import )
		 {
			 if packages[fullpackage].parseinit() && 
			 	!std.exist(this.getFullName() , hashInit)
			 {
				 hashInit[this.getFullName()] = true
				 this.InsertInitFunc(p)
			 }
		 }
	 }
	 
	 if (this.package == "main" && std.len(this.inits) == 0){
		this.panic("main_init0 should be created before")
	 }
	 
	 return hashInit[this.getFullName()] 
 }
 HasGen = {}
Package::geninit(){
	 if std.exist(this.getFullName(),HasGen)
	 	return false
	 HasGen[this.getFullName()] = true

	 if std.len(this.inits) <= 0 return false
	 mf = this.inits[0]
	 for(filepath,parser : this.parsers){
		 for(fullpackage : parser.import){
			 if !std.exist(fullpackage,packages) utils.panic("not exist: %s" , fullpackage)
			 dpkg = packages[fullpackage]
			 if(dpkg.geninit()){
				 for(init : dpkg.inits){
					mf.InsertFuncall(fullpackage,init.name)
				 }
			 }
		 }
	 }
	 
	 if this.package == "main" {
		 for(init : this.inits){
			if init.funcname == mf.funcname continue
			mf.InsertFuncall(fullpackage,init.name)
		 }
 
	 }
	 return true
 } 