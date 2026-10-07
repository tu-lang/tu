// export fn is illegal; export marks dynamic facades only.
export fn bad(a<i32>) i32 {
    return a
}
