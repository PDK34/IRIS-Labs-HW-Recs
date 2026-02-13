#!/usr/bin/env python3
"""
makehex.py - Convert binary to 32-bit hex words for RAM boot
"""
import sys

def main():
    if len(sys.argv) < 3:
        print("Usage: makehex.py <input.bin> <output.hex>", file=sys.stderr)
        sys.exit(1)
    
    binfile = sys.argv[1]
    hexfile = sys.argv[2]
    
    #Read binary
    with open(binfile, 'rb') as f:
        data = f.read()
    
    #Pad to 4-byte boundary
    while len(data) % 4 != 0:
        data += b'\x00'
    
    #Write as 32-bit little-endian words
    with open(hexfile, 'w') as f:
        for i in range(0, len(data), 4):
            # Little-endian: LSB first
            word = (data[i+0]) | (data[i+1] << 8) | (data[i+2] << 16) | (data[i+3] << 24)
            f.write(f"{word:08x}\n")
    
    print(f"Generated {len(data)//4} words in {hexfile}")

if __name__ == '__main__':
    main()
