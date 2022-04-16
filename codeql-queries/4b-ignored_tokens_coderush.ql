import csharp

class TokenAcceptingMethod extends Method {
	TokenAcceptingMethod() {
      this.getAParameter().getType().hasQualifiedName("System.Threading.CancellationToken") 
      and this.hasStatementBody()
    }
}

predicate isTestElement(Element e) {
  e.getFile().getAbsolutePath().toLowerCase().matches("%test%")
}

predicate isCancellationCheckExpr(Expr e) {
  e.(PropertyAccess).getProperty().hasQualifiedName("System.Threading.CancellationToken.IsCancellationRequested") or
     e.(MethodCall).getTarget().hasQualifiedName("System.Threading.CancellationToken.ThrowIfCancellationRequested")
}

predicate checksToken(Method m) {
  exists(Expr e | (m = e.getEnclosingCallable() or m = e.getEnclosingCallable().getEnclosingCallable*()) and
    isCancellationCheckExpr(e))
}

predicate passesToken(Method m) {
  exists(Call c | (m = c.getEnclosingCallable() or m = c.getEnclosingCallable*()) and callWithToken(c))
}

predicate callWithToken(Call c) {
	c.getAnArgument().getType().hasQualifiedName("System.Threading.CancellationToken")
}

from TokenAcceptingMethod tm
where not isTestElement(tm) and 
    not checksToken(tm) and 
    not passesToken(tm)
select tm

