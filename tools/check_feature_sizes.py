from PIL import Image
import os

files = [
    'assets/playstore/feature_graphic.png',
    'assets/playstore/feature_graphic_left_brand.png',
    'assets/playstore/feature_graphic_left_brand_thumb.png',
    'assets/playstore/feature_graphic_centered.png',
    'assets/playstore/feature_graphic_centered_thumb.png',
    'assets/playstore/feature_graphic_minimal.png',
    'assets/playstore/feature_graphic_minimal_thumb.png',
]

for f in files:
    if os.path.exists(f):
        with Image.open(f) as im:
            print(f, im.size)
    else:
        print(f, 'MISSING')
