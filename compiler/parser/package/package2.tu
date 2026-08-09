use fmt
use compiler.parser.scanner
use compiler.compile

Package::parse2()
{
	for(cls : this.classes){
        cls.type_id = 0
        cls.funcs = []
    }

    for st : this.structs {
        keepPoll = null
        if st.isasync && st.asyncfn == null
            keepPoll = st.getFunc("poll")
        st.funcs = {}
        st.order_funcs = []
        st.apis        = []
        if keepPoll != null
            st.funcs[keepPoll.name] = keepPoll
        // asyncMemberLeaves / syncFactoryLeaves kept across parse2 for await rewrite
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