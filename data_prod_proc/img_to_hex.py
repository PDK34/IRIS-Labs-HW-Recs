from PIL import Image

# Convert image to 32x32 grayscale hex
img = Image.open('bird.jpg').convert('L').resize((32, 32))
pixels = list(img.getdata())

with open('image.hex', 'w') as f:
    for pixel in pixels:
        f.write(f'{pixel:02X}\n')

print("Created image.hex")
