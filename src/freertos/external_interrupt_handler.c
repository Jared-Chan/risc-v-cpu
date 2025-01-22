#include "external_interrupt_handler.h"
#include "util.h"

void external_interrupt_handler( uint32_t cause ) {
    putstr("Handling external interrupt 0x");
    putint(cause, 16, false);
    uart_send_char('\n');
}
