
out    # current file fd
parser # current parser
ctx # arr[Context*,Context*..]

func init(filename) 
{
    utils.debug("Compiler::init:",filename)
    ctx = [] # arr[Context*,Context*]

    pkg = new parser.Packge("main","main",false)

    mparser = new parser.Parser(filename,pkg,"main","main")
    mparser.fileno = 1
    mparser.parser()    # token parsering

    pkg.parsers[filename] = mparser

    parser.packages["main"] = pkg

    //check runtime has been parsered
    if std.exist("runtime",parser.packages) {
        pkg = new parser.Package("runtime","runtime",false) 
        //recursively scan code files
        if !pkg.parse() utils.error("AsmError: runtime lib import failed")
        parser.packages["runtime"] = pkg 
    }
}
func writeln(fmtstr<runtime.Value>, args , _1 , _2 , _3 , _4) {
    s<i8*> = string.stringempty()
    initlen<u64> = string.stringlen(s)
    f<i8*> = fmtstr.data
    i<u64> = 0
    db<i32> = 2
    single<i32> = 1
    s = string.stringMakeRoomFor(s, initlen + std.strlen(fmtstr.data) * db)
    i = initlen 
    curr<runtime.Value> = 0

 	pp<u64*> = &args
	stack<i32> = 5   
    while *f != null {
        next<i8> = 0
        str<i8*> = 0
        l<u64>   = 0
        num<i64> = 0
        unum<u64> = 0
        if string.stringavail(s) == runtime.Zero {
            s = string.stringMakeRoomFor(s,single)
        }
        match *f 
        {
            '%': {
                f   += 1
                next = *f
                match next {
                    's' | 'S' :{
                        //init stack
                        curr = *pp
                        if stack < 1  pp += 8	else pp -= 8
                        //push end ---
                        //push rip
                        //push rbp
                        //mov %rdi ,-8(%rbp)
                        if stack == 1 {	pp = &fmtstr	pp += 24	}		
                        stack -= 1
                        //stack end
                        str = curr.data
                        if next == 's' 
                            l = std.strlen(str)
                        else 
                            l = string.stringlen(str)
                        if string.stringavail(s) < l {
                            s = string.stringMakeRoomFor(s,l)
                        }
                        std.memcpy(s + i,str,l)
                        string.stringinclen(s,l)
                        i += l
                    }
                    'i' | 'I' : {
                        //init stack
                        curr = *pp
                        if stack < 1  pp += 8	else pp -= 8
                        if stack == 1 {	pp = &fmtstr	pp += 24	}		
                        stack -= 1
                        //stack end
                        num = curr.data

                        buf_o<i8:21> = 0
                        buf<i8*> = &buf_o
                        l = string.stringll2str(buf,num)
                        if string.stringavail(s) < l {
                            s = string.stringMakeRoomFor(s,l)
                        }
                        std.memcpy(s + i,buf,l)
                        string.stringinclen(s,l)
                        i += l
                    }
                    'u' | 'U' : {
                        //init stack
                        curr = *pp
                        if stack < 1  pp += 8	else pp -= 8
                        if stack == 1 {	pp = &fmtstr	pp += 24	}		
                        stack -= 1
                        //stack end
                        unum = curr.data

                        buf_o<i8:21> = 0
                        buf<i8*> = &buf_o
                        l = string.stringull2str(buf,unum)
                        if string.stringavail(s) < l {
                            s = string.stringMakeRoomFor(s,l)
                        }
                        std.memcpy(s + i,buf,l)
                        string.stringinclen(s,l)
                        i += l
                    }
                    _ : {
                        # s[i++] = next
                        tp<i8*> = s + i
                        i += 1
                        *tp = next
                        string.stringinclen(s,single)
                    } 
                }
            }
            _ : {
                # s[i++] = *f
                tp<i8*> = s + i
                i += 1
                *tp = *f
                string.stringinclen(s,1)
            }
        }
        f += 1
    }
    tp<i8*> = s + i # s[i] = '\n'
    *tp = '\n'
    i += 1
    string.stringinclen(s,1)
    # s[i] = '\0'
    tp<i8*> = s + i # s[i] = '\0'
    *tp = 0
    out.NWrite(s)
}
