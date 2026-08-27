use std
use std.regex
use compiler.utils
use compiler.ast
use compiler.parser
use compiler.compile
use os
use string
use fmt

// RFC110: package mode from tu.mod; only dyn|static. Default dyn when absent.
// Tags live in parent compiler.parser (parser.tu); reference as parser.PkgMode*.

class Package {
    parsers = {} // parsers map[filepath + name] = parser
    package = name
    path    = path
    full_package = path
    fparser    = null
    gc_moudles = ""

    inits = []   // string,func
    initid = 0
    initvars 
    classes = {} // map{string : Class  }
    structs = {} // map{string : Struct }
    impls   = {}
    imports = {} // map[string: string}
    gstrs = {}
    embeds = []

    cfgs    = new ast.ConfigOpts()
    // RFC110: nearest-ancestor tu.mod; migration default Mixed (no pkgmode checks).
    pkg_mode = parser.PkgModeMixed
}

Package::add_embed(set) {
    this.embeds[] = set
}

Package::init(name , path , multi) {
    utils.debugf("parser.package.Package::init() name:%s path:%s multi:%d",
        name,path,multi
    )
    // Do not self-map short name into imports (poisons top-level io/sys).
    if multi {
        this.path = regex.replace(path,"_","/")
    }

    this.gc_moudles = "gc." + this.full_package + ".ms"
    this.fparser = null
    // RFC110: migration default Mixed; explicit tu.mod overrides.
    this.pkg_mode = parser.PkgModeMixed

}

fn pkg_dir_has_tu(dir) {
    names = utils.list_dir_basenames(dir)
    for name : names {
        nlen = std.len(name)
        if nlen >= 3 && string.sub(name, nlen - 3) == ".tu" {
            return true
        }
    }
    return false
}

// cwd/<pkg> is usable only if it has .tu, and runtime also has the host overlay
// (linux.tu / darwin.tu / windows.tu). Scan still keeps the --target overlay
// file, not the host one: Darwin cwd with both files + --target=linux parses
// linux.tu (Palloc). Repo runtime/ is Unix-only; without the host-file check
// Darwin default would compile linux-only host_os.
fn cwd_pkg_usable(dir, pkg_path) {
    if !std.is_dir(dir) {
        return false
    }
    if !pkg_dir_has_tu(dir) {
        return false
    }
    if pkg_path == "runtime" {
        return std.is_file(utils.path_join(dir, utils.host_runtime_overlay()))
    }
    return true
}

// RFC110 migration: no tu.mod => Mixed (no checks). static/dyn only via explicit manifest.
fn pkgmode_engine_default(pkgpath) {
    return parser.PkgModeMixed
}

fn pkgmode_push_tok(toks, cur) {
    if cur != "" && cur != null {
        toks[] = cur
    }
}

fn pkgmode_next_tok(toks, idx) {
    if idx >= std.len(toks) {
        ast.parse_err("pkgmode: manifest truncated, expect %s\n", "token")
    }
    v = toks[idx]
    return v, idx + 1
}

