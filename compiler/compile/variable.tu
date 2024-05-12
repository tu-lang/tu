use compiler.ast
use compiler.parser
use compiler.parser.package
use compiler.utils
use fmt

func registerStrings(c){
    for(var : currentParser.strs){
        if !c {
            var.name = fmt.sprintf(
                "%s.L%d",currentParser.label(),ast.incr_labelid()
            )
        } else CreateGlobalString(var)
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
    writeln("    .globl %s", var.name)
    writeln("%s:", var.name)
    writeln("    .string \"%s\"",var.lit)
}

fn registerObjects(){
    for cls : currentParser.classes {
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
        utils.quick_sort(orderf,fn(l,r){
            return l.namehid < r.namehid
        })

        orderm = []
        for var : cls.membervars {
            if var.varname == "" 
                var.check(false,"regist object find var name is empty")
            var.varnamehid = utils.hash(var.varname)
            orderm[] = var
        }
        utils.quick_sort(orderm,fn(l,r){
            return l.varnamehid < r.varnamehid
        })

        for fc : orderf {
            writeln("   .quad %d",fc.namehid)
            writeln("   .quad %s",fc.fullname())
            writeln("   .long %d",std.len(fc.params))
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
