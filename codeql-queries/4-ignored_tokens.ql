import csharp

class TokenAcceptingMethod extends Method {
	TokenAcceptingMethod() {
      this.getAParameter().getType().hasQualifiedName("System.Threading.CancellationToken") 
      and this.hasStatementBody()
    }
}

predicate isTestOrDebugMethod(Method m) {
    m.getFile().getAbsolutePath().toLowerCase().matches("%test%") or
    m.getFile().getAbsolutePath().toString().matches("%Manual.cs")
}

predicate checksToken(Expr e) {
     e.(PropertyAccess).getProperty().hasQualifiedName("System.Threading.IsCancellationRequested") or
     e.(MethodCall).getTarget().hasQualifiedName("System.Threading.CancellationToken.ThrowIfCancellationRequested")
}

predicate passesToken(Call c) {
	c.getAnArgument().getType().hasQualifiedName("System.Threading.CancellationToken")
}

predicate containsLoopWithoutTokenCheck(Method m) {
  exists(LoopStmt s | not s.getAChildStmt().(ForeachStmt).isAsync() and 
                        s.getEnclosingCallable*() = m and 
                        not exists(Expr e | s = e.getEnclosingStmt().getParent*() and
                            (checksToken(e) or passesToken(e))))
}

from TokenAcceptingMethod tm
where not isTestOrDebugMethod(tm)
and containsLoopWithoutTokenCheck(tm)
select tm

