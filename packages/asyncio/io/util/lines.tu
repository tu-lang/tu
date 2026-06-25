// Top-level constructor wrapping the Lines iterator defined in
// async_buf_read_ext.tu. Use as `lines(reader)` to iterate records
// terminated by '\n'.

// Build a Lines iterator over buffered reader `r`.
const lines(r<u64>) Lines {
    return Lines::new(r)
}
