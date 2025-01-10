#include "util.h"

void uart_send_char(char c);

int main(void) {
    uart_send_char('H');
    uart_send_char('e');
    uart_send_char('l');
    uart_send_char('l');
    uart_send_char('o');
    uart_send_char(' ');
    uart_send_char('w');
    uart_send_char('o');
    uart_send_char('r');
    uart_send_char('l');
    uart_send_char('d');
    uart_send_char('!');
    return 0;
}
