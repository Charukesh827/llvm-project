; NOTE: Assertions have been autogenerated by utils/update_analyze_test_checks.py UTC_ARGS: --version 3
; RUN: opt -passes='print<access-info>' -disable-output %s 2>&1 | FileCheck %s

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"

; Test cases for https://github.com/llvm/llvm-project/issues/69744.
; Note that both loops in the tests are needed to incorrectly determine that
; the loops are safe with runtime checks via FoundNonConstantDistanceDependence
; handling code in LAA.

define void @test_indirect_read_write_loop_also_modifies_pointer_array(ptr noundef %arr) {
; CHECK-LABEL: 'test_indirect_read_write_loop_also_modifies_pointer_array'
; CHECK-NEXT:    loop.1:
; CHECK-NEXT:      Report: could not determine number of loop iterations
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Grouped accesses:
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
; CHECK-NEXT:    loop.2:
; CHECK-NEXT:      Report: unsafe dependent memory operations in loop. Use #pragma clang loop distribute(enable) to allow loop distribution to attempt to isolate the offending operations into a separate loop
; CHECK-NEXT:  Unsafe indirect dependence.
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:        IndirectUnsafe:
; CHECK-NEXT:            %l.2 = load i64, ptr %l.1, align 8, !tbaa !4 ->
; CHECK-NEXT:            store i64 %inc, ptr %l.1, align 8, !tbaa !4
; CHECK-EMPTY:
; CHECK-NEXT:        Unknown:
; CHECK-NEXT:            %l.1 = load ptr, ptr %gep.iv.1, align 8, !tbaa !0 ->
; CHECK-NEXT:            store ptr %l.1, ptr %gep.iv.2, align 8, !tbaa !0
; CHECK-EMPTY:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Grouped accesses:
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
;
entry:
  br label %loop.1

loop.1:
  %iv = phi i64 [ %iv.next, %loop.1 ], [ 8, %entry ]
  %arr.addr.0.i = phi ptr [ %incdec.ptr.i, %loop.1 ], [ %arr, %entry ]
  %incdec.ptr.i = getelementptr inbounds ptr, ptr %arr.addr.0.i, i64 1
  %0 = load ptr, ptr %arr.addr.0.i, align 8, !tbaa !6
  %tobool.not.i = icmp eq ptr %0, null
  %iv.next = add i64 %iv, 8
  br i1 %tobool.not.i, label %loop.1.exit, label %loop.1

loop.1.exit:
  %iv.lcssa = phi i64 [ %iv, %loop.1 ]
  br label %loop.2

loop.2:
  %iv.1 = phi i64 [ 0, %loop.1.exit ], [ %iv.1.next, %loop.2 ]
  %iv.2 = phi i64 [ %iv.lcssa, %loop.1.exit ], [ %iv.2.next, %loop.2 ]
  %gep.iv.1 = getelementptr inbounds ptr, ptr %arr, i64 %iv.1
  %l.1 = load ptr, ptr %gep.iv.1, align 8, !tbaa !6
  %l.2 = load i64, ptr %l.1, align 8, !tbaa !13
  %inc = add i64 %l.2, 1
  store i64 %inc, ptr %l.1, align 8, !tbaa !13
  %iv.2.next = add nsw i64 %iv.2, 1
  %gep.iv.2 = getelementptr inbounds ptr, ptr %arr, i64 %iv.2
  store ptr %l.1, ptr %gep.iv.2, align 8, !tbaa !6
  %iv.1.next = add nuw nsw i64 %iv.1, 1
  %cmp = icmp ult i64 %iv.1.next, 1000
  br i1 %cmp, label %loop.2, label %exit

exit:
  ret void
}

