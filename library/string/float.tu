ExponentMax<i32>  =  1023
MantisSize<i32>   = 52
BigintSize<i32>   = 300
DecimalStart<i32> = 150

mem FloatBytes {
	u32		val[BigintSize]
	u16 	start , end 
	u16 	pos ,decn
	String* formatstr
}

FloatBytes::multiply(exp<i16>)
{
	i<u16> = 0
	while exp {
		exp -= 1
		i = this.start
		while (i <= this.end) {
			this.val[i] *= 2
			if (this.val[i] >= 1000000000)
			{
				this.val[i] -= 1000000000
				this.val[i - 1] += 1
				if (i == this.start){
					this.start -= 1
				}
			}
			if (i == this.end && this.val[i] == 0)
				this.end -= 1
			i += 1
		}
	}
}

FloatBytes::divided(exp<i16>)
{
	i<u16> = 0
	while exp {
		exp += 1

		i = this.end
		while i >= this.start {
			if this.val[i] & 1 {
				this.val[i + 1] += 500000000
				if i == this.end
					this.end += 1
			}
			this.val[i] /= 2
			if i == this.start && this.val[i] == 0
				this.start += 1
			i -= 1
		}
	}
}

FloatBytes::merge(right<FloatBytes>)
{
	start<u16> = 0
	end<u16> = 0
	i<u16> = 0

	if this.start < right.start  start = this.start
	else start = right.start

	if this.end > right.end end = this.end 
	else end =  right.end

	i = end
	while (i >= start) {
		this.val[i] += right.val[i]
		if (this.val[i] >= 1000000000)
		{
			this.val[i] -= 1000000000
			this.val[i - 1] += 1
		}
		i -= 1
		if (i < start && this.val[i] != 0)
			start -= 1
	}
	this.end = end
	this.start = start
}

FloatBytes::zero(){
	this.start = BigintSize - 1
	this.end = 0
	this.pos = 0
	this.decn = 0
}

FloatBytes::unit(exp<i16>)
{
	this.val[DecimalStart - 1] = 1
	this.start = DecimalStart - 1
	this.end = DecimalStart - 1
	this.pos = 0
	this.decn = 0
	if (exp < 0)
		this.divided(exp)
	else if (exp > 0)
		this.multiply(exp)
}

FloatBytes::format(neg<i32>,dcount<i32>)
{
	i<u16> = 0
	this.formatstr = emptyS()
	this.format_init(neg)
	i = this.start
	while i <= this.end {
		if dcount != 0 && this.decn != 0 && this.pos > this.decn + dcount 
			break
		if (i == DecimalStart)
			this.format_dot()
		this.format_num(i)
		i += 1
	}
	if this.decn + dcount > this.pos{
		add<i32> = (this.decn + dcount) - this.pos
		if this.decn == 0 {
			this.formatstr.putc('.'.(i8))
			this.formatstr.putc('0'.(i8))
		}
		for j<i32> = 0 ; j < add ; j += 1
			this.formatstr.putc('0'.(i8))
		return this.formatstr
	}
	if dcount == 0
		return this.formatstr.sub(0.(i8),this.decn - 1)
	if this.decn == 0 {
		this.formatstr.putc('.'.(i8))
		for j<i32> = 0 ; j < dcount ; j += 1 
			this.formatstr.putc('0'.(i8))
		return this.formatstr
	}
	return this.formatstr.sub(0.(i8),this.decn + dcount)
}
FloatBytes::inf_nan(neg<i32> , mantissa<u64>)
{
	if (mantissa >> 63 != 0)
		mantissa = 0
	if (neg && mantissa == 0)
		this.formatstr = S("-Inf".(i8))
	else if (mantissa == 0)
		this.formatstr = S("Inf".(i8))
	else
		this.formatstr = S("NaN".(i8))
	return this.formatstr
}

FloatBytes::format_itoa(n<i32> , add<i32>)
{
	len<u16> = 0
	buf<i32> = 0
	positif<u32> = 0
	numstr_<i8:10> = null
	numstr<i8*> = &numstr_
	len = (n < 0) + 1
	buf = n
	loop {
		buf /= 10
		if buf <= 0  break
		len += 1
	}
	numstr[len] = 0
	if (n < 0)
	{
		numstr[0] = '-'
		buf = 1
	}
	positif = n * (1 - 2 * (n < 0))
	while (len > buf)
	{
		len -= 1
		numstr[len] = '0' + positif % 10
		positif /= 10
	}
	if(add){
		this.formatstr.catstr(numstr)
		this.pos += std.strlen(numstr)
	}
	return S(numstr)
}

