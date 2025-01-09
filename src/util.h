#define UART_BASE_ADDR 0xF0000000
#define UART_RDY_ADDR 0x0
#define UART_RDATA_ADDR 0x1
#define UART_WRITE_ADDR 0x2
#define UART_WDATA_ADDR 0x3
#define UART_WRDY_ADDR 0x4
#define UART_BASE 0xF0000000
#define UART_RDY *((unsigned char *)(UART_BASE_ADDR + UART_RDY_ADDR))
#define UART_RDATA *((unsigned char *)(UART_BASE_ADDR + UART_RDATA_ADDR))
#define UART_WRITE *((unsigned char *)(UART_BASE_ADDR + UART_WRITE_ADDR))
#define UART_WDATA *((unsigned char *)(UART_BASE_ADDR + UART_WDATA_ADDR))
#define UART_WRDY *((unsigned char *)(UART_BASE_ADDR + UART_WRDY_ADDR))

inline unsigned int read_csr(unsigned int csr_num) {
    unsigned long result;
    asm("csrr %0, %1" : "=r"(result) : "i"(csr_num));
    return result;
}
