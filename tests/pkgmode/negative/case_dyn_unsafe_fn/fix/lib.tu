// `unsafe fn` is still a static definition: rejected in a dyn package (use unsafe func).
unsafe fn bad(a<i32>) i32 {
    return a
}
