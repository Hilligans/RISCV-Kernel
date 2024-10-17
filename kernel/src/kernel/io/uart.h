

#ifndef KERNEL_UART_H
#define KERNEL_UART_H

#endif //KERNEL_UART_H

#define UART0 = 0x10000000
#define UART1 = 0x10010000
#define UART2 = 0x10020000


#define tx 0x0
#define rx 0x0

#define usr 0x7c

struct uart {
    void* uart_base;
};