define void @test_indirect_read_loop_also_modifies_pointer_array(ptr noundef %arr) {
; CHECK-LABEL: 'test_indirect_read_loop_also_modifies_pointer_array'
; CHECK-NEXT:    loop.1:
; CHECK-NEXT:      Report: could not determine number of loop iterations
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Grouped accesses:
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
; CHECK-NEXT:    loop.2:
; CHECK-NEXT:      Memory dependences are safe with run-time checks
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Check 0:
; CHECK-NEXT:        Comparing group GRP0:
; CHECK-NEXT:          %gep.iv.2 = getelementptr inbounds i64, ptr %arr, i64 %iv.2
; CHECK-NEXT:        Against group GRP1:
; CHECK-NEXT:          %gep.iv.1 = getelementptr inbounds ptr, ptr %arr, i64 %iv.1
; CHECK-NEXT:      Grouped accesses:
; CHECK-NEXT:        Group GRP0:
; CHECK-NEXT:          (Low: {(64 + %arr),+,64}<%loop.1> High: {(8064 + %arr),+,64}<%loop.1>)
; CHECK-NEXT:            Member: {{\{\{}}(64 + %arr),+,64}<%loop.1>,+,8}<%loop.2>
; CHECK-NEXT:        Group GRP1:
; CHECK-NEXT:          (Low: %arr High: (8000 + %arr))
; CHECK-NEXT:            Member: {%arr,+,8}<nuw><%loop.2>
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
;
entry:
  br label %loop.1

loop.1:
  %iv = phi i64 [ %iv.next, %loop.1 ], [ 8, %entry ]
  %arr.addr.0.i = phi ptr [ %incdec.ptr.i, %loop.1 ], [ %arr, %entry ]
  %incdec.ptr.i = getelementptr inbounds ptr, ptr %arr.addr.0.i, i64 1
  %0 = load ptr, ptr %arr.addr.0.i, align 8, !tbaa !6
  %tobool.not.i = icmp eq ptr %0, null
  %iv.next = add i64 %iv, 8
  br i1 %tobool.not.i, label %loop.1.exit, label %loop.1

loop.1.exit:
  %iv.lcssa = phi i64 [ %iv, %loop.1 ]
  br label %loop.2

loop.2:
  %iv.1 = phi i64 [ 0, %loop.1.exit ], [ %iv.1.next, %loop.2 ]
  %iv.2 = phi i64 [ %iv.lcssa, %loop.1.exit ], [ %iv.2.next, %loop.2 ]
  %gep.iv.1 = getelementptr inbounds ptr, ptr %arr, i64 %iv.1
  %l.1 = load ptr, ptr %gep.iv.1, align 8, !tbaa !6
  %l.2 = load i64, ptr %l.1, align 8, !tbaa !13
  %inc = add i64 %l.2, 1
  %iv.2.next = add nsw i64 %iv.2, 1
  %gep.iv.2 = getelementptr inbounds i64, ptr %arr, i64 %iv.2
  store i64 %l.2, ptr %gep.iv.2, align 8, !tbaa !6
  %iv.1.next = add nuw nsw i64 %iv.1, 1
  %cmp = icmp ult i64 %iv.1.next, 1000
  br i1 %cmp, label %loop.2, label %exit

exit:
  ret void
}

define void @test_indirect_write_loop_also_modifies_pointer_array(ptr noundef %arr) {
; CHECK-LABEL: 'test_indirect_write_loop_also_modifies_pointer_array'
; CHECK-NEXT:    loop.1:
; CHECK-NEXT:      Report: could not determine number of loop iterations
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Grouped accesses:
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
; CHECK-NEXT:    loop.2:
; CHECK-NEXT:      Memory dependences are safe with run-time checks
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Check 0:
; CHECK-NEXT:        Comparing group GRP0:
; CHECK-NEXT:          %gep.iv.2 = getelementptr inbounds ptr, ptr %arr, i64 %iv.2
; CHECK-NEXT:        Against group GRP1:
; CHECK-NEXT:          %gep.iv.1 = getelementptr inbounds ptr, ptr %arr, i64 %iv.1
; CHECK-NEXT:      Grouped accesses:
; CHECK-NEXT:        Group GRP0:
; CHECK-NEXT:          (Low: {(64 + %arr),+,64}<%loop.1> High: {(8064 + %arr),+,64}<%loop.1>)
; CHECK-NEXT:            Member: {{\{\{}}(64 + %arr),+,64}<%loop.1>,+,8}<%loop.2>
; CHECK-NEXT:        Group GRP1:
; CHECK-NEXT:          (Low: %arr High: (8000 + %arr))
; CHECK-NEXT:            Member: {%arr,+,8}<nuw><%loop.2>
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
;
entry:
  br label %loop.1

loop.1:
  %iv = phi i64 [ %iv.next, %loop.1 ], [ 8, %entry ]
  %arr.addr.0.i = phi ptr [ %incdec.ptr.i, %loop.1 ], [ %arr, %entry ]
  %incdec.ptr.i = getelementptr inbounds ptr, ptr %arr.addr.0.i, i64 1
  %0 = load ptr, ptr %arr.addr.0.i, align 8, !tbaa !6
  %tobool.not.i = icmp eq ptr %0, null
  %iv.next = add i64 %iv, 8
  br i1 %tobool.not.i, label %loop.1.exit, label %loop.1

loop.1.exit:
  %iv.lcssa = phi i64 [ %iv, %loop.1 ]
  br label %loop.2

loop.2:
  %iv.1 = phi i64 [ 0, %loop.1.exit ], [ %iv.1.next, %loop.2 ]
  %iv.2 = phi i64 [ %iv.lcssa, %loop.1.exit ], [ %iv.2.next, %loop.2 ]
  %gep.iv.1 = getelementptr inbounds ptr, ptr %arr, i64 %iv.1
  %l.1 = load ptr, ptr %gep.iv.1, align 8, !tbaa !6
  %inc = add i64 %iv.1, 1
  store i64 %inc, ptr %l.1, align 8, !tbaa !13
  %iv.2.next = add nsw i64 %iv.2, 1
  %gep.iv.2 = getelementptr inbounds ptr, ptr %arr, i64 %iv.2
  store ptr %l.1, ptr %gep.iv.2, align 8, !tbaa !6
  %iv.1.next = add nuw nsw i64 %iv.1, 1
  %cmp = icmp ult i64 %iv.1.next, 1000
  br i1 %cmp, label %loop.2, label %exit

exit:
  ret void
}

