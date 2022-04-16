import java

class IECatchClause extends CatchClause {
  IECatchClause() {
    this.getACaughtType().getASupertype*().hasQualifiedName("java.lang", "InterruptedException") and
    this.getCompilationUnit().fromSource()
  }
}

predicate isJavaMethod(Method m) {
 m.getDeclaringType().getPackage().getName().matches("java%")
}

predicate clearsFlag(Stmt s) {
    forall(MethodAccess ma | ma.getEnclosingStmt().getEnclosingStmt*() = s | 
      not ma.getMethod().getAThrownExceptionType().hasQualifiedName("java.lang", "InterruptedException") or
      isJavaMethod(ma.getMethod()) or
      (not ma.getMethod().isAbstract() and clearsFlag(ma.getMethod().getBody())) or
      (ma.getMethod().isAbstract() and clearsFlag(ma.getMethod().getAPossibleImplementation().getBody()))
  ) and
  not exists(MethodAccess ma2 | ma2.getEnclosingStmt().getEnclosingStmt*() = s and
      ma2.getMethod().hasQualifiedName("java.lang", "Thread", "interrupt"))
}

from IECatchClause cc, MethodAccess ma
where 
  clearsFlag(cc.getTry().getBlock()) and
  ma.getMethod().hasQualifiedName("java.lang", "Thread", "interrupted") and 
  ma.getEnclosingStmt().getEnclosingStmt*() = cc
select ma


