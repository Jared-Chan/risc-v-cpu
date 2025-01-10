.section .text._start
.global _start
_start:
    la sp,_stack
    call main
    ebreak
