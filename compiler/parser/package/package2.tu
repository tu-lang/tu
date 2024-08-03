use fmt
use compiler.parser.scanner
use compiler.compile

Package::parse2()
{
	for(cls : this.classes){
        cls.type_id = 0
        cls.funcs = []
    }

    this.initid = 0
    this.inits = []
}

Package::parse3()
{
    for(p : this.parsers){
		reader<scanner.ScannerStatic> = p.scanner
        reader.reset()

        compile.currentParser = p
        p.parse()
        compile.currentParser = null
    }
}