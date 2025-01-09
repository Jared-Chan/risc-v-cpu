#define UART_BASE 0xF0000000
#define UART_RDY 0x0
#define UART_RDATA 0x1
#define UART_WRITE 0x2
#define UART_WDATA 0x3
#define UART_WRDY 0x4

volatile unsigned char *uart_ready = (unsigned char *)(UART_BASE + UART_RDY);
volatile unsigned char *uart_rdata = (unsigned char *)(UART_BASE + UART_RDATA);
volatile unsigned char *uart_write = (unsigned char *)(UART_BASE + UART_WRITE);
volatile unsigned char *uart_wdata = (unsigned char *)(UART_BASE + UART_WDATA);
volatile unsigned char *uart_wready = (unsigned char *)(UART_BASE + UART_WRDY);

int main(void) {
    /*char urdy = *uart_ready & 0xF;*/
    /*char rdata = *uart_rdata & 0xF;*/
    unsigned char u_wrdy;
    do {
        u_wrdy = *uart_wready & 0x1;
    } while (!u_wrdy);
    *uart_wdata = 'A';
    *uart_write = 1;
    do {
        u_wrdy = *uart_wready & 0x1;
    } while (!u_wrdy);
    /*__asm__(*/
    /*        "ebreak;"*/
    /*       );*/
    return 0;
}
