from PIL import Image, ImageDraw, ImageFont, ImageFilter
import sys
import os

# Simple generator for a 1024x500 feature graphic based on existing app icon and draft composition.
# Usage:
#   python generate_feature_graphic.py [icon_path] [output_path]

ICON_PATH = sys.argv[1] if len(sys.argv) > 1 else "./assets/icons/app_icon-512.png"
OUTPUT_PATH = sys.argv[2] if len(sys.argv) > 2 else "./assets/playstore/feature_graphic.png"

W, H = 1024, 500
BACKGROUND = (37, 37, 37)  # dark gray
TEXT = "Grow, stay\nbalanced."

os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)

# Load font: try bundled common fonts, fall back to default
font_paths = [
    "C:/Windows/Fonts/SegoeUI-Bold.ttf",
    "C:/Windows/Fonts/Arialbd.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
]
font_path = None
for p in font_paths:
    if os.path.exists(p):
        font_path = p
        break

if not font_path:
    # Last resort: PIL's default font (not ideal)
    from PIL import ImageFont
    font = ImageFont.load_default()
else:
    font = ImageFont.truetype(font_path, 96)

# Create canvas
img = Image.new('RGB', (W, H), BACKGROUND)
draw = ImageDraw.Draw(img)

# Optional subtle gradient
for y in range(H):
    alpha = y / H
    r = int(BACKGROUND[0] * (1 - 0.06 * alpha))
    g = int(BACKGROUND[1] * (1 - 0.06 * alpha))
    b = int(BACKGROUND[2] * (1 - 0.06 * alpha))
    draw.line([(0, y), (W, y)], fill=(r, g, b))

# Load icon and compose a simple stylized scale using the icon as right coin
try:
    icon = Image.open(ICON_PATH).convert('RGBA')
    icon = icon.resize((220, 220), Image.LANCZOS)
except Exception as e:
    icon = None
    print(f"Warning: couldn't load icon at {ICON_PATH}: {e}")

# Draw headline on left
text_x = 80
text_y = 40
# Slightly larger headline
try:
    font = ImageFont.truetype(font_path, 110) if font_path else font
except Exception:
    font = font

# Draw slightly bolder white text by drawing multiple offset copies
text_lines = TEXT.split('\n')
line_height = 100
for i, line in enumerate(text_lines):
    x = text_x
    y = text_y + i * line_height
    # shadow / stroke imitation (subtle)
    for ox, oy in [(0,0),(1,0),(0,1)]:
        draw.text((x+ox, y+oy), line, font=font, fill=(245,245,245))

# Draw simple scale baseline and pivot (nudge right a bit)
pivot_x = W // 2 + 90
pivot_y = H // 2 + 40
bar_length = 360
bar_height = 12
bar_color = (60, 130, 255)
# bar
draw.rectangle([ (pivot_x - bar_length//2, pivot_y - bar_height//2), (pivot_x + bar_length//2, pivot_y + bar_height//2) ], fill=bar_color)
# pivot
draw.rectangle([ (pivot_x - 22, pivot_y - 8), (pivot_x + 22, pivot_y + 72) ], fill=bar_color)

# Draw icon as right coin but contained in a circular coin with margin so it doesn't cover the bar
if icon:
    coin_diameter = 220
    coin_margin = 18
    # Create coin background
    coin = Image.new('RGBA', (coin_diameter, coin_diameter), (0,0,0,0))
    coin_draw = ImageDraw.Draw(coin)
    coin_center = coin_diameter // 2
    # coin gradient-ish fill
    coin_draw.ellipse([(0,0),(coin_diameter,coin_diameter)], fill=(50,110,230,255))
    # paste resized icon centered inside coin with a margin
    inner_size = coin_diameter - coin_margin*2
    icon_small = icon.resize((inner_size, inner_size), Image.LANCZOS)
    icon_pos = (coin_margin, coin_margin)
    coin.paste(icon_small, icon_pos, icon_small)
    # position coin to the right, not overlapping the bar
    coin_x = pivot_x + bar_length//2 + 30
    coin_y = pivot_y - coin_diameter//2 - 10
    img.paste(coin, (coin_x, coin_y), coin)

# Save
img.save(OUTPUT_PATH, format='PNG')
print(f"Saved feature graphic to {OUTPUT_PATH}")
