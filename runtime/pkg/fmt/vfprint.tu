use runtime
use std
use fmt

flag_percent<i8> = 37 # '%'
flag_d<i8> = 100 # 'd'
flag_D<i8> = 68  #  'D'
flag_s<i8> = 115 # 's'
flag_S<i8> = 83  # 'S'
flag_i<i8> = 105 # 'i'
flag_I<i8> = 73  # 'I'
flag_u<i8> = 117 # 'u'
flag_U<i8> = 85  # 'U'

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
func vfprintf(out<u64>, format<i8*>, args,args1,args2,args3)
{
	translating<u64> = 0
	ret<u64>		 = 0
	curr<u64>        = 0
	pp<u64*> = &args
	stack<i32> = 4
	for (p<i8*> = format ; *p != 0 ; p += 1)
	{
		//init stack
		curr = *pp
		if *p == flag_d || *p == flag_s {
			if stack < 1  pp += 8	else pp -= 8
			if stack == 1 {	pp = &args	pp += 40	}		
			stack -= 1
		}
		//stack end
		match *p {
			flag_percent : {
				if translating == 0 {
					translating	= 1
				} 
				else{
					if fputc(flag_percent,out) < runtime.Zero {
						return std.EOF
					}
					ret += 1
					translating = 0
				}
			}
			flag_d :{
				if translating == 1	{ //%d
					buf_o<i8:10> = null
					buf<i8*>	 = &buf_o
					translating	= 0
					ilen<i32> = 10
					std.itoa(curr,buf,ilen)
					if fputs(buf,out) < runtime.Zero   {
						return std.EOF
					}
					ret += std.strlen(buf)
				}else if fputc(flag_d,out) < runtime.Zero {
					return std.EOF
				} else{
					ret += 1
				}
			}
			flag_s : {
				if translating > 0 {
					str1<i8*>	= curr
					translating	= 0
					if fputs(str1,out) < runtime.Zero {
						return std.EOF
					}
					ret += std.strlen(str1)
				}else if fputc(flag_s,out) < runtime.Zero {
					return std.EOF
				}else{
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