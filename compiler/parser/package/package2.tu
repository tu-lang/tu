use fmt
use compiler.parser.scanner

Package::parse2()
{
	for(cls : this.classes){
        cls.type_id = 0
        cls.funcs.clear()
    }

    this.initid = 0
    this.inits = {}

    for(p : this.parsers){
		reader<scanner.ScannerStatic> = p.scanner
        reader.reset()
        p.parse()
    }
}