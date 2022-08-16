

func ALIGN_UP(x<u64> , a<u64>) {
  //((x) + (a - 1)) & ~(a - 1)
  t<u64> = x + a - 1
  o<u64> = a - 1
  o ~= o
  return t & o
}
func ALIGN_DOWN(x<u64>,a<u64>) {
  return ALIGN_UP(x-a+1,a)
}

class Class 
{
  func init(pkg){
    this.pkg = pkg
  }
  pkg
  parser      # Parser
  name
  members     = [] # [Expression]
  initmembers = [] # [Expression]
  funcs       = [] # [Function] 
}

class Member
{
  name
  type
  size
  isunsigned
  pointer

  idx
  align
  offset
  
  bitfield
  bitoffset
  bitwidth
  
  arrsize
  isarr

  
  isstruct
  structpkg
  structname
  structref
  
  line
  column
  file
}
class Struct 
{
  func init(){
    pkg = ""  name = ""
    size = 0  align = 0
    iscomputed = false
    ispacked = false
    parser = null
  }
  pkg
  name
  size
  align
  member # [Member]

  iscomputed
  ispacked
  
  parser

}

class Value
{
  type
  data
}

Struct::getMember(name)
{
  for(i : member){
    if i.name == name
      return i
  }
  return null
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