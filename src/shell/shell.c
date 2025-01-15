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

void send_time() {
    unsigned int lower = read_csr(CSR_TIME_L);
    unsigned int upper = read_csr(CSR_TIME_H);
    int64_t time_val = (int64_t)upper << 32 | lower;
    putstr("Time (us): ");
    putlong(time_val, 10, false);
    putstr("\n");
}

/* Dump memory to UART 16 bytes at a time from the starting address
 * Input '\n' to move on to the next 16 bytes.
 * Input anything else to return.
 * Requires memory location to be in hexadecimal and lowercase
 * Requires eight digits
 */
void dump_memory() {
    unsigned int mem_ptr_u = 0;
    char c;
    int cur_digit = 7;
    c = uart_get_char(); // space
    while (true) {
        c = uart_get_char();
        if ((c >= ASCII_ZERO && c <= ASCII_ZERO + 9)) {
            mem_ptr_u += ((c - ASCII_ZERO) << (cur_digit * 4));
        } else if (c >= ASCII_LOWER_A && c <= ASCII_LOWER_A + 5) {
            mem_ptr_u += ((c - ASCII_LOWER_A + 10) << (cur_digit * 4));
        } else {
            putstr("Invalid memory address.\n");
            return;
        }
        --cur_digit;
        if (cur_digit < 0) {
            break;
        }
    }
    c = uart_get_char(); // enter
    putstr("Memory address: 0x");
    putint(mem_ptr_u, 16, false);
    uart_send_char('\n');

    char *mem_ptr = (char *)mem_ptr_u;

    putstr("Enter <enter> to continue. Anything else to return.\n");
    while (true) {
        putstr("0x");
        putint((unsigned int)(mem_ptr + 16), 16, false);
        putstr(" - ");
        putstr("0x");
        putint((unsigned int)(mem_ptr), 16, false);
        putstr(": ");
        for (int i = 15; i >= 0; i--) {
            if (*(mem_ptr + i) < 16)
                uart_send_char('0');
            putint((unsigned int)*(mem_ptr + i), 16, false);
            uart_send_char(' ');
        }
        putstr(" | ");
        for (int i = 15; i >= 0; i--) {
            uart_send_char(*(mem_ptr + i));
        }
        mem_ptr += 16;
        c = uart_get_char();
        if (c == '\n') {
            continue;
        } else {
            break;
        }
    }
}

void mirror() {
    char c;
    while (true) {
        c = uart_get_char();
        uart_send_char(c);
    }
}

int main(void) {
    char c;
    putstr("Starting shell\n");
    while (true) {
        c = uart_get_char();
        switch (c) {
        case '\n':
            break;
        case 'h':
            putstr("Menu\n");
            putstr("c: display cycle count\n");
            putstr("t: display time\n");
            putstr("i: display retired instruction count\n");
            putstr("d xxxxxxxx: dump memory starting at xxxxxxxx, where "
                   "xxxxxxxx is a hexadecimal address in lowercase.\n");
            break;
        case 'c':
            send_cycles();
            break;
        case 'i':
            send_instret();
            break;
        case 't':
            send_time();
            break;
        case 'd':
            dump_memory();
            break;
        case 'm':
            mirror();
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
