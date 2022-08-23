mem Block {
	i8* data
	u32 offset
	u32 size
}
func newBlock(d<i8*>,off<u32>,si<u32>){
	r<Block> = new Block
	r.data   = d
	r.offset = off
	r.size   = si
	return r
}
