use fmt
use os
use runtime

lines<Lines> = null
elf<Elf>	 = null
parse_done<i8> 	 = null

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

func debug_init(){
	if parse_done != null
		return True
	elf = new Elf {
		filepath : runtime.ori_execout
	}
	elf.init()

	seclines<Elf64_Shdr> = elf.Section(".debug_line".(i8))
	if seclines == null {
		debug("couldn't find .debug_line")
		parse_done = True
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
	parse_done = True
}
func findpc(pc<u64>){
	if parse_done == null debug_init()

	row<PcData> = lines.funcline(pc)
	if row == null return "??:0"

	return fmt.sprintf(
		"%s:%d",string.new(row.filename),int(row.line)
	)
}