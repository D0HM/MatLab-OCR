#!/usr/bin/env python3
"""Validate bundled demo bytes/annotations; does not execute MATLAB or OCR."""
from collections import Counter
from pathlib import Path
import csv
import hashlib
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

def main():
    data = ROOT / 'data/demo'
    with (data / 'manifest.csv').open(encoding='utf-8', newline='') as stream:
        manifest = list(csv.DictReader(stream))
    with (data / 'ground_truth.csv').open(encoding='utf-8', newline='') as stream:
        gt = list(csv.DictReader(stream))
    assert len(manifest) == 30 and len(gt) == 60
    images = {row['image_id']: row for row in manifest}
    assert len(images) == 30
    counts = Counter((row['texture'], row['split']) for row in manifest)
    assert counts == Counter({(texture, split): 5 for texture in
                             ['simple', 'moderate', 'complex'] for split in ['dev', 'test']})
    dimensions = {}
    for image_id, row in images.items():
        with Image.open(data / 'images' / row['filename']) as image:
            image.load()  # Detect truncated PNG streams, not just readable headers.
            dimensions[image_id] = image.size
    indices = set()
    for row in gt:
        width, height = dimensions[row['image_id']]
        x, y, w, h = [int(row[key]) for key in ['x', 'y', 'width', 'height']]
        assert x >= 1 and y >= 1 and w > 0 and h > 0
        assert x + w <= width + 1 and y + h <= height + 1
        assert row['text'] and not any(c.isspace() for c in row['text'])
        key = row['image_id'], int(row['word_index'])
        assert key not in indices
        indices.add(key)
    print('PASS: 30 readable PNGs, 60 valid word boxes, balanced 15/15 dev/test split.')
    data=ROOT/'data/provided'
    with (data/'manifest.csv').open(encoding='utf8',newline='') as stream:
        supplied=list(csv.DictReader(stream))
    with (data/'ground_truth.csv').open(encoding='utf8',newline='') as stream:
        draft=list(csv.DictReader(stream))
    with (data/'source_checksums.csv').open(encoding='utf8',newline='') as stream:
        checksums=list(csv.DictReader(stream))
    assert len(supplied)==7 and len(draft)==19
    sizes={}
    for row in supplied:
        assert row['split']=='provided' and row['annotation_status']=='draft'
        with Image.open(data/'images'/row['filename']) as image:
            image.load(); sizes[row['image_id']]=image.size
    for row in draft:
        width,height=sizes[row['image_id']]
        x,y,w,h=[int(row[key]) for key in ['x','y','width','height']]
        assert x>=1 and y>=1 and w>0 and h>0 and x+w<=width+1 and y+h<=height+1
    for row in checksums:
        assert hashlib.sha256((data/'images'/row['filename']).read_bytes()).hexdigest()==row['sha256']
    print('PASS: 7 original supplied JPGs, 19 bounded draft seeds, original byte checksums.')
    print('This validates data only. Run run_tests and run_challenge in MATLAB for runtime checks.')

if __name__ == '__main__':
    main()
