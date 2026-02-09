#!/usr/bin/env python3
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
    
    # Output as hex (one byte per line)
    for byte in data:
        print(f"{byte:02x}")

if __name__ == '__main__':
    main()
