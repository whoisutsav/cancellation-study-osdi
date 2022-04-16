import csharp

class TokenAcceptingMethod extends Method {
	TokenAcceptingMethod() {
      this.getAParameter().getType().getQualifiedName().matches("%System.Threading.CancellationToken%") 
      and this.hasStatementBody()
    }
}

predicate isTestElement(Element e) {
  e.getLocation().getFile().getAbsolutePath().toLowerCase().matches("%test%")
}

predicate callWithToken(Call c) {
	c.getAnArgument().getType().hasQualifiedName("System.Threading.CancellationToken")
}

predicate canSupportToken(Call c) {
  exists(TokenAcceptingMethod tm | tm = c.getARuntimeTarget())

}

predicate failsToPassTokenWhenSupported(Method m) {
  exists(Call c | m = c.getEnclosingCallable+() and not callWithToken(c) and canSupportToken(c))
}

from TokenAcceptingMethod tm
where not isTestElement(tm) and failsToPassTokenWhenSupported(tm)
select tm


