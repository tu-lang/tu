use fmt
use os
use runtime

lines<Lines> = null
elf<Elf>	 = null
//NOTICE: set by compiler
enabled<i8>  = 0

func error(str){
	os.die(str)
}
func debug(str){
	fmt.println(str)
}
func check(ret<i32>){
	if ret == 0 {
		error("check  failed")
	}
}
// enable by compiler through  -g parameter
// like: tu run hello.tu -g
func debug_init(){
	//FIXME: "return" cause lost of initcall missing
	// if enabled != 1.(i8) return 1.(i8)
	if enabled == 1 {
	elf = new Elf {
		filepath : runtime.ori_execout
	}
	elf.init()

	seclines<Elf64_Shdr> = elf.Section(".debug_line".(i8))
	if seclines == null {
		debug("couldn't find .debug_line")
		return 0.(i8)
	}
	lines = new Lines {
		reader: Reader {
			buffer: elf.buffer + seclines.sh_offset,
			len: seclines.sh_size,
			offset: 0
		},
		files: std.array_create(),
		rows: std.array_create()
	}
	lines.parse()
	}
}
func findpc(pc<u64>){
	// must enable debug first
	// like: tu run hello.tu -g
	if enabled == 0.(i8) return int(pc) + ":??"

	row<PcData> = lines.funcline(pc)
	if row == null return int(pc) + ":??"

	return fmt.sprintf(
		"%s:%d",string.new(row.filename),int(row.line)
	)
}