FloatBytes::format_init(neg<i32>)
{
	i<u16> = 0

	if (neg) {
		this.formatstr.catstr("-".(i8))
		this.pos = 1
	}
	if (this.start >= DecimalStart)
	{
		i = this.start
		this.formatstr.catstr("0".(i8))
		this.pos += 1
		if (this.start > DecimalStart)
		{
			this.formatstr.catstr(".".(i8))
			this.pos += 1
			this.decn = this.pos
		}
		while (i > DecimalStart)
		{
			i -= 1
			this.formatstr.catstr("000000000".(i8))
			this.pos += 9
		}
	}
}

FloatBytes::format_dot()
{
	if (this.pos > this.start || (this.start != this.end))
	{
		this.formatstr.catstr(".".(i8))
		this.pos += 1
		this.decn = this.pos
	}
}

FloatBytes::format_num(i<u16>){
	k<u32> = 0
	j<u16> = 0

	if (i == this.start && i < DecimalStart)
	{
		this.format_itoa(this.val[i],1.(i8))
	}
	else if (i == this.end && i >= DecimalStart)
	{
		k = 100000000
		while (this.val[i] / k == 0)
		{
			this.formatstr.catstr("0".(i8))
			this.pos += 1
			k /= 10
		}
		k = 1
		while (this.val[i] % (k * 10) == 0)
			k *= 10
		this.format_itoa(this.val[i]/k,1.(i8))
	}
	else
	{
		numstr<String> = this.format_itoa(this.val[i], 0.(i8))
		k = numstr.len()
		j = k
		while (j < 9){
			j += 1
			this.formatstr.catstr("0".(i8))
			this.pos += 1
		}
		this.formatstr.cat(numstr)
		this.pos += k
	}
}

FloatBytes::zero_double(neg<i32>,dcount<i32>)
{
	s<String> = null
	if (neg) s = S("-0".(i8))
	else 	 s = S("0".(i8))

	if dcount {
		s.putc('.'.(i8))
		for i<i32> = 0 ; i < dcount ; i +=1 
			s.putc('0'.(i8))
	}
	return s
}

fn f64tostring(x<f64>,dcount<i32>)
{
	x2<u64*> = &x
	mantissa<u64> = *x2
	is_negative<i32> = 0
	exp<i16> = 0
	unit<FloatBytes>   = new FloatBytes
	result<FloatBytes> = new FloatBytes
	i<i16> = 0
	exp = ((mantissa << 1) >> 53) - ExponentMax
	is_negative = (mantissa >> 63)
	mantissa = ((mantissa << 12) >> 12)
	if (x == 0) return result.zero_double(is_negative,dcount)

	if (exp >= ExponentMax + 1)
		return result.inf_nan(is_negative, mantissa)
	unit.unit(exp - MantisSize)

	result.zero()
	while (i < MantisSize)
	{
		if (mantissa >> i) & 1
			result.merge(unit)
		unit.multiply(1.(i8))
		i += 1
	}
	result.merge(unit)
	return result.format(is_negative,dcount)
}

fn f32tostring(x<f32>,dcount<i32>)
{
	x64<f64> = x
	return f64tostring(x64,dcount)
}

fn strtof32(str<i8*>)
{
    ret<f64> = strtof64(str)
    ret32<f32> = ret
    return ret32
}

fn strtof64(str<i8*>)
{
    ret<f64> = 0.0
	signedRet<i8> = '\0'
    signedExp<i8> = '\0'
    decimals<i32> = 0
    isExp<i32> = 0
    foundExp<i32> = 0
    found<i32> = 0
    exp<f64> = 0
    for c<i8> = 0; '\0' != *str ; str += 1 {
		c = *str
		
        if (c >= '0') && (c <= '9')
        {
            digit<f64> = c - '0'
            if (isExp)
            {
                exp = (10 * exp) + digit
                foundExp = 1
            }
            else if (decimals == 0)
            {
                ret = (10 * ret) + digit
                found = 1
            }
            else
            {
                ret += digit / decimals
                decimals *= 10
            }
            continue
        }
        if (c == '.')
        {
            if !found break
            if isExp break
            if decimals != 0 break
            decimals = 10
            continue
        }
        if ((c == '-') || (c == '+'))
        {
            if (isExp) {
                if (signedExp || (exp != 0)) break
                else signedExp = c
            }else{
                if (signedRet || (ret != 0)) break
                else signedRet = c
            }
            continue
        }
        if (c == 'E')
        {
            if !found break
            if isExp break
            else	      isExp = 1
            continue
        }
        break
    }
    if (isExp && !foundExp)
    {
        while (*str != 'E')
            str -= 1
    }
    if !found && signedRet
        str -= 1

    for c2<i8> = 0; exp != 0; exp -= 1
    {
        if (signedExp == '-')
            ret /= 10
        else
            ret *= 10
    }
    if (signedRet == '-')
    {
        if (ret != 0)
            ret = 0 - ret
    }
    return ret
}