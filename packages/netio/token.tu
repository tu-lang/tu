// Mother: Token(pub usize) — opaque u64 token for Poll registration.

mem Token {
	u64 raw
}

const Token::new(v<u64>) Token {
	return new Token { raw: v }
}

// Package-level bridge for cross-subpackage callers.
fn token_from_u64(v<u64>) Token {
	return Token::new(v)
}

// Instance method (not const): needs `this` for field load.
Token::as_u64() u64 {
	return this.raw
}
