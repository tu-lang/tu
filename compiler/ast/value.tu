

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
  name
  members # [string]
  funcs   # [Function] 
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
  for(i : members){
    if i == name
      return i
  }
  return ""
}