class Function {

}
# auto increment closure id
closureidx

# auto increment count
compileridx

func incr_closureidx(){
    idx = closureidx
    closureidx += 1
    return idx
}
func incr_compileridx(){
    idx = compileridx
    compileridx += 1
    return idx
}