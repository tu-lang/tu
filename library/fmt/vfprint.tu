use runtime
use std
use fmt

func fputs(s<i8*>,out<u64>)
{
	ll<u64>		= std.strlen(s)
	c<i8> = 1
	if std.fwrite(s,c,ll,out) != ll	{
		return std.EOF
	}else{
		return ll
	}
}

func fputc(c<i8>,out<u64*>){
	l<u64> = 1
	if l != std.fwrite(&c,l,l,out) {
		return std.EOF
	}
	return c
}
//vfprintf
func vfprintf(out<u64>, format<i8*>, args_<u64*>)
{
	translating<u64> = 0
	ret<u64>		 = 0
	args<u64*> = &args_
	i<i32>  = 0
	for (p<i8*> = format ; *p != 0 ; p += 1)
	{
		match *p {
			'%' : {
				if translating == 0 {
					translating	= 1
				}else{
					if fputc('%'.(i8),out) < runtime.Zero {
						return std.EOF
					}
					ret += 1
					translating = 0
				}
			}
			'd' :{
				if translating == 1	{ //%d
					buf_o<i8:10> = null
					buf<i8*>	 = &buf_o
					translating	= 0
					std.itoa(args[i],buf,10.(i8))
					if fputs(buf,out) < runtime.Zero   {
						return std.EOF
					}
					ret += std.strlen(buf)
					i += 1
				}else if fputc('d'.(i8),out) < runtime.Zero {
					return std.EOF
				} else{
					ret += 1
				}
			}
			's' : {
				if translating > 0 {
					str1<i8*>	= args[i]
					i += 1
					translating	= 0
					if fputs(str1,out) < runtime.Zero {
						return std.EOF
					}
					ret += std.strlen(str1)
				}else if fputc('s'.(i8),out) < runtime.Zero {
					return std.EOF
				}else{
					ret += 1
				}
			}
			'c' : {
				if translating > 0 {
					c1<i8*>	= args[i]
					i += 1
					translating	= 0
					if fputc(c1,out) < runtime.Zero {
						return std.EOF
					}
				}else if fputc('c'.(i8),out) < runtime.Zero {
					return std.EOF
				}
				ret += 1
			}
			'p' :{
				if translating == 1	{ //%p
					if fputs("0x".(i8),out) < runtime.Zero   {
						return std.EOF
					}
					buf_o<i8:21> = null
					buf<i8*>	 = &buf_o
					translating	= 0
					std.itoa(args[i],buf,16.(i8))
					ret += 2
					if fputs(buf,out) < runtime.Zero   {
						return std.EOF
					}
					ret += std.strlen(buf)
					i += 1
				}else if fputc('p'.(i8),out) < runtime.Zero {
					return std.EOF
				} else{
					ret += 1
				}
			}
			_ :{
				if translating > 0 {
					translating	= 0
				}
				if fputc(*p,out) < runtime.Zero	{
					return std.EOF
				}else{
					ret += 1
				}
			}
		}
	}
	return ret
}