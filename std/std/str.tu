use runtime
use string

func tolower(c<u8>){
	if c >= 65 && c <= 90 return c + 32
	return c
}
func toupper(c<u8>){
	if c >= 97 && c <= 122 return c - 32
	return c
}
func strlen(str<i8*>){
	cnt<u64> = 0
	if str == null return runtime.Zero

	while *str != 0 {
		cnt += 1
		str += 1
	}	
	return cnt
}



func swap_i8(l<i8*>,r<i8*>){
    tmp<i8> = *l
    *l = *r
    *r = tmp
}
func reverse(str<i8*>, length<i32>)
{
    start<i32> = 0
    end<i32>   = length - 1
    while start < end {
        swap_i8(str+start,str + end)
        start += 1
        end -= 1
    }
}

func itoa(num<i32>, str<i8*>, base<i32>)
{
    i<i32> = 0
	isNegative<i32> = 0
    strp<i8*> = null
	
    //Handle 0 explicitely, otherwise empty string is printed for 0 
    if num == 0 {
        str[0] = '0'
        str[1] = '\0'
        return str
    }
  
    // In standard itoa(), negative numbers are handled only with 
    // base 10. Otherwise numbers are considered unsigned.
    if num < 0 && base == 10 {
        isNegative = 1
        num = 0 - num
    }
  
    // Process individual digits
    while num != 0 {
        rem<i32>  = num % base
        strp = str + i
        i += 1
        if rem > 9 
            *strp = rem - 10 + 97 # 'a'
        else
            *strp = rem + 48 #'0'
        num = num / base
    }
  
    // If number is negative, append '-'
    if isNegative != 0 {
		str[i] = '-'
        i += 1
    }
	str[i] = '\0' // Append string terminator
  
    // Reverse the string
    reverse(str, i)
  
    return str
}
//@param nptr string
//@param endptr NULL
//@param base 10
//@return long
func strtol(nptr<i8*>, endptr<u64*>, base<i32>)
{
    s<i8*> = nptr
    acc<i64> = 0
    cutoff<i64> = 0
    c<i32> = 0
    neg<i32> = 0
    any<i32> = 0
    cutlim<i32> = 0

    while runtime.True {
		c = *s
		s += 1
		if string.isspace(c) == runtime.False 
			break
	} 
	if c == '-' {
		neg = 1
		c = *s
		s += 1
	} else {
		neg = 0
		if c == '+'{
			c = *s
			s += 1
		}
	}
	if ((base == 0 || base == 16) &&
	    c == '0' && (*s == 'x' || *s == 'X')) {
		c = s[1]
		s += 2
		base = 16
	}
	if base == 0 {
		// TODO: base = c == '0' ? 8 : 10;
		if c == '0' base = 8
		else 		base = 10
	}
	// cutoff = neg ? LONG_MIN : LONG_MAX;
	if neg != null {
		cutoff = runtime.I64_MIN
	}else{
		cutoff = runtime.I64_MAX
	}
	cutlim = cutoff % base
	cutoff /= base
	if neg != null {
		if (cutlim > 0) {
			cutlim -= base
			cutoff += 1
		}
		cutlim = 0 - cutlim
	}
	acc = 0
	any = 0
	_base<i32> = 10
	while runtime.True {
	// for (acc = 0, any = 0;; c = (unsigned char) *s++) {
		if string.isdigit(c) == runtime.True {
			c -= '0'
		}else if (string.isalpha(c) == runtime.True) {
			if string.isupper(c) == runtime.True {
				c -= 'A' - _base
			}else{
				c -= 'a' - _base
			}
			// c -= isupper(c) ? 'A' - 10 : 'a' - 10;
		}else	break

		if (c >= base)
			break
		if (any < 0)
			continue
		if (neg) {
			if (acc < cutoff || (acc == cutoff && c > cutlim)) {
				any = -1
				acc = runtime.I64_MIN
				// errno = ERANGE
			} else {
				any = 1
				acc *= base
				acc -= c
			}
		} else {
			if (acc > cutoff || (acc == cutoff && c > cutlim)) {
				any = -1
				acc = runtime.I64_MAX
				// errno = ERANGE;
			} else {
				any = 1
				acc *= base
				acc += c
			}
		}
		//TODO: c = *s++
		c = *s
		s += 1
	}
	if (endptr != 0){
		*endptr = nptr
		if any != 0 {
			*endptr = s - 1
		}
		// *endptr = (char *) (any ? s - 1 : nptr);
	}
	return acc
}
prime64<u64>    = 1099511628211

func hash64(bytes<u8*>,len<u64>){
	hash<u64> = 14695981039346656037
	for i<i64> = 0 ; i < len ; i += 1 {
		hash ^= bytes[i]
		hash *= prime64
	}
	return hash
}