; FIXME: Not safe with runtime checks due to the indirect pointers are modified
;        in the loop.
define void @test_indirect_read_write_loop_does_not_modify_pointer_array(ptr noundef %arr, ptr noundef noalias %arr2) {
; CHECK-LABEL: 'test_indirect_read_write_loop_does_not_modify_pointer_array'
; CHECK-NEXT:    loop.1:
; CHECK-NEXT:      Report: could not determine number of loop iterations
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Grouped accesses:
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
; CHECK-NEXT:    loop.2:
; CHECK-NEXT:      Report: unsafe dependent memory operations in loop. Use #pragma clang loop distribute(enable) to allow loop distribution to attempt to isolate the offending operations into a separate loop
; CHECK-NEXT:  Unsafe indirect dependence.
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:        IndirectUnsafe:
; CHECK-NEXT:            %l.2 = load i64, ptr %l.1, align 8, !tbaa !4 ->
; CHECK-NEXT:            store i64 %inc, ptr %l.1, align 8, !tbaa !4
; CHECK-EMPTY:
; CHECK-NEXT:        Unknown:
; CHECK-NEXT:            %l.3 = load i64, ptr %gep.arr2.iv.1, align 8 ->
; CHECK-NEXT:            store i64 %inc.2, ptr %gep.arr2.iv.2, align 8, !tbaa !0
; CHECK-EMPTY:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Grouped accesses:
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
;
entry:
  br label %loop.1

loop.1:
  %iv = phi i64 [ %iv.next, %loop.1 ], [ 8, %entry ]
  %arr.addr.0.i = phi ptr [ %incdec.ptr.i, %loop.1 ], [ %arr, %entry ]
  %incdec.ptr.i = getelementptr inbounds ptr, ptr %arr.addr.0.i, i64 1
  %0 = load ptr, ptr %arr.addr.0.i, align 8, !tbaa !6
  %tobool.not.i = icmp eq ptr %0, null
  %iv.next = add i64 %iv, 8
  br i1 %tobool.not.i, label %loop.1.exit, label %loop.1

loop.1.exit:
  %iv.lcssa = phi i64 [ %iv, %loop.1 ]
  br label %loop.2

loop.2:
  %iv.1 = phi i64 [ 0, %loop.1.exit ], [ %iv.1.next, %loop.2 ]
  %iv.2 = phi i64 [ %iv.lcssa, %loop.1.exit ], [ %iv.2.next, %loop.2 ]
  %gep.iv.1 = getelementptr inbounds ptr, ptr %arr, i64 %iv.1
  %l.1 = load ptr, ptr %gep.iv.1, align 8, !tbaa !6
  %l.2 = load i64, ptr %l.1, align 8, !tbaa !13
  %inc = add i64 %l.2, 1
  store i64 %inc, ptr %l.1, align 8, !tbaa !13
  %iv.2.next = add nsw i64 %iv.2, 1
  %gep.arr2.iv.1 = getelementptr inbounds i64 , ptr %arr2, i64 %iv.1
  %gep.arr2.iv.2 = getelementptr inbounds i64 , ptr %arr2, i64 %iv.2
  %l.3 = load i64, ptr %gep.arr2.iv.1
  %inc.2 = add i64 %l.3, 5
  store i64 %inc.2, ptr %gep.arr2.iv.2, align 8, !tbaa !6
  %iv.1.next = add nuw nsw i64 %iv.1, 1
  %cmp = icmp ult i64 %iv.1.next, 1000
  br i1 %cmp, label %loop.2, label %exit

exit:
  ret void
}

!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!13 = !{!14, !15, i64 0}
!14 = !{!"", !15, i64 0}
!15 = !{!"long long", !8, i64 0}
