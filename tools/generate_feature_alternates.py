from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1024, 500
BACKGROUND = (37, 37, 37)
BRAND = "Rebalance"

def load_font(size):
    paths = [
        "C:/Windows/Fonts/SegoeUI-Bold.ttf",
        "C:/Windows/Fonts/Arialbd.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
    ]
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def save(img, name):
    out_dir = os.path.join('assets', 'playstore')
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, name)
    img.save(path, 'PNG')
    print('Saved', path)

def variant_left_brand():
    img = Image.new('RGB', (W,H), BACKGROUND)
    draw = ImageDraw.Draw(img)
    # small brand top-left
    brand_font = load_font(28)
    draw.text((80, 28), BRAND, font=brand_font, fill=(180,180,180))
    # headline smaller
    hfont = load_font(84)
    text = "Grow, stay\nbalanced."
    draw.text((80, 80), text, font=hfont, fill=(245,245,245))
    # simple scale silhouette at right (no icon)
    pivot_x = W//2 + 90
    pivot_y = H//2 + 40
    bar_color = (60,130,255)
    draw.rectangle([(pivot_x-180, pivot_y-6),(pivot_x+180,pivot_y+6)], fill=bar_color)
    draw.rectangle([(pivot_x-20,pivot_y-8),(pivot_x+20,pivot_y+70)], fill=bar_color)
    save(img, 'feature_graphic_left_brand.png')
    # thumbnail
    save(img.resize((512,250), Image.LANCZOS), 'feature_graphic_left_brand_thumb.png')

def variant_centered():
    img = Image.new('RGB', (W,H), BACKGROUND)
    draw = ImageDraw.Draw(img)
    # headline centered
    hfont = load_font(78)
    text = "Grow, stay balanced."
    # measure with textbbox
    bbox = draw.textbbox((0,0), text, font=hfont)
    w = bbox[2] - bbox[0]
    hh = bbox[3] - bbox[1]
    draw.text(((W-w)/2, 110), text, font=hfont, fill=(245,245,245))
    # brand small below
    bfont = load_font(30)
    bb = draw.textbbox((0,0), BRAND, font=bfont)
    bw = bb[2] - bb[0]
    bh = bb[3] - bb[1]
    draw.text(((W-bw)/2, 110+hh+20), BRAND, font=bfont, fill=(180,180,180))
    # scale silhouette lower
    pivot_x = W//2
    pivot_y = H//2 + 60
    bar_color = (60,130,255)
    draw.rectangle([(pivot_x-200, pivot_y-6),(pivot_x+200,pivot_y+6)], fill=bar_color)
    draw.rectangle([(pivot_x-20,pivot_y-8),(pivot_x+20,pivot_y+70)], fill=bar_color)
    save(img, 'feature_graphic_centered.png')
    save(img.resize((512,250), Image.LANCZOS), 'feature_graphic_centered_thumb.png')

def variant_minimal():
    img = Image.new('RGB', (W,H), BACKGROUND)
    draw = ImageDraw.Draw(img)
    # brand big and subtle
    bfont = load_font(44)
    draw.text((80, 60), BRAND, font=bfont, fill=(220,220,220))
    # single-line headline smaller
    hfont = load_font(64)
    draw.text((80, 120), "Stay balanced.", font=hfont, fill=(245,245,245))
    # small scale icon-left bottom
    pivot_x = W//2 + 140
    pivot_y = H//2 + 40
    bar_color = (60,130,255)
    draw.rectangle([(pivot_x-150, pivot_y-5),(pivot_x+150,pivot_y+5)], fill=bar_color)
    draw.rectangle([(pivot_x-18,pivot_y-6),(pivot_x+18,pivot_y+60)], fill=bar_color)
    save(img, 'feature_graphic_minimal.png')
    save(img.resize((512,250), Image.LANCZOS), 'feature_graphic_minimal_thumb.png')

def variant_choice_full_slogan():
    img = Image.new('RGB', (W,H), BACKGROUND)
    draw = ImageDraw.Draw(img)
    # brand top-left
    bfont = load_font(40)
    draw.text((80, 40), BRAND, font=bfont, fill=(220,220,220))
    # full slogan (two parts) - keep 'Grow, Stay Balanced.' on two lines but slightly larger
    hfont = load_font(88)
    text = "Grow, Stay\nBalanced."
    draw.text((80, 100), text, font=hfont, fill=(245,245,245))
    # scale silhouette right
    pivot_x = W//2 + 120
    pivot_y = H//2 + 30
    bar_color = (60,130,255)
    draw.rectangle([(pivot_x-200, pivot_y-6),(pivot_x+200,pivot_y+6)], fill=bar_color)
    draw.rectangle([(pivot_x-20,pivot_y-8),(pivot_x+20,pivot_y+72)], fill=bar_color)
    save(img, 'feature_graphic_choice.png')
    save(img.resize((512,250), Image.LANCZOS), 'feature_graphic_choice_thumb.png')

if __name__ == '__main__':
    variant_left_brand()
    variant_centered()
    variant_minimal()
    variant_choice_full_slogan()
