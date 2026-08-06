use compiler.ast
use compiler.parser
use compiler.parser.package
use compiler.utils
use fmt

// Emit .balign before .data labels so gas+ld packing after .string cannot
// leave Note/MutexInter futex words on misaligned addresses.
fn emitDataAlign(bytes){
    if bytes < 1 {
        bytes = 1
    }
    writeln("    .balign %d", bytes)
}

// Natural alignment for a package-level global; mem stack objects at least 8.
fn globalVarDataAlign(v, p) {
    if v == null {
        return 8
    }
    if !v.structtype || v.pointer {
        return 8
    }
    if v.stack && v.structname != "" {
        acualPkg = p.getImport(v.structpkg)
        if acualPkg == "" {
            acualPkg = v.structpkg
        }
        s = package.getStruct(acualPkg, v.structname)
        if s != null {
            if s.size == 0 && !s.iscomputed && s.parser != null && s.parser.pkg != null {
                s.parser.pkg.genStruct(s)
            }
            a = s.align
            if a < 8 {
                a = 8
            }
            return a
        }
        return 8
    }
    if v.type >= ast.I8 && v.type <= ast.F64 {
        sz = 8
        if v.type == ast.I8 || v.type == ast.U8 {
            sz = 1
        } else if v.type == ast.I16 || v.type == ast.U16 {
            sz = 2
        } else if v.type == ast.I32 || v.type == ast.U32 || v.type == ast.F32 {
            sz = 4
        }
        return sz
    }
    return 8
}

fn registerStrings(){
    for(var : currentParser.strs){
        CreateGlobalString(var)
    }
}

fn registerGcMList()
{
    emitDataAlign(8)
    writeln("    .globl gc.ms.entry")
    writeln("gc.ms.entry:")
    writeln("   .quad gc.ms.end")


    //append other package moudle
    for pkg : package.packages {
        if !pkg.hasGcMoudle() {
            continue
        }
        writeln("   .quad %s",pkg.gc_moudles)
    }

    emitDataAlign(8)
    writeln("    .globl gc.ms.end")
    writeln("gc.ms.end:")
    writeln("   .quad 0")
}

func registerVars(){
    utils.debug("compile.registerVars()")
    writeln("    .globl %s", currentParser.filenameid)
    writeln("%s:", currentParser.filenameid)
    writeln("    .string \"%s\"",currentParser.filepath)

    if currentParser == main_parser {
        registerGcMList()
    }
    pkg = currentParser.pkg
    //skip no gvars parser
    if std.len(currentParser.gvars) == 0 {
        return true
    }

    if pkg.fparser == currentParser {
        emitDataAlign(8)
        writeln("    .globl %s", pkg.gc_moudles)
        writeln("%s:", pkg.gc_moudles)
        writeln("    .quad %s",currentParser.gstartvar())
    }

    //moudle start
    emitDataAlign(8)
    writeln("    .globl %s", currentParser.gstartvar())
    writeln("%s:", currentParser.gstartvar())
    writeln("    .quad %s",currentParser.gendvar())

    for(name,v : currentParser.gvars){
        gname = currentParser.getpkgname() + "_" + name
        emitDataAlign(globalVarDataAlign(v, currentParser))
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

    //entry end
    emitDataAlign(8)
    writeln("    .globl %s", currentParser.gendvar())
    writeln("%s:", currentParser.gendvar())
    if currentParser.next != null {
        writeln("    .quad %s", currentParser.next.gstartvar())
    }else{
        writeln("    .quad 0")
    }
}
func CreateGlobalString(var){
    if var.name == "" {
        var.check(false,"static string not compute")
    }
    // Strings stay byte-packed; following data labels must emitDataAlign.
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

        emitDataAlign(8)
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
            //future
            if fc.isasync()
                writeln("   .quad %d",2 * 8)
            else
                writeln("   .quad %d",std.len(fc.params_order_var) * 8)

            writeln("   .quad %d",fc.mcount)
            writeln("   .quad %d", (fc.mcount - 1) * 8)

            if fc.isasync()
                writeln("   .long %d",2)
            else
                writeln("   .long %d",std.len(fc.params_order_var))
            
            if fc.isasync()
                writeln("   .long %d",fc.asyncst.size)
            else
                writeln("   .long 0")
            writeln("   .quad %d" , fc.argsmem())
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

// Emit api vtables.
//
// parse2 clears every struct's order_funcs; parse3 walks packages in hash order.
// A cross-pkg `impl pkg.Api for S` that runs before the API package's FunctionPhase
 // snapshots an empty order_funcs into ApiImpl.funcs, so codegen used to emit
// empty apitl labels (asmer then dies on `.global`/`.text` after the label).
// Resolve .quad slots from the API's final order_funcs + impl getFunc at emit time.
fn registerApiTable(){
    for st : currentParser.structs {
        if st.isasync continue
        if st.asyncobj continue
        if std.len(st.apis) == 0
            continue
        
        for it : st.apis {
            tbptr = st.apiname(it.name)
            emitDataAlign(8)
            writeln("    .global %s",tbptr)
            writeln("%s:",tbptr)

            apiDef = null
            for pkg : package.packages {
                cand = pkg.getStruct(it.name)
                if cand == null || !cand.isapi
                    continue
                if apiDef == null || std.len(cand.order_funcs) > std.len(apiDef.order_funcs) {
                    apiDef = cand
                }
            }

            if apiDef != null && std.len(apiDef.order_funcs) > 0 {
                for apiFn : apiDef.order_funcs {
                    if apiFn == null continue
                    implFn = st.getFunc(apiFn.name)
                    if implFn != null {
                        writeln("   .quad %s",implFn.fullname())
                    }else if apiFn.hasBlock {
                        writeln("   .quad %s",apiFn.fullname())
                    }
                }
            }else{
                for fc : it.funcs {
                    writeln("   .quad %s",fc.fullname())
                }
            }
        }
    }

}

fn registerFutures(){
    for st : currentParser.structs {
        if !st.isasync continue
        if st.asyncobj continue //skip class future member func

        pollf = st.getPoll()
        if pollf == null {
            utils.error("future not impl poll")
        }
        virtname = st.futurepollname()
        emitDataAlign(8)
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
