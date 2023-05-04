use utils
use std
use std.map
use string

mem SymTable {
    map.Map*   symbols //string => Sym*
    std.Array* data_symbol // Sym*
}
func mapstringhashkey(k<string.String>){
    return k.hash64()
}
SymTable::init(){
    this.symbols = map.map_new(mapstringhashkey,0.(i8))
    this.data_symbol = std.array_create()
}

SymTable::hasName(name) {
    return this.symbols.find(name) != map.Null
}
SymTable::addSym(sym<Sym>) {
    utils.debug("SymTable::addSym name:%S".(i8),sym.name.str())
    if this.symbols.find(sym.name) != map.Null {
        pre_sym<Sym> = this.symbols.find(sym.name)
        if pre_sym.global
            sym.global = true
    }
    this.symbols.insert(sym.name ,sym)
    if sym.segName.cmpstr(".data".(i8)) == string.Equal {
        this.data_symbol.push(sym)
    }

}
SymTable::getSym(name<string.String>) {
    utils.debug("SymTable::getSym name:%S".(i8),name.str())
    if this.hasName(name) == True {
        return this.symbols.find(name)
    }else{
        sym<Sym> = newSym(name,True)
        this.symbols.insert(name,sym)
        return sym
    }
}