
use fmt
use os

func test_string()
{
    a = "stringa"
    b = "stringb"
    if  a != "stringa" {
        fmt.print("failed a == stringa ",a)
        os.exit(1)
    }
    if  b != "stringb" {
        fmt.print("failed b == stringb ",b)
        os.exit(1)
    }
    a += b

    if  a != "stringastringb" {
        fmt.print("failed a += b ",a)
        os.exit(1)
    }
    fmt.print("success string + string ",a)

}
func test_string_int(num,str){
    nstr = num + str + num
    if  nstr != "99test99" {
        fmt.println("failed num + str ",nstr)
        os.exit(1)
    }
    fmt.print("success num + str == ",nstr)
}
func test_index(){
    fmt.println("test string index")
    str = "abcde"
    if str[0] != 'a' os.die("stro[0] should be a")
    if str[1] != 'b' os.die("stro[1] should be b")
    if str[2] != 'c' os.die("stro[2] should be c")
    if str[3] != 'd' os.die("stro[3] should be d")
    if str[4] != 'e' os.die("stro[4] should be e")
    //out
    if str[5] != 0   os.die("stro[5] should be outbound")
    fmt.println("test string index success")
}
use string
func test_nativeop(){
    fmt.println("test string native memory operate")
    native<u8*> = "this is native const char *"
    wrap = string.new(native)
    if wrap == "this is not native const char *" {
        os.die("not should be here")
    }
    if wrap != "this is native const char *" {
        os.die("wrap failed")
    }
    fmt.println("test string native memory operate success")
}

// string_to_bits / string_from_bits / cstr_from_bits (library formal bridges).
fn test_string_bits_bridge(){
    fmt.println("test string bits bridge")
    src<string.String> = string.S(*"tu-lib-bits")
    path_bits<u64> = string.string_to_bits(src)
    if path_bits == 0 os.die("string_to_bits returned 0")
    cpath<i8*> = string.cstr_from_bits(path_bits)
    if cpath == null os.die("cstr_from_bits null")
    // Compare via string.new(cstr) — same pattern as native string tests.
    if string.new(cpath) != "tu-lib-bits" os.die("cstr_from_bits content mismatch")
    back<string.String> = string.string_from_bits(path_bits)
    if string.new(back.str()) != "tu-lib-bits" os.die("string_from_bits roundtrip mismatch")
    empty_s<string.String> = string.S(*"")
    empty_bits<u64> = string.string_to_bits(empty_s)
    empty_p<i8*> = string.cstr_from_bits(empty_bits)
    if empty_p == null os.die("empty cstr null")
    if *empty_p != 0 os.die("empty cstr not NUL")
    fmt.println("test string bits bridge success")
}

// string.Cursor static core: runs, blanks/lines, rollback, quoted errors.
fn test_cursor_static(){
    fmt.println("test string cursor static")
    e<string.Cursor> = string.cursor_from_string("")
    if e.peek() != -1 os.die("empty cursor peek should be EOF")
    if e.next() != -1 os.die("empty cursor next should be EOF")

    c<string.Cursor> = string.cursor_from_string("ab_1 0x1F\n  3.5 \"q\\\"x\" tail")
    id = c.take_run(string.CURSOR_IDENT)
    if id != "ab_1" os.die("ident run mismatch")
    ch<i32> = c.skip_space()
    if ch != '0' os.die("skip_space should stop at 0")
    lead = c.take_run(string.CURSOR_DIGIT)
    hex = c.take_run(string.CURSOR_ALNUM)
    if lead + hex != "0x1F" os.die("hex runs mismatch")
    if c.line != 1 os.die("line should still be 1")
    ch = c.skip_space()
    if c.line != 2 os.die("newline should bump line")
    if c.column != 2 os.die("column should count bytes after newline")
    save<i32> = c.pos
    ip = c.take_run(string.CURSOR_DIGIT)
    if c.next() != '.' os.die("expected dot")
    frac = c.take_run(string.CURSOR_DIGIT)
    if ip + "." + frac != "3.5" os.die("float runs mismatch")
    c.pos = save
    again = c.take_run(string.CURSOR_DIGIT)
    if again != "3" os.die("rollback via pos failed")
    c.next()
    c.take_run(string.CURSOR_DIGIT)
    c.skip_space()
    if c.next() != '"' os.die("expected opening quote")
    qerr<i32>, qbody<u64> = c.take_quoted('"')
    if qerr != 0 os.die("terminated quote should succeed")
    if c.peek() != ' ' os.die("closing quote should be consumed")
    if c.slice(save, save + 3) != "3.5" os.die("slice mismatch")

    u<string.Cursor> = string.cursor_from_string("\"abc\\")
    u.next()
    uerr<i32>, ubody<u64> = u.take_quoted('"')
    if uerr != 1 os.die("unterminated quote should fail")
    fmt.println("test string cursor static success")
}

// string.cursor_text / CursorObj: same lexing surface without mem annotations.
func test_cursor_dyn(){
    fmt.println("test string cursor dyn")
    e = string.cursor_text("")
    if e.next() != -1 os.die("dyn empty cursor should be EOF")
    if e.size() != 0 os.die("dyn empty size")

    c = string.cursor_text("ab_1 0x1F\n  3.5 \"q\\\"x\" // note\nz")
    if c.peek() != 'a' os.die("dyn peek")
    if c.peekAt(1) != 'b' os.die("dyn peekAt")
    if c.ident() != "ab_1" os.die("dyn ident")
    if c.skipSpace() != '0' os.die("dyn skipSpace")
    hex = c.digits() + c.alnum()
    if hex != "0x1F" os.die("dyn hex")
    c.skipSpace()
    if c.line() != 2 os.die("dyn line")
    if c.column() != 2 os.die("dyn column")
    save = c.pos()
    num = c.digits()
    num += c.next()
    num += c.digits()
    if num != "3.5" os.die("dyn float")
    c.setPos(save)
    if c.digits() != "3" os.die("dyn rollback")
    c.setPos(save + 3)
    c.skipSpace()
    if c.next() != '"' os.die("dyn opening quote")
    err, body = c.quoted('"')
    if err != 0 os.die("dyn quoted err")
    if body != "q\\\"x" os.die("dyn quoted body keeps escapes")
    c.skipSpace()
    c.skipLine()
    if c.peek() != '\n' os.die("dyn skipLine stops before newline")
    if c.skipSpace() != 'z' os.die("dyn after comment")
    c.next()
    if c.next() != -1 os.die("dyn EOF")
    if c.slice(0, 4) != "ab_1" os.die("dyn slice")

    u = string.cursor_text("\"abc")
    u.next()
    uerr, ubody = u.quoted('"')
    if uerr != 1 os.die("dyn unterminated quote")
    if ubody != "abc" os.die("dyn partial body")

    ferr, f = string.cursor_open_file("no/such/cursor_file.tu")
    if ferr != 1 os.die("missing file should fail")
    if f != null os.die("missing file cursor should be null")
    fmt.println("test string cursor dyn success")
}

//native memory operte
func main(){
    test_string()
    test_string_int(99,"test")
    test_index()
    test_nativeop()
    test_string_bits_bridge()
    test_cursor_static()
    test_cursor_dyn()
}
