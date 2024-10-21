use compiler.ast
use compiler.parser
use compiler.parser.package
use compiler.utils
use fmt

func registerStrings(){
    for(var : currentParser.strs){
        CreateGlobalString(var)
    }
}
func registerVars(){
    utils.debug("compile.registerVars()")
    writeln("    .globl %s", currentParser.filenameid)
    writeln("%s:", currentParser.filenameid)
    writeln("    .string \"%s\"",currentParser.filepath)

    for(name,v : currentParser.gvars){
        gname = currentParser.getpkgname() + "_" + name
        writeln("    .global %s",gname)
        writeln("%s:",gname)
        if !v.structtype {
            writeln("    .quad   8")
            continue
        }
        mt = ast.typesizestring(v.type)
        value = "0"
        if !std.empty(v.ivalue) value = v.ivalue
        if v.pointer mt = "quad"
        
        if v.stack && v.structname != "" && v.stacksize == 1{
            if v.sinit != null {
                s = package.getStruct(v.sinit.init.pkgname,v.sinit.init.name)
                InitStructVar(v,s,v.sinit.init.fields)
            }else
                writeln("    .zero   %d",v.getStackSize(currentParser))
        }else if v.stack {
            if std.len(v.elements) != 0 {
                if(v.structname == ""){
                    for(i : v.elements){
                        writeln("   .%s %s",mt,i)
                    }
                }else{
                    s = package.getStruct(v.structpkg,v.structname) 
                    if s == null {
                        v.check(false,fmt.sprintf(
                            "struckt not exist pkg:%s name:%s",
                            v.structpkg,v.structname
                        ))
                    }
                    if std.len(s.member) * v.stacksize != std.len(v.elements) {
                        v.check(false,"mem arr: init element count not right")
                    }
                    j = 0
                    for i = 0 ; i < v.stacksize ; i += 1 {
                        ws = 0
                        for m : s.member {
                            if(ws > m.offset) v.check(false,"ws > m.offset")
                            if(ws < m.offset){
                                writeln("   .zero %d",m.offset - ws)
                                ws = m.offset
                            }
                            mtk = m.type
                            if(m.pointer) mtk = ast.U64
                            mt = ast.typesizestring(m.type)
                            writeln("   .%s %s",mt,v.elements[j])
                            ws += m.size
                            j += 1
                        }
                        if(ws > s.size) v.check(false,"ws > m.size")
                        if(ws < s.size){
                            writeln("   .zero %d",s.size - ws)
                        }
                    }
                }
            }else{
                writeln("    .zero   %d",v.getStackSize(currentParser))
            }
        }else
            writeln("    .%s   %s",mt,value)
    }
}
func CreateGlobalString(var){
    if var.name == "" {
        var.check(false,"static string not compute")
    }
    writeln("    .globl %s", var.name)
    writeln("%s:", var.name)
    writeln("    .string \"%s\"",var.lit)
}

fn registerObjects(){
    for cls : currentParser.classes {
        //skip struct
        if !cls.found continue

        // gen object type info
        obj_virtname = cls.virtname()

        writeln("   .global %s",obj_virtname)
        writeln("%s:",obj_virtname)

        if cls.father != null 
            writeln("   .quad %s",cls.father.virtname())
        else 
            writeln("   .quad 0")
        writeln("   .long %d",std.len(cls.membervars))
        writeln("   .long %d",std.len(cls.funcs))

        orderf = []
        for fc : cls.funcs {
            if fc.name == "" 
                cls.parser.check(false,"regist object find fn nmae is empty")
            fc.namehid = utils.hash(fc.name)
            orderf[] = fc
        }
        orderf = utils.quick_sort(orderf,fn(l,r){
            ll<runtime.Value> = l.namehid
            rr<runtime.Value> = r.namehid
            lv<u64> = ll.data
            rv<u64> = rr.data
            if lv < rv return true
            return false
        })
        orderm = []
        for var : cls.membervars {
            if var.varname == "" 
                var.check(false,"regist object find var name is empty")
            var.varnamehid = utils.hash(var.varname)
            orderm[] = var
        }
        orderm = utils.quick_sort(orderm,fn(l,r){
            ll<runtime.Value> = l.varnamehid
            rr<runtime.Value> = r.varnamehid
            lv<u64> = ll.data
            rv<u64> = rr.data
            if lv < rv return true
            return false
        })
        for fc : orderf {
            writeln("   .quad %d",fc.namehid)
            writeln("   .quad %s",fc.fullname())

            writeln("   .quad %d",fc.is_variadic)
            writeln("   .quad %d",std.len(fc.params_order_var) * 8)

            writeln("   .quad %d",fc.mcount)
            writeln("   .quad %d", (fc.mcount - 1) * 8)

            writeln("   .long %d",std.len(fc.params_order_var))
            writeln("   .long 0")
            writeln("   .quad 0")
        }

        offset = 0
        for var : orderm {
            writeln("   .quad %d",var.varnamehid)
            writeln("   .quad %d",offset)
            offset += 8
        }
    }
}

fn registerFutures(){
    for st : currentParser.structs {
        if !st.isasync() continue
        cls = package.getClass(st.pkg,st.name)
        if cls == null {
            utils.error("cls not exist in future struct")
        }
        pollf = cls.getFunc("poll")
        if pollf == null {
            utils.error("future not impl poll")
        }
        virtname = st.futurepollname()
        writeln("    .global %s",virtname)
        writeln("%s:",virtname)

        writeln("   .quad 0")
        writeln("   .quad %s",pollf.fullname())

        if pollf.is_variadic {
            currentParser.check(false,"async params can't be variadic")
        }
        writeln("   .quad %d",pollf.is_variadic)

        writeln("   .quad %d",2 * 8)
        writeln("   .quad %d",pollf.mcount)
        writeln("   .quad %d",(pollf.mcount - 1) * 8)
        writeln("   .long %d",2)
        writeln("   .long 0")
        writeln("   .quad 0")
    }
}