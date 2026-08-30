// Compile-time embed support: mem EmbedFS + dyn EmbedFSObj (RFC-107).
// Index entry layout (u64 x4): name_ptr, name_len, data_ptr, data_len.

use string
use std
use runtime

// Static handle: table points at embed.entries.* emitted by the compiler.
mem EmbedFS {
	u64 table
	i32 nentries
}

// Dynamic facade wraps mem EmbedFS so untyped `fs = embed(...)` can .read/.list.
class EmbedFSObj {
	inner
	func init(fs) {
		this.inner = fs
	}
}

// Heap-copy rodata bytes into a dyn string (safe if interior NULs).
fn embed_string(ptr<i8*>, len<u64>) {
	n<i32> = len.(i32)
	return string.newstringfromlen(ptr, n)
}

// Construct static EmbedFS.
fn embed_fs_new(table<u64>, count<i32>) EmbedFS {
	return new EmbedFS {
		table: table,
		nentries: count
	}
}

// Construct dyn object with read/list.
fn embed_fs_bits(fs<EmbedFS>) u64 {
	return fs
}

fn embed_fs_from_bits(bits<u64>) EmbedFS {
	return bits.(EmbedFS)
}

// Compiler ABI entry for embed() codegen (builtin.tu → runtime_embed_box). Do not
// change param types without updating compiler/gen/builtin.tu.
fn embed_box(table<u64>, count<i32>) {
	fs<EmbedFS> = embed_fs_new(table, count)
	return new EmbedFSObj(fs)
}

fn embed_entry_ptrs(table<u64>, i<i32>) (u64, u64, u64, u64) {
	base<u64*> = table
	off<i32> = i * 4
	o0<i32> = off
	o1<i32> = off + 1
	o2<i32> = off + 2
	o3<i32> = off + 3
	np<u64> = base[o0]
	nl<u64> = base[o1]
	dp<u64> = base[o2]
	dl<u64> = base[o3]
	return np, nl, dp, dl
}

fn embed_name_eq(np<u64>, nl<u64>, want_ptr<i8*>, want_len<i32>) i32 {
	wl<u64> = want_len.(u64)
	if nl != wl {
		return 0
	}
	a<u64> = np
	w<u64> = want_ptr
	if std.memcmp(a, w, nl) != 0 {
		return 0
	}
	return 1
}

// Linear search by path; 0 = hit.
fn embed_find(table<u64>, count<i32>, name_ptr<i8*>, name_len<i32>) (i32, i8*, u64) {
	i<i32> = 0
	z<i8*> = 0
	while i < count {
		np<u64>, nl<u64>, dp<u64>, dl<u64> = embed_entry_ptrs(table, i)
		if embed_name_eq(np, nl, name_ptr, name_len) != 0 {
			d<i8*> = dp
			return 0, d, dl
		}
		i += 1
	}
	return 1, z, 0.(u64)
}

// Dyn string → cstr pointer (Str buffer). Single return avoids (i8*,i32) ABI loss.
fn embed_dyn_name_ptr(name) i8* {
	z<i8*> = 0
	if name == null {
		return z
	}
	v<runtime.Value> = name
	if v.type != runtime.String {
		return z
	}
	return v.data
}

fn embed_dyn_name_len(name) i32 {
	if name == null {
		return 0
	}
	v<runtime.Value> = name
	if v.type != runtime.String {
		return 0
	}
	// Str buffer is NUL-terminated; type nl as u64 so return is native i32 (not dyn int*).
	p<i8*> = v.data
	nl<u64> = std.strlen(p)
	return nl.(i32)
}

EmbedFS::read(name) i32, i8*, u64 {
	p<i8*> = embed_dyn_name_ptr(name)
	n<i32> = embed_dyn_name_len(name)
	z<i8*> = 0
	if p == 0 {
		return 1, z, 0.(u64)
	}
	err<i32>, data<i8*>, lenu<u64> = embed_find(this.table, this.nentries, p, n)
	return err, data, lenu
}

EmbedFS::has(name) i32 {
	err<i32>, data<i8*>, lenu<u64> = this.read(name)
	if err == 0 {
		return 1
	}
	return 0
}

EmbedFS::count() i32 {
	return this.nentries
}

EmbedFS::entry(i<i32>) i32, i8*, u64, i8*, u64 {
	z<i8*> = 0
	if i < 0 || i >= this.nentries {
		return 1, z, 0.(u64), z, 0.(u64)
	}
	np<u64>, nl<u64>, dp<u64>, dl<u64> = embed_entry_ptrs(this.table, i)
	npp<i8*> = np
	dpp<i8*> = dp
	return 0, npp, nl, dpp, dl
}

// List helper; called only from export func embed_list body.
fn embed_mem_list(fs<EmbedFS>, dir) {
	prefix = ""
	if dir != null {
		prefix = dir
	}
	pre_p<i8*> = embed_dyn_name_ptr(prefix)
	pre_n<i32> = embed_dyn_name_len(prefix)
	if prefix == "" {
		pre_n = 0
	}
	arr = []
	t<u64> = fs.table
	c<i32> = fs.nentries
	i<i32> = 0
	while i < c {
		base<u64*> = t
		off<i32> = i * 4
		np<u64> = base[off]
		nl<u64> = base[off + 1]
		npp<i8*> = np
		nln<i32> = nl.(i32)
		name_s = string.newstringfromlen(npp, nln)
		if pre_n == 0 {
			arr[] = name_s
		} else {
			if nln > pre_n {
				w<u64> = pre_p
				pn<u64> = pre_n.(u64)
				if std.memcmp(np, w, pn) == 0 {
					sep_off<i32> = pre_n
					sep_ptr<u64> = np + sep_off.(u64)
					sep<i8*> = sep_ptr
					if *sep == '/' {
						arr[] = name_s
					}
				}
			} else if nln == pre_n {
				w<u64> = pre_p
				pn<u64> = pre_n.(u64)
				if std.memcmp(np, w, pn) == 0 {
					arr[] = name_s
				}
			}
		}
		i += 1
	}
	return 0, arr
}

export func embed_read(inner, name) {
	fs<EmbedFS> = inner.(EmbedFS)
	p<i8*> = embed_dyn_name_ptr(name)
	n<i32> = embed_dyn_name_len(name)
	z<i8*> = 0
	if p == 0 {
		return 1, ""
	}
	err<i32>, data<i8*>, lenu<u64> = embed_find(fs.table, fs.nentries, p, n)
	if err != 0 {
		return 1, ""
	}
	ln<i32> = lenu.(i32)
	body = string.newstringfromlen(data, ln)
	return 0, body
}

export func embed_list(inner, dir) {
	fs<EmbedFS> = inner.(EmbedFS)
	return embed_mem_list(fs, dir)
}

EmbedFSObj::read(name) {
	err, body = embed_read(this.inner, name)
	return err, body
}

EmbedFSObj::list(dir) {
	err, names = embed_list(this.inner, dir)
	return err, names
}
