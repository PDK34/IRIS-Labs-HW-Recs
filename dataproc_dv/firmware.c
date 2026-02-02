#include <stdint.h>
#include <stdbool.h>

#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)

/*---------Define your data processing registers addresses here -----------------*/



/*---------------------------------------------------------------------------------*/

void putchar(char c);
void print(const char *p);

void main()
{
	reg_uart_clkdiv = 104;

	/*Write the code to read & write to your data proc module
	 * and print the output pixels using print() function*/




	/*------------------------------------------------------*/


}

void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}
