class Class 
{
  func init(pkg){
    this.pkg = pkg
  }
  pkg
  name
  members     = [] # [Expression]
  initmembers = [] # [Expression]
  funcs       = [] # [Function] 

  father
  parser      # Parser
  type_id
}

Class::getMember(name)
{
  for(i : this.members){
    var = assign.lhs
    if var.varname == name {
      return name
    }
  }
  for(i : this.initmembers){
    var = assign.lhs
    if var.varname == name {
      return name
    }
  }
  return ""
}

Class::initClassInitFunc()
{
    f = null
    for(var : this.funcs){
        if var.name == "init" {
            f = var
            break
        }
    }
    if f == null {
        f = this.parser.genClassInitFunc(name) 
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
  if this.father != null return True
  for f : this.funcs {
    if f.block == null  continue
    if f.name == "init" continue
    f.block.checkAndRmFirstSuperDefine()
  }
}