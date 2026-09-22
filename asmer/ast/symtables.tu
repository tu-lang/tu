use asmer.utils
use std
use std.map
use string

mem SymTable {
    map.Map*   symbols //string => Sym*
    std.Array* data_symbol // Sym*
}
fn mapstringhashkey(k<string.String>) u64 {
    return k.hash64()
}
SymTable::init(){
    this.symbols = map.map_new(mapstringhashkey.(u64),0.(i8))
    this.data_symbol = std.NewArray()
}

// Native i32 presence. Do not compare find()!=Null in `if` / `== True`:
// that path was dyn-bool and made getSym always miss, overwriting .data syms.
SymTable::hasName(name) i32 {
	hit<u64> = this.symbols.find(name)
	if hit != 0.(u64) {
		return 1
	}
	return 0
}
SymTable::addSym(sym<Sym>) {
    utils.debug("SymTable::addSym name:%S".(i8),sym.name.str())
	hit<u64> = this.symbols.find(sym.name)
	if hit != 0.(u64) {
		pre_sym<Sym> = hit
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
	hit<u64> = this.symbols.find(name)
	if hit != 0.(u64) {
		return hit
    }
	sym<Sym> = newSym(name, true)
	this.symbols.insert(name,sym)
	return sym
}