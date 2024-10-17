


#ifndef KERNEL_UART_C
#define KERNEL_UART_C

void write_string(struct uart* p, char* str) {
    char s;
    do {
        s = *(str++);
        *(char*)(p->uart_base + tx) = s;
    } while(s);
}

void wait_writable(struct uart* p) {
    int val;
    do {
        val = *(int *) (p->uart_base + usr);
    } while (!(val & 1));
}

/*
 * 0 = DW_apb_uart is idle or inactive
 * 1 = DW_apb_uart is busy (actively transferring data)
 */
int check_busy(struct uart* p) {
    int val = *(int*)(p->uart_base + usr);
    return val & 1;
}


 
