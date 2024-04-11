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