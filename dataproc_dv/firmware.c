#include <stdint.h>

#define FLASH_IMAGE_ADDR 0x00100000


#define REG_UART_CLKDIV (*(volatile uint32_t*)0x02000004)
#define REG_UART_DATA   (*(volatile uint32_t*)0x02000008)

//Processor mapped custom Registers
#define DP_CONTROL      (*(volatile uint32_t*)0x02001000)
#define DP_STATUS       (*(volatile uint32_t*)0x02001004)
#define DP_OUTPUT       (*(volatile uint32_t*)0x0200100C)
#define DP_INPUT        (*(volatile uint32_t*)0x02001010) 


//Dummy array to simulate Flash Data
const uint8_t test_image[] = {
    0x00, 0xFF, 0x00, 0xFF, 0x10, 0x20, 0x30, 0x40,
    0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF
};

void putchar(char c) {
    if (c == '\n') putchar('\r');
    REG_UART_DATA = c;
}

void print(const char *p) {
    while (*p) putchar(*(p++));
}

void print_hex(uint8_t val) {
    const char hex[] = "0123456789ABCDEF";
    putchar(hex[val >> 4]);
    putchar(hex[val & 0xF]);
}


void main() {
    REG_UART_CLKDIV = 104;
    
    print("Booting from RAM...\n");
    print("Reading Image from SPI Flash\n");

    //Invert Mode
    DP_CONTROL = 0x03; 

    volatile uint8_t *flash_image = (uint8_t *)FLASH_IMAGE_ADDR;

    print("Processing:\n");

    //Process 16 pixels from Flash
    for(int i = 0; i < 16; i++) {
        
        uint8_t pixel = flash_image[i]; 
        
        DP_INPUT = pixel;
        
        while((DP_STATUS & 0x02) == 0);
        
        print_hex(DP_OUTPUT & 0xFF);
        print(" ");
    }
    
    print("\nDone.\n");
    
    DP_CONTROL = 0x00;
    while(1);
}
