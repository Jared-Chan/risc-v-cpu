.section .text._boot
.global _boot
_boot:
    la sp,_stack
    j _start
