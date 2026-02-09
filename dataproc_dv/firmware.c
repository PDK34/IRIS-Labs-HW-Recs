#include <stdint.h>
#include <stdbool.h>

#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)

/*---------Define your data processing registers addresses here -----------------*/
#define DATAPROC_CONTROL   (*(volatile uint32_t*)0x02001000)
#define DATAPROC_STATUS    (*(volatile uint32_t*)0x02001004)
#define DATAPROC_PIXCOUNT  (*(volatile uint32_t*)0x02001008)
#define DATAPROC_OUTPUT    (*(volatile uint32_t*)0x0200100C)

/*---------------------------------------------------------------------------------*/

void uart_putc(char c);
void print(const char *p);
//utility fn
void print_hex(uint8_t val) {
    const char hex[] = "0123456789ABCDEF";
    uart_putc(hex[val >> 4]);
    uart_putc(hex[val & 0xF]);
}

void print_hex32(uint32_t val) {
    print_hex((val >> 24) & 0xFF);
    print_hex((val >> 16) & 0xFF);
    print_hex((val >> 8) & 0xFF);
    print_hex(val & 0xFF);
}


void main()
{
	reg_uart_clkdiv = 104;

    //Register Read/Write
    print("Register Access\n");
    
    //Write to control register
    DATAPROC_CONTROL = 0x01;  // start=1, mode=00
    
    //Read it back
    uint32_t ctrl = DATAPROC_CONTROL;
    print("  CONTROL written: 0x01\n");
    print("  CONTROL read:    0x");
    print_hex32(ctrl);
    if (ctrl == 0x01)
        print("  [PASS]\n");
    else
        print("  [FAIL]\n");
    print("\n");
    
    //Read status Register
    print("Status Register\n");
    
    uint32_t status = DATAPROC_STATUS;
    print("  STATUS: 0x");
    print_hex32(status);
    print("\n");
    print("    Busy bit:  ");
    print((status & 0x01) ? "1\n" : "0\n");
    print("    Valid bit: ");
    print((status & 0x02) ? "1\n" : "0\n");
    print("\n");
    
    //process first 16 Pixels in Bypass Mode
    print("Bypass Mode (16 pixels)\n");
    
    DATAPROC_CONTROL = 0x01;  // mode=00 (bypass), start=1
    
    print("  Outputs: ");
    for (int i = 0; i < 16; i++) {
        // Wait for valid output
        int timeout = 10000;
        while (!(DATAPROC_STATUS & 0x02) && timeout-- > 0);
        
        if (timeout > 0) {
            uint8_t pixel = DATAPROC_OUTPUT & 0xFF;
            print_hex(pixel);
            print(" ");
        } else {
            print("TO ");  // Timeout
        }
    }
    print("\n");
    
    // Check pixel count
    uint32_t count = DATAPROC_PIXCOUNT;
    print("  Pixel count: ");
    print_hex32(count);
    print("\n\n");
    
    //Invert Mode (16 pixels)
    print("Test 4: Invert Mode (16 pixels)\n");
    
    // Stop first
    DATAPROC_CONTROL = 0x00;
    
    // Small delay
    for (volatile int i = 0; i < 1000; i++);
    
    // Start in invert mode
    DATAPROC_CONTROL = 0x03;  // mode=01 (invert), start=1
    
    print("  Outputs: ");
    for (int i = 0; i < 16; i++) {
        int timeout = 10000;
        while (!(DATAPROC_STATUS & 0x02) && timeout-- > 0);
        
        if (timeout > 0) {
            uint8_t pixel = DATAPROC_OUTPUT & 0xFF;
            print_hex(pixel);
            print(" ");
        } else {
            print("TO ");
        }
    }
    print("\n");
    
    count = DATAPROC_PIXCOUNT;
    print("  Pixel count: ");
    print_hex32(count);
    print("\n\n");
    
    
    print("All tests completed\n");
    
    DATAPROC_CONTROL = 0x00;
    
    while (1);
}

void uart_putc(char c)
{
	if (c == '\n')
		uart_putc('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		uart_putc(*(p++));
}

