func vsnprintf(dstr<i8*>, format<i8*>, args...)
{
	translating<u64>	= 0
	ret<u64>	= 0
	i<i32> = 0
	strp<i8*> = null

	pp<u64*> = &args
	stack<i32> = 4
	for (p<i8*> = format ; *p != 0 ; p += 1) {
		//init stack
		curr = *pp
		if stack < 1  pp += 8	else pp -= 8
		if stack == 1 {	pp = &args	pp += 40	}		
		stack -= 1
		//stack end

		match *p {
			flag_percent : {
				if !translating {
					translating	= 1
				}else
				{
					//dstr[i++] = '%'
					strp = dstr + i
					i += 1
					*strp = flag_percent
					ret += 1
					translating = 0
				}
			}
			flag_d :{
				if translating	{ //%d
					buf_o<i8:16> = 0
					buf<i8*> = &buf_o
					translating	= 0
					bl<i32> = 10
					std.itoa(curr,buf,bl)
					l<i32> = std.strlen(buf)
					std.strcat(dstr,buf)
					i += l
					ret += l
				}else
				{
				    //dstr[i++] = 'd'
					strp = dstr + i
					i += 1
					*strp = flag_d
					ret += 1
				}
			}
			flag_s : {
				if translating {
					str<i8*> = curr
					translating	= 0
					ll<i32> = std.strlen(str)
					std.strcat(dstr,str)
					i += ll

					ret += ll
				}else
				{
					//dstr[i++] = 's'
					strp = dstr + i
					i += 1
					*strp = flag_s
					ret += 1
				}
			}
			_ : {
				if translating {
					translating	= 0
				}else {
					//dstr[i++] = *p
					strp = dstr + i
					i += 1
					*strp = *p
					ret += 1
				}
			}
		}
	}
	return ret
}
//func printf(arg...)
//{
//	return vfprintf(arg)
//}