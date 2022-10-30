use utils
use std

class Class 
{
  pkg = pkg
  name
  members     = [] # [Expression]
  initmembers = [] # [Expression]
  funcs       = [] # [Function] 

  father
  parser      # Parser
  type_id     = 0
  found       = false
  func init(pkg){}
}
Class::getFunc(name){
  for it : this.funcs {
    if it.name == name {
      return it
    }
  }
  return null
}
Class::getMember(name)
{
  utils.debugf("ast.Class::getMember() name:%s",name)
  for(i : this.members){
    assign = i
    var = assign.lhs
    if var.varname == this.name {
      return name
    }
  }
  for(i : this.initmembers){
    //FIXME: assign should not define
    // var = assign.lhs
    var = i.lhs
    if var.varname == name {
      return name
    }
  }
  return ""
}

Class::initClassInitFunc()
{
  utils.debug("ast.Class::initClassInitFunc()")
    f = null
    for(var : this.funcs){
        if var.name == "init" {
            f = var
            break
        }
    }
    if f == null {
        f = this.parser.genClassInitFunc(this.name) 
        this.funcs[] = f
        this.parser.addFunc(this.name + f.name,f)
        if this.father != null {
          f.block.stmts[] = this.parser.genSuperInitStmt(f)
        }
    }
    if f.block == null {
        f.block = new Block()
    }
    if this.father == null {
      f.block.checkAndRmFirstSuperDefine()
    }
    f.block.InsertExpressionsHead(this.initmembers)

    return true
} 

Class::checkRmSupers(){
  utils.debug("ast.Class::checkRmSupers()")
  if this.father != null return True
  for f : this.funcs {
    if f.block == null  continue
    if f.name == "init" continue
    f.block.checkAndRmFirstSuperDefine()
  }
}