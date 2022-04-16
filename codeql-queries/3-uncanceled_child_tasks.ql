import java

predicate isSourceNode(ConstructorCall cc) {
  cc
    .getConstructedType()
    .getASupertype*()
    .hasQualifiedName("java.util", "Timer")
}

predicate isSinkNode(Call c) {
  c.
  (MethodAccess)
  .getMethod()
  .hasQualifiedName("java.util", "Timer", "cancel")
}

predicate isTest(Element e) {
  e.getFile().getAbsolutePath().matches("%/test/%")
}

from ConstructorCall cc
where isSourceNode(cc) and 
    not isTest(cc) and
    not exists (Call c, Field f | isSinkNode(c) and
      c.getEnclosingCallable().getDeclaringType() = cc.getEnclosingCallable().getDeclaringType() and
      cc.getEnclosingStmt().(ExprStmt).getExpr().getAChildExpr().(FieldAccess).getField() = f and
      c.getEnclosingStmt().(ExprStmt).getExpr().getAChildExpr().(FieldAccess).getField() = f) and
    not exists (Call c, Variable v | isSinkNode(c) and
      c.getEnclosingCallable() = cc.getEnclosingCallable() and
      (cc.getEnclosingStmt().(ExprStmt).getExpr().(VariableAssign).getDestVar() = v 
        or cc.getEnclosingStmt().(LocalVariableDeclStmt).getAVariable().getVariable().(Variable) = v) and
      c.getEnclosingStmt().(ExprStmt).getExpr().getAChildExpr().(VarAccess).getVariable() = v)
select cc