// RFC110: parse tu.mod manifest; migration accepts mixed; final state dyn|static only (Step5).
fn parseTuMod(file) {
    if !std.is_file(file) {
        ast.parse_err("pkgmode: cannot open manifest %s\n", file)
    }
    fs = new std.File(file)
    if !fs.IsOpen() {
        ast.parse_err("pkgmode: cannot open manifest %s\n", file)
    }
    content = fs.ReadAll()
    fs.Close()
    toks = []
    cur = ""
    pos = 0
    n = std.len(content)
    while pos < n {
        ch = content[pos]
        if ch == '/' && pos + 1 < n && content[pos + 1] == '/' {
            while pos < n && content[pos] != '\n' {
                pos += 1
            }
            pkgmode_push_tok(toks, cur)
            cur = ""
            continue
        }
        if ch == '{' || ch == '}' {
            pkgmode_push_tok(toks, cur)
            cur = ""
            if ch == '{' {
                toks[] = "{"
            } else {
                toks[] = "}"
            }
            pos += 1
            continue
        }
        if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
            pkgmode_push_tok(toks, cur)
            cur = ""
            pos += 1
            continue
        }
        cur = cur + ch
        pos += 1
    }
    pkgmode_push_tok(toks, cur)

    idx = 0
    tok = ""
    tok, idx = pkgmode_next_tok(toks, idx)
    if tok != "package" {
        ast.parse_err("pkgmode: manifest %s must start with 'package'\n", file)
    }
    tok, idx = pkgmode_next_tok(toks, idx)
    if tok != "{" {
        ast.parse_err("pkgmode: manifest %s expect '{' after 'package'\n", file)
    }
    m = parser.PkgModeMixed
    has_mode = false
    loop {
        tok, idx = pkgmode_next_tok(toks, idx)
        if tok == "}" break
        if tok == "mode" {
            val = ""
            val, idx = pkgmode_next_tok(toks, idx)
            if val == "dyn" {
                m = parser.PkgModeDyn
            } else if val == "static" {
                m = parser.PkgModeStatic
            } else if val == "mixed" {
                m = parser.PkgModeMixed
            } else {
                ast.parse_err("pkgmode: manifest %s unknown mode '%s'\n", file, val)
            }
            has_mode = true
        } else {
            ast.parse_err("pkgmode: manifest %s unknown attribute '%s'\n", file, tok)
        }
    }
    if idx < std.len(toks) {
        ast.parse_err("pkgmode: manifest %s trailing tokens after '}'\n", file)
    }
    if !has_mode {
        ast.parse_err("pkgmode: manifest %s missing 'mode'\n", file)
    }
    return m
}

// RFC110: nearest tu.mod wins; absent manifest stays Mixed (no checks).
Package::loadMode(abpath) {
    this.pkg_mode = parser.PkgModeMixed
    depth = 1
    for i = 0; i < std.len(this.path); i += 1 {
        if this.path[i] == '/' {
            depth += 1
        }
    }
    if depth < 8 depth = 8
    dir = abpath
    for i = 0; i < depth; i += 1 {
        f = utils.path_join(dir, "tu.mod")
        if std.is_file(f) {
            this.pkg_mode = parseTuMod(f)
            return
        }
        dir = utils.path_dirname(dir)
        if dir == "" || dir == "/" break
    }
    eng = pkgmode_engine_default(this.path)
    if eng != parser.PkgModeMixed {
        this.pkg_mode = eng
    }
}

