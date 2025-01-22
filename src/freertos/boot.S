.extern main
.extern freertos_risc_v_trap_handler

.section .text._boot
.global _boot
_boot:
    la sp,_stack

    /*
        Install trap hanlder.
        freertos_risc_v_trap_handler[1:0] is 2'b0, 
        meaning 'direct mode'
    */
    la a0,freertos_risc_v_trap_handler
    csrw mtvec,a0

    /*
        Enable machine interrupts
    */
    //csrsi mstatus,8
    j main
