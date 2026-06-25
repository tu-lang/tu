// Top-level constructor wrapping the Split iterator defined in
// async_buf_read_ext.tu. Use as `aiou.split(reader, delim)` to
// iterate records terminated by `delim`.

// Build a Split iterator over buffered reader `r` with delimiter `delim`.
const split(r<u64>, delim<u8>) Split {
    return Split::new(r, delim)
}
