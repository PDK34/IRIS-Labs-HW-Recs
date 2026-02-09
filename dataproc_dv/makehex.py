#!/usr/bin/env python3
"""
makehex.py - Convert binary file to hex format for Verilog $readmemh

"""

import sys

def main():
    if len(sys.argv) < 3:
        print("Usage: makehex.py <input.bin> <size_in_bytes>", file=sys.stderr)
        sys.exit(1)
    
    binfile = sys.argv[1]
    size = int(sys.argv[2])
    
    # Read binary file
    with open(binfile, 'rb') as f:
        data = f.read()
    
    # Pad to size
    if len(data) > size:
        print(f"Error: Binary file ({len(data)} bytes) larger than size ({size} bytes)", 
              file=sys.stderr)
        sys.exit(1)
    
    data = data + b'\x00' * (size - len(data))
    
    # Output as hex (32-bit words)
    for i in range(0, len(data), 4):
        word = data[i:i+4]
        # Little-endian 32-bit word
        val = word[0] | (word[1] << 8) | (word[2] << 16) | (word[3] << 24)
        print(f"{val:08x}")

if __name__ == '__main__':
    main()
