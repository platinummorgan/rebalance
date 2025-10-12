from PIL import Image
import os

src_dir = os.path.join('assets','playstore')
files = [
    'feature_graphic.png',
    'feature_graphic_left_brand.png',
    'feature_graphic_centered.png',
    'feature_graphic_minimal.png',
    'feature_graphic_choice.png',
]

os.makedirs(src_dir, exist_ok=True)

for f in files:
    path = os.path.join(src_dir, f)
    if not os.path.exists(path):
        print('Missing', path)
        continue
    with Image.open(path) as im:
        # ensure it's 1024x500; if not, center-crop or resize while preserving aspect
        if im.size != (1024,500):
            im = im.resize((1024,500), Image.LANCZOS)
        out = os.path.join(src_dir, f.replace('.png','_preview_1024x500.png'))
        im.save(out, 'PNG')
        print('Saved', out)
