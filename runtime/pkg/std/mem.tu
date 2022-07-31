use runtime

OP_T_THERS<i8> = 16

OPSIZE<i8> = 8

func byte_copy(dst<u8*>,src<u8*>,bytes<u64>){
	
    while  bytes > 0 {								      
		x<u8> = *src
		# mov pointer
		src   += 1
		bytes -= 1
		*dst = x
		# mov pointer
		dst += 1
	}
}
func memcpy(dst<u8*>,src<u8*>,bytes<u64>){
	byte_copy(dst,src,bytes)
}
func strcopy(dst<i8*>,src<i8*>){
	ret<i8*> = dst	
    while  *src != 0 {								      
		*dst = *src
		dst += 1
		src += 1
	}
	*dst = 0
	return ret
}

func strcmp(p1<i8*>, p2<i8*>) {
	s1<i8*> = p1
	s2<i8*> = p2
	c1<i8>  = 0
	c2<i8>  = 0

	while c1 == c2 {
     	c1 =  *s1
		s1 += 1

		c2 = *s2
		s2 += 1
      if c1 == 0	return c1 - c2
    }

  	return c1 - c2
}
func strcat(dest<i8*> , src<i8*>){
	strcopy(dest + strlen(dest) , src)
	return dest
}
func memcmp(vl<u64> , vr<u64>, n<u64>)
{
	l<u8*> = vl
	r<u8*> = vr
	while n  && *l == *r {
		n -= 1
		l += 1
		r += 1
	}
	if n > 0  {
		return *l - *r	
	}
	return runtime.Zero
}
func memset(s<u64> , c<i32> , n<u64>)
{
	uc<u8> = c
	su<i8*> = s

	while n > 0 {
		*su = uc
		su += 1
		n -= 1
	}
	return s
}
