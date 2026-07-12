mem Token {
	u64 value
}

const Token::new(value<u64>) Token {
	return new Token { value: value }
}

// Package-level bridge for cross-subpackage callers.
fn token_from_u64(v<u64>) Token {
	return Token::new(v)
}

const Token::as_u64() u64 {
	return this.value
}
