// dummy functions
void uart_init() {}
void uart_send(unsigned int c) {}
char uart_getc() { return 'a'; }
void uart_puts(char *s) {}

void main() {
  uart_init();

  uart_puts("Hello World!\n");

  while (1) {
    uart_send(uart_getc());
  }
}