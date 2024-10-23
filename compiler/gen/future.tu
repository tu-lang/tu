IfStmt::checkawait(){
    for it : this.cases {
        if it.cond.hasawait {
            this.hasawait = true
            break
        }
        if it.block.hasawait {
            this.hasawait = true
            break
        }
    }
    if this.elseCase != null {
        if this.elseCase.block.hasawait {
            this.hasawait = true
        }
    }
}

ChainExpr::checkawait(){
    if this.first != null && this.first.hasawait {
        this.hasawait = true
        return true
    }
    if this.last != null && this.last.hasawait {
        this.hasawait = true
        return true
    }
    for it : this.fields {
        if it.hasawait {
            this.hasawait = true
            return true
        }
    }
}

BinaryExpr::checkawait(){
	if this.lhs.hasawait {
		this.hasawait = true
	}
	if this.rhs != null && this.rhs.hasawait {
		this.hasawait = true
	}
}

AssignExpr::checkawait(){
	if this.lhs.hasawait {
		this.hasawait = true
	}
	if this.rhs != null && this.rhs.hasawait {
		this.hasawait = true
	}	
}