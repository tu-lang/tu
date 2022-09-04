class Struct 
{
  pkg  = ""
  name = ""
  size = 0
  align = 0
  member = [] # [Member]

  iscomputed = false
  ispacked = false
  parser = null

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


Struct::getMember(name)
{
  for(i : this.member){
    if i.name == name
      return i
  }
  return null
}