Package::parse()
{

    abpath = utils.pwd()
    abpath += "/" + this.path
    utils.debugf("found import.start parser.. %s",abpath)

    if cwd_pkg_usable(abpath, this.path) {
        this.loadMode(abpath)
        utils.notice("start scan the package:%s",abpath)
        names = utils.list_dir_basenames(abpath)
        if std.len(names) <= 0 {
            utils.error("file|dir not exist " +abpath)
        }
        for name : names {
            if name == "." || name == ".." {
                continue
            }
            nlen = std.len(name)
            if nlen < 3 {
                continue
            }
            if string.sub(name, nlen - 3) != ".tu" {
                continue
            }
            if this.path == "runtime" {
                want = utils.overlay_runtime_name(utils.pkgfs_target)
                if name == "linux.tu" || name == "darwin.tu" || name == "windows.tu" {
                    if name != want {
                        continue
                    }
                }
            }
            filepath = abpath
            last = filepath[std.len(filepath) - 1]
            bs = utils.char1(92.(i8))
            if last != '/' && last != bs {
                filepath = filepath + "/"
            }
            filepath = utils.norm_slash(filepath + name)
            if !std.is_file(filepath) {
                continue
            }
            p = new parser.Parser(filepath,this)
            p.fileno = compile.fileno
            this.parsers[filepath] = p
            utils.notice("start parse the package:%s file:%s",abpath,filepath)
            p.parse()
        }
        return true
    }

    utils.debugf("Parser: cwd package missing; pkgfs stdlib %s",this.path)
    std_dir = utils.pkgfs_resolve_std_dir(this.path)
    if std_dir == "" {
        utils.debugf("Parser: pkgfs could not resolve :%s",this.path)
        return false
    }
    err<i32> = utils.pkgfs_list_package_tu(this.path)
    names = utils.pkgfs_take_list_cache()
    if err != 0 || std.len(names) <= 0 {
        utils.error(fmt.sprintf("pkgfs: no .tu in stdlib package %s mode=%d", this.path, int(utils.pkgfs_mode)))
    }
    mode_root = utils.pkgfs_mode_root(this.path)
    if mode_root == "" {
        mode_root = std_dir
    }
    this.loadMode(mode_root)
    utils.notice("start scan pkgfs package:%s dir:%s",this.path,std_dir)
    for name : names {
        scan_path = utils.pkgfs_scan_filepath(std_dir, name)
        disk_path = ""
        if utils.pkgfs_mode == utils.PKGFS_MODE_EMBED {
            disk_path = utils.pkgfs_materialize_embed(std_dir, this.path, name)
            if disk_path == "" {
                utils.error("pkgfs: materialize failed " + scan_path)
            }
        } else {
            disk_path = utils.pkgfs_disk_source_path(std_dir, this.path, name)
            if !std.is_file(disk_path) {
                utils.error("pkgfs: missing " + disk_path)
            }
        }
        p = new parser.Parser(disk_path, this)
        p.fileno = compile.fileno
        this.parsers[scan_path] = p
        utils.notice("start parse pkgfs file:%s",scan_path)
        p.parse()
    }
    return true
}
Package::getFullName(){
    return this.full_package
}
Package::geninitid(){
    id = this.initid
    this.initid += 1
    return id
}
Package::getFunc(name , is_extern){
    for(p : this.parsers){
        ret  = p.getFunc(name,is_extern)
        if ret != null return ret
    }
    return null
}

Package::addClass(name, f)
{
    if this.classes[name] {
        if this.classes[name].type_id != 0 {
            f.parser.panic("class define duplicate " + name)
        }
        for(i : this.classes[name].funcs)
            f.funcs[] = i
    }
    f.type_id = ast.getTypeId()
    this.classes[name] = f
}

Package::addStruct(name, f)
{
    if std.exist(name,this.structs) {
        this.structs[name] = f
        return true
    }
    this.structs[name] = f
}

Package::addAsyncStruct(name, f)
{

    f.isasync = true
    if std.exist(name,this.structs) {
        this.structs[name] = f
        return true
    }
    this.structs[name] = f
}

Package::getStruct(name)
{    
    if std.exist(name,this.structs) 
        return this.structs[name]
    return null
}
Package::addStructFunc(name , fcname , f, s)
{
    if std.exist(name,this.structs) {
        this.structs[name].funcs[fcname] = f
        this.structs[name].order_funcs[] = f
        return null
    }
    this.structs[name] = s
    s.funcs[fcname] = f
    s.order_funcs[] = f
}
Package::addClassFunc(name,f,p)
{
    if std.exist(name,this.classes) {
        this.classes[name].funcs[] = f
        return null
    }
    
    s = new ast.Class(this.package)
    s.name  = name
    s.parser = p
    s.funcs[] = f
    this.classes[name] = s
}
Package::hasClass(name)
{
    return std.exist(name,this.classes)
}

Package::getGlobalVar(name){
    for(p : this.parsers){
        if std.exist(name,p.gvars){
            return p.gvars[name]
        }
    }
    return null
}
Package::getClass(name)
{    
    if std.exist(name,this.classes) 
        return this.classes[name]
    return null
}

Package::checkClassFunc(name , fc)
{
    if std.exist(name,this.classes)
        return false
    cs = this.classes[name]
    for(var : cs.funcs){
        if var.name == fc
            return true
    }
    return false
}
