use std
use std.regex
use compiler.utils
use compiler.ast
use compiler.parser
use compiler.compile
use os
use string
use fmt

// RFC110: package mode from the nearest tu.mod (dyn|static|mixed); no manifest => dyn.
// mixed is explicit-only (test suites). Tags live in parent compiler.parser (parser.tu).

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
    // RFC110: Mixed until loadMode runs (unchecked internal packages); loadMode sets the real mode.
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
    // RFC110: Mixed until loadMode runs; loadMode sets the real mode.
    this.pkg_mode = parser.PkgModeMixed

}

func pkg_dir_has_tu(dir) {
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
func cwd_pkg_usable(dir, pkg_path) {
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

func pkgmode_push_tok(toks, cur) {
    if cur != "" && cur != null {
        toks[] = cur
    }
}

func pkgmode_next_tok(toks, idx) {
    if idx >= std.len(toks) {
        ast.parse_err("pkgmode: manifest truncated, expect %s\n", "token")
    }
    v = toks[idx]
    return v, idx + 1
}

// RFC114: mod subtree path validation. Legal: [A-Za-z0-9_-] segments joined
// by '/'; no empty segment (leading/trailing '/' or "//"), no "." or "..".
func pkgmode_valid_path(p) {
    if p == null || p == "" {
        return false
    }
    seg = 0
    i = 0
    n = std.len(p)
    while i < n {
        c = p[i]
        if c == '/' {
            if seg == 0 {
                return false
            }
            seg = 0
            i += 1
            continue
        }
        ok = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
        ok = ok || (c >= '0' && c <= '9') || c == '_' || c == '-'
        if !ok {
            return false
        }
        seg += 1
        i += 1
    }
    if seg == 0 {
        return false
    }
    return true
}

// RFC114: one manifest object per tu.mod — default mode + mod overrides.
class TuModManifest {
    def  = 0
    mods = {} // subtree prefix (relative to manifest dir) -> mode
}

// RFC114: parse mode value; unknown values are hard errors.
func pkgmode_parse_mode(file, val) {
    if val == "dyn" {
        return parser.PkgModeDyn
    }
    if val == "static" {
        return parser.PkgModeStatic
    }
    // mixed only via explicit declaration (test suites); never checked.
    if val == "mixed" {
        return parser.PkgModeMixed
    }
    ast.parse_err("pkgmode: manifest %s unknown mode '%s'\n", file, val)
    return parser.PkgModeMixed
}

// RFC114: parse one tu.mod manifest (the single project-root manifest).
// Grammar: package { mode X } followed by 0..n top-level mod <path> { mode X }.
// Strict: unknown attrs/values, bad paths, duplicates, trailing tokens all fail.
func parseTuMod(file) {
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
    mf = new TuModManifest()
    has_mode = false
    // package block: only the mode attribute, up to this block's '}'
    loop {
        tok, idx = pkgmode_next_tok(toks, idx)
        if tok == "}" break
        if tok == "mode" {
            val = ""
            val, idx = pkgmode_next_tok(toks, idx)
            mf.def = pkgmode_parse_mode(file, val)
            has_mode = true
        } else {
            ast.parse_err("pkgmode: manifest %s unknown attribute '%s'\n", file, tok)
        }
    }
    if !has_mode {
        ast.parse_err("pkgmode: manifest %s missing 'mode'\n", file)
    }
    // RFC114: 0..n top-level mod blocks; a manifest may end with a mod block.
    while idx < std.len(toks) {
        tok, idx = pkgmode_next_tok(toks, idx)
        if tok != "mod" {
            ast.parse_err("pkgmode: manifest %s trailing tokens after '}'\n", file)
        }
        mpath = ""
        mpath, idx = pkgmode_next_tok(toks, idx)
        if !pkgmode_valid_path(mpath) {
            ast.parse_err("pkgmode: manifest %s invalid module path '%s'\n", file, mpath)
        }
        if utils.has(mpath, mf.mods) {
            ast.parse_err("pkgmode: manifest %s duplicate module '%s'\n", file, mpath)
        }
        tok, idx = pkgmode_next_tok(toks, idx)
        if tok != "{" {
            ast.parse_err("pkgmode: manifest %s expect '{' after module '%s'\n", file, mpath)
        }
        has_mmode = false
        loop {
            tok, idx = pkgmode_next_tok(toks, idx)
            if tok == "}" break
            if tok == "mode" {
                val = ""
                val, idx = pkgmode_next_tok(toks, idx)
                mf.mods[mpath] = pkgmode_parse_mode(file, val)
                has_mmode = true
            } else {
                ast.parse_err("pkgmode: manifest %s unknown module attribute '%s'\n", file, tok)
            }
        }
        if !has_mmode {
            ast.parse_err("pkgmode: manifest %s module '%s' missing 'mode'\n", file, mpath)
        }
    }
    return mf
}

// RFC114: manifest cache keyed by absolute manifest path — parsed once per compile.
tumod_cache = {}

// RFC114: longest-prefix hit — exact match first, then strip trailing segments;
// no hit anywhere -> manifest default. mods keys are non-empty, rel=="" falls through.
func pkgmode_resolve(mf, rel) {
    r = rel
    loop {
        if utils.has(r, mf.mods) {
            return mf.mods[r]
        }
        pos = -1
        i = 0
        n = std.len(r)
        while i < n {
            if r[i] == '/' {
                pos = i
            }
            i += 1
        }
        if pos < 0 break
        // r[0..pos] (string.sub is start-index only, so build the prefix here)
        head = ""
        j = 0
        while j < pos {
            head = head + r[j]
            j += 1
        }
        r = head
    }
    return mf.def
}

// RFC114: single-manifest rule — walking up from the anchor, any manifest found
// above is a hard error. User side only (main package / cwd-resolved packages);
// the stdroot universe is exempt so old per-package installs keep working.
func pkgmode_single_check(anchor) {
    dir = anchor
    for i = 0; i < 24; i += 1 {
        dir = utils.path_dirname(dir)
        if dir == "" || dir == "/" break
        f = utils.path_join(dir, "tu.mod")
        if std.is_file(f) {
            ast.parse_err("pkgmode: only one tu.mod per project: %s/tu.mod nested under %s/tu.mod\n", anchor, dir)
        }
    }
}

// RFC114: the project anchor is the nearest tu.mod walking up (cap 24); its
// manifest governs the whole subtree via longest-prefix mod matching.
// enforce_single=false skips the nested-manifest check (stdroot resolution).
Package::loadMode(abpath, enforce_single) {
    dir = abpath
    anchor = ""
    found = false
    for i = 0; i < 24; i += 1 {
        f = utils.path_join(dir, "tu.mod")
        if std.is_file(f) {
            anchor = dir
            found = true
            break
        }
        dir = utils.path_dirname(dir)
        if dir == "" || dir == "/" break
    }
    if !found {
        this.pkg_mode = parser.PkgModeDyn
        return
    }
    if enforce_single {
        pkgmode_single_check(anchor)
    }
    key = utils.path_join(anchor, "tu.mod")
    mf = null
    if utils.has(key, tumod_cache) {
        mf = tumod_cache[key]
    } else {
        mf = parseTuMod(key)
        tumod_cache[key] = mf
    }
    // Subtree path of this package relative to the anchor (walked up from it)
    rel = ""
    alen = std.len(anchor)
    nlen = std.len(abpath)
    if nlen > alen && utils.str_starts_with(abpath, anchor) && abpath[alen] == '/' {
        rel = string.sub(abpath, alen + 1)
    }
    this.pkg_mode = pkgmode_resolve(mf, rel)
}

Package::parse()
{

    abpath = utils.pwd()
    abpath += "/" + this.path
    utils.debugf("found import.start parser.. %s",abpath)

    if cwd_pkg_usable(abpath, this.path) {
        // RFC114: cwd-resolved packages are user-side -> enforce the single
        // project manifest rule.
        this.loadMode(abpath, true)
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
            if last != '/' && last != '\\' {
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
    err = utils.pkgfs_list_package_tu(this.path)
    names = utils.pkgfs_take_list_cache()
    if err != 0 || std.len(names) <= 0 {
        utils.error(fmt.sprintf("pkgfs: no .tu in stdlib package %s mode=%d", this.path, utils.pkgfs_mode))
    }
    mode_root = utils.pkgfs_mode_root(this.path)
    if mode_root == "" {
        mode_root = std_dir
    }
    // RFC114: stdroot universe (embed stdroot / copkg / TU_STD) is exempt from
    // the single-manifest check so old per-package installs keep working.
    this.loadMode(mode_root, false)
    utils.notice("start scan pkgfs package:%s dir:%s",this.path,std_dir)
    for name : names {
        scan_path = utils.pkgfs_scan_filepath(std_dir, name)
        disk_path = utils.pkgfs_disk_source_path(std_dir, this.path, name)
        if !std.is_file(disk_path) {
            utils.error("pkgfs: missing " + disk_path)
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
    if utils.has(name,this.structs) {
        this.structs[name] = f
        return true
    }
    this.structs[name] = f
}

Package::addAsyncStruct(name, f)
{

    f.isasync = true
    if utils.has(name,this.structs) {
        this.structs[name] = f
        return true
    }
    this.structs[name] = f
}

Package::getStruct(name)
{    
    if utils.has(name,this.structs) 
        return this.structs[name]
    return null
}
Package::addStructFunc(name , fcname , f, s)
{
    if utils.has(name,this.structs) {
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
    if utils.has(name,this.classes) {
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
    return utils.has(name,this.classes)
}

Package::getGlobalVar(name){
    for(p : this.parsers){
        if utils.has(name,p.gvars){
            return p.gvars[name]
        }
    }
    return null
}
Package::getClass(name)
{    
    if utils.has(name,this.classes) 
        return this.classes[name]
    return null
}

Package::checkClassFunc(name , fc)
{
    if utils.has(name,this.classes)
        return false
    cs = this.classes[name]
    for(var : cs.funcs){
        if var.name == fc
            return true
    }
    return false
}
