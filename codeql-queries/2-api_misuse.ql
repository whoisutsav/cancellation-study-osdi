import java

class IECatchClause extends CatchClause {
  IECatchClause() {
    this.getACaughtType().getASupertype*().hasQualifiedName("java.lang", "InterruptedException") and
    this.getCompilationUnit().fromSource()
  }
}

// catch (InterruptedException) calls Thread.interrupted()
from IECatchClause cc, MethodAccess ma
where ma.getMethod().getDeclaringType().getASupertype*().hasQualifiedName("java.lang", "Thread") and
ma.getMethod().hasName("interrupted") and 
ma.getMethod().hasNoParameters() and
(ma.getEnclosingStmt() = cc or ma.getEnclosingStmt().getEnclosingStmt*() = cc)
select ma


