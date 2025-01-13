#ifndef __UTIL_H
#define __UTIL_H

#include <stdint.h>

#define UART_BASE_ADDR 0xF0000000
#define UART_RDY_ADDR 0x0
#define UART_RDATA_ADDR 0x4
#define UART_WRITE_ADDR 0x8
#define UART_WDATA_ADDR 0xC
#define UART_WRDY_ADDR 0x10
#define UART_BASE 0xF0000000
#define UART_RDY *((volatile unsigned char *)(UART_BASE_ADDR + UART_RDY_ADDR))
#define UART_RDATA                                                             \
    *((volatile unsigned char *)(UART_BASE_ADDR + UART_RDATA_ADDR))
#define UART_WRITE                                                             \
    *((volatile unsigned char *)(UART_BASE_ADDR + UART_WRITE_ADDR))
#define UART_WDATA                                                             \
    *((volatile unsigned char *)(UART_BASE_ADDR + UART_WDATA_ADDR))
#define UART_WRDY *((volatile unsigned char *)(UART_BASE_ADDR + UART_WRDY_ADDR))

#define CSR_CYCLE_L 0xC00
#define CSR_CYCLE_H 0xC80
#define CSR_TIME_L 0xC01
#define CSR_TIME_H 0xC81
#define CSR_INSTRET_L 0xC02
#define CSR_INSTRET_H 0xC82

#define ASCII_ZERO 48
#define ASCII_LOWER_A 97

unsigned int read_csr(const unsigned int csr_num);

void uart_send_char(char c);
char uart_get_char();

void putint(unsigned int i, int base, bool has_sign);
void putlong(int64_t i, int base, bool has_sign);
void putstr(char* str);

#endif
