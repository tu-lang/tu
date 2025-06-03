use compiler.ast
use compiler.compile
use std
use fmt
use compiler.parser.package

TypeInfo::getStruct(){
	s = null
	if !this.memType() {
		utils.error("must be mem type in get struct for typeinfo")
	}
	if this.st == null {
		utils.error("st is null in typeinfo")
	}
	return this.st
}