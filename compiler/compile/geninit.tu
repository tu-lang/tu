 use parser
 use parser.package
 use internal
 use ast
 use std

 hashInit = {} # map{string:bool}
 func parseinit(Package* pkg){
	 if std.exist(pkg.getFullName(),hashInit
		 return hashInit[pkg.getFullName()]
	 
	 hashInit[pkg.getFullName()] = std.len(pkg.inits)  > 0
 
	 for(p : pkg.parsers){
		 for(fullpackage : p.import ){
			 if parseinit(package.packages[fullpackage]) && 
			 	!std.exist(pkg.getFullName()) , hashInit)
			 {
				 hashInit[pkg.getFullName()] = true
				 f = new ast.Function()
				 f.name = "init"
				 f.block = new ast.Block()
				 f.parser = p
				 f.package = pkg 
				 p.addFunc(f.name,f)
			 }
		 }
	 }
	 
	 if (pkg.package == "main" && std.len(pkg.inits) == 0){
		 f = new ast.Function()
		 p = std.head(pkg.parsers)
		 
		 f.name = "init"
		 f.block = new ast.Block()
		 f.parser = p
		 f.package = pkg 
		 p.addFunc(f.name,f)
	 }
	 
	 return hashInit[pkg.getFullName()] 
 }
func  geninit(Package* pkg){
	 if std.exist(pkg.getFullName(),HasGen)
	 	return false
	 HasGen[pkg.getFullName()] = true

	 if std.len(pkg.inits) <= 0 return false
	 mf = pkg.inits[0]
	 for(filepath,parser : pkg.parsers){
		 for(fullpackage : parser.import){
			 if !std.exist(fullpackage,package.packages) parse_err("not exist: %s" , fullpackage)
			 dpkg = package.packages[fullpackage]
			 if(geninit(dpkg)){
				 for(init : dpkg.inits){
					 call = new ast.FunCallExpr(mf.parser.line,mf.parser.column)
					 
					 call.package = fullpackage
					 call.funcname = init.name
					 call.is_pkgcall = true
					 
					 if (mf.block == nullptr){
						 mf.block = new ast.Block()
					 }
					 
					 mf.block.stmts[] = new ast.ExpressionStmt(
						call,
						mf.parser.line,
						mf.parser.column
					)
				 }
			 }
		 }
	 }
	 
	 if (pkg.package == "main"){
		 for(init : pkg.inits){
			 
			 if (init.funcname == mf.funcname) continue
			 call = new ast.FunCallExpr(mf.parser.line,mf.parser.column)
			 call.package = init.package.package
			 call.funcname = init.name
			 call.is_pkgcall = true
			 
			 if (mf.block == nullptr){
				 mf.block = new ast.Block()
			 }
			 
			 mf.block.stmts.[] = 
				 new ast.ExpressionStmt(
					 call,
					 mf.parser.line,
					 mf.parser.column
				 )
			 )
		 }
 
	 }
	 return true
 } 