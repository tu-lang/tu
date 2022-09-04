use utils
use ast


uniquesig = "initvars_" + utils.strRand()

Package::getInitVarsFuncName(){
	return uniquesig
}

Package::initClassInitFunc(name)
{
	if this.classes[name] == null
		return false
	cs = this.classes[name]
	f = null
    for(var : cs.funcs){
        if var.name == "init" {
            f = var
            break
        }
    }
    if f == null {
		p = std.head(this.parsers)
        f = p.genClassInitFunc(name)
        cs.funcs[] = f 
        p.addFunc(cs.name + f.name,f)
    }

    if f.block == null {
        f.block = new ast.Block()
    }
    f.block.InsertExpressionsHead(cs.initmembers)
    return true
}
