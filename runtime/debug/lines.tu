use fmt
use os
use std
use string

Lines::read(out<u8*>, count<i32>){return this.reader.read(out,count)}
Lines::read_u8(out<u8*>) { return this.read(out, U8) }
Lines::read_i8(out<i8*>) { return this.read(out, I8) }
Lines::read_u16(out<u16*>) { return this.read(out, U16) }
Lines::read_u32(out<u32*>) { return this.read(out, U32) }
Lines::read_u64(out<u64*>) { return this.read(out, U64) }


Lines::append(r<Row>) {
	if r.address != null {
		file<i32> = r.file
		if file > 0
			file += this.file_offset - 1
		//push one
		this.rows.push(new Row{
			address: r.address,
			file : file,
			line : r.line
		})
	}
}
Lines::qsort(l<i32> , r<i32>){
	if(l < r){
		i<i32> = l
		j<i32> = r
		x<Row> = this.rows.addr[l]
		t<Row> = null
		while( i < j ){
			t = this.rows.addr[j]
			// while(i < j && this.rows[j] >= x)
			while(i < j && t.address >= x.address){
				j -= 1
			}
			if(i < j){
				this.rows.addr[i] = this.rows.addr[j]
				i += 1
			}
			t = this.rows.addr[i]
			// while(i < j && this.rows[i] < x)
			while(i < j && t.address < x.address){
				i += 1
			}
			if (i < j){
				this.rows.addr[j] = this.rows.addr[i]
				j -= 1
			}
		}
		this.rows.addr[i] = x
		this.qsort(l , i - 1)
		this.qsort(i + 1 , r)
	}
}


Lines::parse(){
	while this.reader.finish() == False {
		this.load()
  	}
	this.qsort(0.(i8) , this.rows.len() - 1)
}


Lines::load(){
	lh<LineHeader> = new LineHeader
	end<i32> = this.reader.offset + 4
	this.read(lh,sizeof(LineHeader))
	end += lh.total

	for (i<i32> = 1 ; i < lh.opcode_base ; i += 1) {
		this.read_u8(Null)
	}
	dir<string.String> = string.string()
	loop {
		path<string.String> = string.string()
		path = this.reader.read_str(path)
		if path.empty() == True
			break
		dir = path
	}

	this.file_offset = this.files.len()
	loop {
		file<string.String> = string.string()
		file = this.reader.read_str(file)
		if file.empty() == True
			break
		
		fullpath<string.String> = dir.dup()
		fullpath.putc('/'.(i8))
		fullpath.cat(file)
		this.files.push(fullpath)
		dir_index<u64> = 0
		mtime<u64> = 0
		file_length<u64> = 0
		check(this.reader.read_uleb128(&dir_index))
		check(this.reader.read_uleb128(&mtime))
		check(this.reader.read_uleb128(&file_length))
	}
	r<Row> = new Row {
		address: 0,
		file : 1,
		line : 1
	}

	while this.reader.offset < end {
		op<u8> = 0
		if this.read_u8(&op) == Null
			break
		// fmt.print(int(op),"\t")
		match op {
			0x0: { 
				check(this.reader.read_uleb128(Null))
				check(this.read_u8(&op))
				addr<u64> = 0
				match op {
					0x01:{
						this.append(r)
						//default
						r.address = 0
						r.file = 1
						r.line = 1
					}
					0x02:{
						check(this.read_u64(&addr))
						r.address = addr
					}
					0x04:	check(this.reader.read_uleb128(&addr))
					0x03| 0x80 | 0xff : {}
					_ :	{
						error("unhandled extended op " + int(op))
					}
				}
			}
			0x1: this.append(r)
			0x2: { 
				delta<u64> = 0
				check(this.reader.read_uleb128(&delta))
				delta *= lh.m_length
				r.address += delta
			}
			0x3: {
				delta<i64> = 0
				check(this.reader.read_sleb128(&delta))
				r.line += delta
				// fmt.println("0x3: line:",int(r.line)," delta:",int(delta))
			}
			0x4: {
				//FIXME: same varname 
				filen<u64> = 0
				check(this.reader.read_uleb128(&filen))
				filename<i8*> = "??"
				if filen > 0 {
					filename = this.files.addr[
						this.file_offset + filen - 1
					]
				}
				r.file = filen
			}
			0x5 | 0x7 | 0x9 : error("unimpl")
			0x6: debug("negate stmt")
			0x8: {
				adjusted_opcode<i32> = 255 - lh.opcode_base
				address_increment<i32> =
					(adjusted_opcode / lh.range) * lh.m_length
				r.address += address_increment
			} 
			_: {
				adjusted_opcode<i32> = op - lh.opcode_base
				//FIXME: address_increment<i32> = (adjusted_opcode / lh.range) *lh.m_length 。=> * lh.m_length
				address_increment<i32> =
					(adjusted_opcode / lh.range) * lh.m_length
				line_increment<i32> = lh.base + (adjusted_opcode % lh.range)
				r.address += address_increment
				r.line += line_increment
				this.append(r)
			}
		}
	}

	return this.reader.offset
}

Lines::debug() {
	for(i<i32>  = 0 ;i < this.rows.len() ; i += 1){
		r<Row> = this.rows.addr[i]
		file<string.String> = this.files.addr[r.file]
		fmt.println(
			fmt.sprintf("%d %s:%d"
				int(r.address),string.new(file.str()),int(r.line)
			)
		)
	}
}


Lines::funcline(address<u64>){
	for(i<i32> = 0 ; i < this.rows.len()  ; i += 1){
		r<Row> = this.rows.addr[i]
		if r.address > address  {
			if i - 1 < 0 {
				return 0.(i8)
			}
			r  = this.rows.addr[i - 1]
			filename<string.String> = this.files.addr[r.file]
			return new PcData {
				address: address,
				line: r.line,
				//TODO: 
				//filename: this.files.addr[r.file]
				filename: filename.str(),
			}

		}
	}
	return 0.(i8)
}
