// True when expr contains .await, including MemberCallExpr wrapping inner FunCallExpr.
func expressionHasAwait(e){
    if e == null return false
    if e.hasawait return true
    if type(e) == type(MemberCallExpr) {
        mc = e
        return mc.call != null && mc.call.hasawait
    }
    return false
}

MemberCallExpr::checkawait(){
    if this.call != null && this.call.hasawait {
        this.hasawait = true
    }
}

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

ChainExpr::checkawait() {
    for it : this.fields {
        if expressionHasAwait(it) {
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
	if expressionHasAwait(this.rhs) {
		this.hasawait = true
	}	
}
