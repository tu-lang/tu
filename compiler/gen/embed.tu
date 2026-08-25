// RFC-107: compile-time embed() file collection and .data emission.

use std
use fmt
use compiler.ast
use compiler.compile
use compiler.utils

// Single embedded file: logical path, absolute path, emitted symbol names.
class EmbedFile {
	logical = ""
	abs_path = ""
	blob_sym = ""
	name_sym = ""
	size = 0
	content_hash = 0
}

// One embed(...) call: collected files + metadata.
class EmbedSet {
	id = 0
	entries_sym = ""
	files = []
	roots = []
	src_dir = ""
	single_file = false
	owner = null
}

EmbedKindAuto = 0
EmbedKindString = 1
EmbedKindFS = 2

func embed_make_absolute(path) {
	p = utils.norm_slash(path)
	if p == "" {
		return p
	}
	if p[0] != '/' {
		pwd = utils.pwd()
		if pwd != "" && pwd != "." {
			p = utils.path_join(pwd, p)
			p = utils.norm_slash(p)
		}
	}
	return p
}

func embed_is_abs_path(p) {
	return p != "" && p[0] == '/'
}

func embed_path_has_dotdot(p) {
	i = 0
	n = std.len(p)
	while i < n {
		j = i
		while j < n && p[j] != '/' {
			j += 1
		}
		part = ""
		k = i
		while k < j {
			part += p[k]
			k += 1
		}
		if part == ".." {
			return true
		}
		if j >= n {
			break
		}
		i = j + 1
	}
	return false
}

func embed_should_skip_dirent(name) {
	if name == "" || name == "." || name == ".." {
		return true
	}
	if name[0] == '.' || name[0] == '_' {
		return true
	}
	return false
}

func embed_file_size(path) {
	f = new std.File(path, "r")
	if f == null || !f.IsOpen() {
		return 0
	}
	return f.Size()
}

func embed_add_one_file(abs, logical, out, filepath, line, column) {
	if !std.is_file(abs) {
		ast.parse_err(fmt.sprintf(
			"%s:%d:%d: embed: cannot read %s\n",
			filepath, line, column, abs
		))
		return
	}
	f = new EmbedFile()
	f.logical = logical
	f.abs_path = embed_make_absolute(abs)
	f.size = embed_file_size(abs)
	out[] = f
}

func embed_walk_dir(abs_dir, logical_prefix, out, filepath, line, column) {
	if !std.is_dir(abs_dir) {
		ast.parse_err(fmt.sprintf(
			"%s:%d:%d: embed: cannot open directory %s\n",
			filepath, line, column, abs_dir
		))
		return
	}
	names = utils.list_dir_basenames(abs_dir)
	for name : names {
		if embed_should_skip_dirent(name) {
			continue
		}
		abs = utils.path_join(abs_dir, name)
		logical = name
		if logical_prefix != "" {
			logical = utils.path_join(logical_prefix, name)
		}
		if std.is_dir(abs) {
			embed_walk_dir(abs, logical, out, filepath, line, column)
		} else if std.is_file(abs) {
			embed_add_one_file(abs, logical, out, filepath, line, column)
		}
	}
}

func embed_collect(filepath, owner, paths, line, column) {
	if std.len(paths) == 0 {
		ast.parse_err(fmt.sprintf(
			"%s:%d:%d: embed() needs at least one string path\n",
			filepath, line, column
		))
		return null
	}
	set = new EmbedSet()
	set.roots = paths
	set.src_dir = utils.path_dirname(filepath)
	all_single_files = true
	for rel : paths {
		if rel == "" {
			ast.parse_err(fmt.sprintf(
				"%s:%d:%d: embed: empty path\n",
				filepath, line, column
			))
			return null
		}
		if embed_is_abs_path(rel) || embed_path_has_dotdot(rel) {
			ast.parse_err(fmt.sprintf(
				"%s:%d:%d: embed: path must be relative and must not contain '..': %s\n",
				filepath, line, column, rel
			))
			return null
		}
		abs = utils.path_join(set.src_dir, rel)
		if std.is_dir(abs) {
			all_single_files = false
			embed_walk_dir(abs, rel, set.files, filepath, line, column)
		} else if std.is_file(abs) {
			embed_add_one_file(abs, rel, set.files, filepath, line, column)
		} else {
			ast.parse_err(fmt.sprintf(
				"%s:%d:%d: embed: file or directory not found: %s\n",
				filepath, line, column, rel
			))
			return null
		}
	}
	if std.len(set.files) == 0 {
		ast.parse_err(fmt.sprintf(
			"%s:%d:%d: embed: no files matched\n",
			filepath, line, column
		))
		return null
	}
	set.single_file = all_single_files && std.len(paths) == 1 && std.len(set.files) == 1
	set.owner = owner
	return set
}

func embed_assign_symbols(set, pkg_sig, seq) {
	set.id = seq
	set.entries_sym = fmt.sprintf("embed.entries.%s.%d", pkg_sig, seq)
	i = 0
	while i < std.len(set.files) {
		f = set.files[i]
		f.blob_sym = fmt.sprintf("embed.blob.%s.%d.%d", pkg_sig, seq, i)
		f.name_sym = fmt.sprintf("embed.name.%s.%d.%d", pkg_sig, seq, i)
		i += 1
	}
}

func embed_emit_set(set) {
	for f : set.files {
		compile.writeln("    .globl %s", f.name_sym)
		compile.writeln("%s:", f.name_sym)
		compile.writeln("    .string \"%s\"", f.logical)
	}
	for f : set.files {
		compile.writeln("    .globl %s", f.blob_sym)
		compile.writeln("%s:", f.blob_sym)
		compile.writeln("    .incbin \"%s\"", f.abs_path)
	}
	compile.emitDataAlign(8)
	compile.writeln("    .globl %s", set.entries_sym)
	compile.writeln("%s:", set.entries_sym)
	for f : set.files {
		compile.writeln("    .quad %s", f.name_sym)
		compile.writeln("    .quad %d", std.len(f.logical))
		compile.writeln("    .quad %s", f.blob_sym)
		compile.writeln("    .quad %d", f.size)
	}
}
