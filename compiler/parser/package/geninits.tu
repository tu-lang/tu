 use compiler.parser
 use compiler.internal
 use compiler.ast
 use std
 use compiler.utils
 
 Package::InsertInitFunc(p){
	f = new ast.Function()
    //set parser
    f.name = "init"
    f.block = new gen.BlockStmt()
    f.parser = p
    f.package = this
    p.addFunc(f.name,f)
	return f
}
hashInit = {} # map{string:bool}
Package::parseinit(){
	if std.exist(this.getFullName(),hashInit){
		return hashInit[this.getFullName()]
	}
	hashInit[this.getFullName()] = std.len(this.inits)  > 0
	for(fullpackage : this.imports )
	{
		if packages[fullpackage].parseinit() && 
		!hashInit[this.getFullName()] {
			hashInit[this.getFullName()] = true
			this.InsertInitFunc(std.head(this.parsers))
		}
	}
	
	if (this.package == "main" && std.len(this.inits) == 0){
		this.panic("main_init0 should be created before")
	}
	
	return hashInit[this.getFullName()] 
}
HasGen = {}
Package::geninit(){
	if std.exist(this.getFullName(),HasGen){
		return false
	}
	HasGen[this.getFullName()] = true
	if std.len(this.inits) <= 0 {
		return false
	}
	mf = this.inits[0]
	for(fullpackage : this.imports){
		if !std.exist(fullpackage,packages) utils.panic("not exist: %s" , fullpackage)
		dpkg = packages[fullpackage]
		if(dpkg.geninit()){
			for( fc : dpkg.inits){
				mf.InsertFuncall(fullpackage,fc.name)
			}
		}
	}

	if this.package == "main" {
		for(fc : this.inits){
			if fc.name == mf.name continue

			mf.InsertFuncall(fc.package.getFullName(),fc.name)
		}

	}
	return true
 } 