mem Token {
	u64 value
}

const Token::new(value<u64>) Token {
	return new Token { value: value }
}

const Token::as_u64() u64 {
	return this.value
}
