#include "util.h"

unsigned int read_csr(const unsigned int csr_num) {
    unsigned int result;
    switch (csr_num) {
    case CSR_CYCLE_H:
        asm("csrr %0, %1" : "=r"(result) : "i"(CSR_CYCLE_H));
        break;
    case CSR_CYCLE_L:
        asm("csrr %0, %1" : "=r"(result) : "i"(CSR_CYCLE_L));
        break;
    case CSR_TIME_H:
        asm("csrr %0, %1" : "=r"(result) : "i"(CSR_TIME_H));
        break;
    case CSR_TIME_L:
        asm("csrr %0, %1" : "=r"(result) : "i"(CSR_TIME_L));
        break;
    case CSR_INSTRET_H:
        asm("csrr %0, %1" : "=r"(result) : "i"(CSR_INSTRET_H));
        break;
    case CSR_INSTRET_L:
        asm("csrr %0, %1" : "=r"(result) : "i"(CSR_INSTRET_L));
        break;
    default:;
    }
    return result;
}

void uart_send_char(char c) {
    while (!(UART_WRDY & 0x01)) {
    }
    UART_WDATA = c;
    while (!(UART_WRDY & 0x01)) {
    }
}

char uart_get_char() {
    char c;
    while (!(UART_RDY & 0x01)) {
    }
    c = UART_RDATA;
    return c;
}

void putint(unsigned int i, int base, bool has_sign) {
    unsigned int j = i;
    unsigned int r;

    char str[33];
    str[32] = '\0';
    int str_idx = 31;

    if (has_sign && (((int)i) < 0)) {
        uart_send_char('-');
        j = -i;
    }

    if (j == 0) {
        uart_send_char('0');
        return;
    }

    while (j > 0) {
        r = j % base;
        if (r < 10)
            str[str_idx] = r + ASCII_ZERO;
        else
            str[str_idx] = r - 10 + ASCII_LOWER_A;
        j /= base;
        str_idx--;
    }
    putstr(str + str_idx + 1);
}

void putlong(int64_t i, int base, bool has_sign) {
    unsigned int l = i & 0xFFFFFFFF;
    unsigned int u = i >> 32;
    if (u != 0)
        putint(u, base, has_sign);
    if (l != 0)
        putint(l, base, false);
    if (l == 0 && u == 0)
        uart_send_char('0');
    if (l == 0 && u != 0) {
        char zeros[] = "00000000000000000000000000000000";
        putstr(zeros);
    }
}

void putstr(char *str) {
    int i = 0;
    while (str[i] != '\0') {
        uart_send_char(str[i++]);
    }
}
