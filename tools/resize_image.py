from PIL import Image
import sys

if len(sys.argv) < 4:
    print("Usage: python resize_image.py <input> <output> <width> <height>")
    sys.exit(1)

input_path = sys.argv[1]
output_path = sys.argv[2]
width = int(sys.argv[3])
height = int(sys.argv[4])

img = Image.open(input_path)
# Preserve aspect ratio by fitting into box then centering on transparent background if needed
img = img.convert('RGBA')
img.thumbnail((width, height), Image.LANCZOS)

background = Image.new('RGBA', (width, height), (255,255,255,0))
# center
x = (width - img.width) // 2
y = (height - img.height) // 2
background.paste(img, (x, y), img)
background.save(output_path)
print(f"Saved resized image to {output_path}")