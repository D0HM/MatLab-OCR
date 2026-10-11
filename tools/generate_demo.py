#!/usr/bin/env python3
"""Reproduce 30 synthetic smoke-test images with exact word boxes.
Optional developer tool only: Python, Pillow, NumPy. MATLAB needs neither.
Usage: python tools/generate_demo.py [--font /path/to/DejaVuSans-Bold.ttf]
"""
from pathlib import Path
import argparse
import csv
import io
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
PHRASES = [
    'FOREST CAMP', 'OPEN TODAY', 'WOODEN SIGN', 'FRESH COFFEE', 'WELCOME HOME',
    'TEXTURE TEST', 'GREEN MARKET', 'READ THIS', 'CITY LIBRARY', 'PARK ENTRANCE',
    'WATER STATION', 'LOCAL SHOP', 'NORTH ROAD', 'SAFETY FIRST', 'QUIET ZONE',
    'ICE CREAM', 'MAIN GATE', 'BOOK STORE', 'NATURE TRAIL', 'PHOTO LAB',
    'RED BRICK', 'SMALL CAFE', 'NEXT EXIT', 'FOOD COURT', 'SLOW DOWN',
    'PUBLIC PARK', 'NIGHT MARKET', 'RIVER WALK', 'ART STUDIO', 'SCIENCE CLUB',
]

def write_csv(path, rows, columns):
    with path.open('w', newline='', encoding='utf-8') as stream:
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--font', default='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf')
    args = parser.parse_args()
    font_path = Path(args.font)
    if not font_path.is_file():
        raise SystemExit('Supply a TrueType bold sans-serif font using --font.')
    out = ROOT / 'data/demo'
    (out / 'images').mkdir(parents=True, exist_ok=True)
    manifest, gt = [], []
    width, height = 1000, 400
    yy, xx = np.mgrid[:height, :width]
    for group_index, texture in enumerate(['simple', 'moderate', 'complex']):
        for j in range(10):
            rng = np.random.default_rng(20261009 + 100*group_index + j)
            light_text = j in [3, 8]
            base = 52 if light_text else 208
            field = np.full((height, width), base, dtype=float)
            if texture == 'moderate':
                field += 12*np.sin(xx/13 + 0.5*np.sin(yy/28)) + 6*np.sin(xx/4)
                field += (yy % 100 < 3)*(-25)
            if texture == 'complex':
                field += 22*np.sin(xx/7)*np.cos(yy/11) + 12*np.sin((xx+yy)/8)
                field += ((yy % 60 < 5) | ((xx + (yy//60 % 2)*80) % 160 < 5))*(-26)
                field += rng.normal(0, 8, field.shape)
            field += 12*(xx/width-0.5) + rng.normal(0, 1.5, field.shape)
            channels = [np.clip(field+v, 0, 255) for v in [10, 1, -12]]
            image = Image.fromarray(np.stack(channels, axis=-1).astype('uint8'))
            draw = ImageDraw.Draw(image)
            font_size = 48 + 4*(j % 4)
            font = ImageFont.truetype(str(font_path), font_size)
            words = PHRASES[group_index*10+j].split()
            gap = 26
            sizes = [draw.textbbox((0, 0), word, font=font) for word in words]
            lengths = [b[2]-b[0] for b in sizes]
            start_x = int((width-sum(lengths)-gap*(len(words)-1))/2)
            top_y = 165 + (j % 3)*5
            image_id = f'{texture}_{j+1:02d}'
            for word_index, (word, box, word_width) in enumerate(zip(words, sizes, lengths), 1):
                origin = (start_x-box[0], top_y-box[1])
                color = (241, 244, 237) if light_text else (25, 30, 26)
                draw.text(origin, word, font=font, fill=color)
                # PIL is zero-based; MATLAB CSV is 1-based, half-open [x,x+width).
                gt.append(dict(image_id=image_id, word_index=word_index, x=start_x+1,
                               y=top_y+1, width=word_width, height=box[3]-box[1], text=word))
                start_x += word_width+gap
            filename = f'{image_id}.png'
            encoded = io.BytesIO()
            image.save(encoded, format='PNG')
            destination = out / 'images' / filename
            temporary = destination.with_suffix('.tmp')
            with temporary.open('wb') as stream:
                stream.write(encoded.getvalue())
                stream.flush()
                os.fsync(stream.fileno())
            temporary.replace(destination)
            manifest.append(dict(image_id=image_id, filename=filename, texture=texture,
                                 split='dev' if j < 5 else 'test',
                                 source='synthetic_demo', has_text=1))
    write_csv(out/'manifest.csv',manifest,['image_id','filename','texture','split','source','has_text'])
    write_csv(out/'ground_truth.csv',gt,['image_id','word_index','x','y','width','height','text'])
    print(f'Generated {len(manifest)} images and {len(gt)} word boxes in {out}')

if __name__ == '__main__':
    main()
