#include "util.h"
#include <stdint.h>

void send_cycles() {
    unsigned int lower = read_csr(CSR_CYCLE_L);
    unsigned int upper = read_csr(CSR_CYCLE_H);
    int64_t cycles = (int64_t)upper << 32 | lower;
    putstr("Cycles: ");
    putlong(cycles, 10, false);
    putstr("\n");
}

void send_instret() {
    unsigned int lower = read_csr(CSR_INSTRET_L);
    unsigned int upper = read_csr(CSR_INSTRET_H);
    int64_t instret = (int64_t)upper << 32 | lower;
    putstr("Instructions retired: ");
    putlong(instret, 10, false);
    putstr("\n");
}

int main(void) {
    char c;
    putstr("Starting\n");
    while (true) {
        c = uart_get_char();
        switch (c) {
        case '\n':
            break;
        case 'c':
            send_cycles();
            break;
        case 'i':
            send_instret();
            break;
        default:
            uart_send_char(' ');
            uart_send_char(c);
            uart_send_char(' ');
            uart_send_char('\n');
        }
    }
    return 0;
}
