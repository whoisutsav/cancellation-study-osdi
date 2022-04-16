import java
import semmle.code.java.dataflow.DataFlow

class RunMethod extends Method {
  RunMethod() {
    this.getDeclaringType().getASupertype*().hasQualifiedName("java.lang", "Runnable") and
    this.hasName("run") and
    this.hasNoParameters() and
    not this.getDeclaringType() instanceof TestClass
  }
}

class InterruptMethod extends Method {
  InterruptMethod() {
    this.getDeclaringType().getASupertype*().hasQualifiedName("java.lang", "Thread") and
    this.hasName("interrupt") and
    this.hasNoParameters()
  }
}

class IECatchClause extends CatchClause {
  IECatchClause() {
    this.getACaughtType().getASupertype*().hasQualifiedName("java.lang", "InterruptedException") and
    this.getCompilationUnit().fromSource()
  }
}

class Configuration extends DataFlow::Configuration {
  Configuration() { this = "Constructor Call to Interrupt Method Access Configuration" }

  override predicate isSource(DataFlow::Node source) {
    source
        .asExpr()
        .(ConstructorCall)
        .getConstructedType()
        .getASupertype*()
        .hasQualifiedName("java.lang", "Runnable")
  }

  override predicate isSink(DataFlow::Node sink) {
    exists(Call call | call.getEnclosingStmt() = sink.asExpr().getEnclosingStmt() |
      call.(MethodAccess).getMethod() instanceof InterruptMethod
    )
  }
}

predicate methodCalls(Callable ca, Stmt st) { ca.getACallee*() = st.getEnclosingCallable() }

/*
 *  False positive type 1
 *    rm:     a run() method
 *    return: evaluates to true if rm is a type-1 false positive,
 *    and evaluates to false other wise
 *
 *
 *    type-1 false positive run() (version 08/04/2021):
 *      1. run() catches an InterruptedException inside
 *      2. there's a loop at a very breath layer (only one layer for now)
 *      3. the loop checks a boolean variable like shouldStop or
 *          a boolean variable accessor like shouldStop()
 *      4. the InterruptedException catch block is inside the loop
 *      5. inside the catch block, either exists an Thread.interrupt() is triggered or
 *          exists a Break/Return statement or
 *          exists a throw statement
 *
 *     We want to make this definition as strict as possible, and leave some
 *     cases that do not fit this definition for human inspection.
 */

predicate isFalsePositiveType1(RunMethod rm) {
  exists(IECatchClause cc, LoopStmt lp |
    /* 1 */ methodCalls(rm, cc) and
    /* 2 */ rm = lp.getEnclosingCallable() and
    /* 3 */ exists(VarAccess va | va.getVariable().getType() instanceof BooleanType |
      va = lp.getCondition().getAChildExpr*() or
      va.getEnclosingCallable() = lp.getCondition().getAChildExpr*().(MethodAccess).getMethod()
    ) and
    /* 4 */ lp.getBody().getAChild+() = cc.getEnclosingStmt() and
    /* 5 */ (
      exists(InterruptMethod im, MethodAccess ma |
        ma.getMethod() = im and
        ma.getEnclosingStmt().getEnclosingStmt() = cc.getBlock()
      )
      or
      exists(Stmt exit | cc.getBlock().getAChild*() = exit |
        exit.(BreakStmt).(JumpStmt).getTarget() = lp
        or
        // exit.(ContinueStmt).(JumpStmt).getTarget() = lp or
        exit.(ReturnStmt).getEnclosingStmt*() = lp.getBody()
      )
      or
      exists(cc.getBlock().getAStmt().(ThrowStmt))
    )
  )
}

predicate hasExceptionHandling(IECatchClause cc) {
  exists(cc.getBlock().getAStmt().(BreakStmt))
  or
  exists(cc.getBlock().getAStmt().(ReturnStmt))
  or
  exists(cc.getBlock().getAStmt().(ThrowStmt))
  or
  exists(InterruptMethod im, MethodAccess ma |
    ma.getMethod() = im and ma.getEnclosingStmt().getEnclosingStmt() = cc.getBlock()
  )
}

predicate isInsideLoop(IECatchClause cc) {
  exists(LoopStmt s | cc.getEnclosingStmt*() = s)
}

/*
 *  Query: locates the run() methods that have unhandled InterruptedException
 *  1. locate the constructor call (src) and the cooresponding interrupt() call (sink)
 *  2. locate the run() method of the src's class, which could be
 *      2.1 new <constructor name>(...)
 *      2.2 new Thread() { @Override public void run() {...}};
 *      2.3 new Thread(new Runnable() { @Override public void run() {...}});
 *      2.4 new Daemon(new <constructor name>(...));
 *      2.5 new Thread(() -> {...}
 *  3. locate an IECatchClause inside run() method
 *  4. check whether this code region is NOT a type-1 false positive (see comments of isFalsePositiveType1)
 *  5. check whether this code region does NOT have exception handing statements (see hasExceptionHandling)
 */

from Configuration config, DataFlow::Node src, DataFlow::Node sink, RunMethod rm, IECatchClause cc
where
  /* 1 */ config.hasFlow(src, sink) and
  exists(Expr ex | ex = src.asExpr().getAChildExpr*() |
    /* 2.1-2.4 */ rm = ex.getType().(ClassOrInterface).getAMethod() or
    /* 2.5     */ rm = ex.(FunctionalExpr).asMethod()
  ) and
  /* 3 */ methodCalls(rm, cc) and
  /* 4 */ not isFalsePositiveType1(rm) and
  /* 5 */ not hasExceptionHandling(cc) and
          isInsideLoop(cc)
select rm // to locate run() methods
// select rm, cc // to locate one or more catch clauses inside a run()




