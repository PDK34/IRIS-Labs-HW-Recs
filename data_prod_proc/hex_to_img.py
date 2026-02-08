from PIL import Image

def hex_to_image(input_file, output_file, size=(32, 32)):
    try:
        with open(input_file, 'r') as f:
            # Read hex strings and convert to integers
            # Works even if there are comments or empty lines
            hex_data = [line.strip() for line in f if line.strip() and not line.startswith('//')]
            pixels = [int(h, 16) for h in hex_data]

        if len(pixels) < size[0] * size[1]:
            print(f"Warning: Only found {len(pixels)} pixels. Image might be incomplete.")
            # Pad with zeros if data is short
            pixels += [0] * (size[0] * size[1] - len(pixels))
        
        # Create image from the pixel list
        img = Image.new('L', size)
        img.putdata(pixels[:size[0] * size[1]])
        
        # Save and scale up so you can actually see it (32x32 is tiny!)
        img.save(output_file)
        img.resize((256, 256), resample=Image.NEAREST).show()
        print(f"Success! Image saved as {output_file}")

    except Exception as e:
        print(f"Error: {e}")

# Usage
hex_to_image('image.hex', 'Original_checkerboard.jpg')
hex_to_image('output_bypass.hex', 'bypass_checkerboard.jpg')
hex_to_image('output_invert.hex', 'invert_checkerboard.jpg')
hex_to_image('output_conv.hex', 'conv_checkerboard.jpg')
