#!/usr/bin/env python3
"""Supplementary parameter sweep (NumPy + Tesseract), NOT MATLAB OCR.
Usage: python tools/tune_frequency.py [--psm 3] [--quick]
Scores F1/F2 settings against data/provided/ground_truth.csv (draft GT!).
Score per image = mean over GT words of best-match (IoU>=0.3) char similarity,
minus 0.25*false-positive-rate. Use only to shortlist cutoffs for MATLAB."""
import argparse, csv, itertools, sys
from pathlib import Path
import numpy as np
from PIL import Image
import pytesseract
from difflib import SequenceMatcher

ROOT = Path(__file__).resolve().parents[1]

def fft_filter(A, H_fn):
    r, c = A.shape
    u = np.arange(-(c//2), (c+1)//2)/c; v = np.arange(-(r//2), (r+1)//2)/r
    U, V = np.meshgrid(u, v); r2 = U**2+V**2
    F = np.fft.fftshift(np.fft.fft2(A))
    return np.fft.ifft2(np.fft.ifftshift(F*H_fn(r2))).real

def to_u8(A):
    p = np.ptp(A)
    return np.zeros(A.shape, np.uint8) if p < 1e-12 else np.clip(np.rint(255*(A-A.min())/p), 0, 255).astype(np.uint8)

def preprocess(gray, method, p):
    pad = max(8, round(min(gray.shape)*0.15))
    A = np.pad(gray, pad, mode='symmetric')
    if method == 'F2':
        low = lambda r2: p['hl'] + (p['hh']-p['hl'])*(1-np.exp(-r2/(2*p['hc']**2)))
        A = np.exp(fft_filter(np.log(np.maximum(A, 1/255)), low))
    A = fft_filter(A, lambda r2: np.exp(-r2/(2*p['lp']**2)))
    if method == 'F2':
        A = fft_filter(A, lambda r2: 1 + p['ba']*(1-np.exp(-r2/(2*p['bc']**2))))
    return to_u8(A[pad:-pad, pad:-pad])

def load_gt():
    gt = {}
    with open(ROOT/'data/provided/ground_truth.csv', newline='') as f:
        for r in csv.DictReader(f):
            gt.setdefault(r['image_id'], []).append((tuple(int(r[k]) for k in ('x','y','width','height')), r['text'].upper()))
    return gt

def iou(a, b):
    x1, y1 = max(a[0], b[0]), max(a[1], b[1])
    x2, y2 = min(a[0]+a[2], b[0]+b[2]), min(a[1]+a[3], b[1]+b[3])
    i = max(0, x2-x1)*max(0, y2-y1); u = a[2]*a[3]+b[2]*b[3]-i
    return i/u if u else 0

def ocr(img, psm):
    d = pytesseract.image_to_data(Image.fromarray(img), lang='eng', config=f'--psm {psm}', output_type=pytesseract.Output.DICT)
    out = []
    for t, c, x, y, w, h in zip(d['text'], d['conf'], d['left'], d['top'], d['width'], d['height']):
        t = ''.join(ch for ch in t if ch.isalnum() or ch == "'")
        if t and float(c) >= 0: out.append(((x, y, w, h), t.upper(), float(c)))
    return out

def score(gt, pred):
    s, used = 0.0, set()
    for box, txt in gt:
        best, bi = 0.0, None
        for i, (pb, pt, pc) in enumerate(pred):
            if i in used or iou(box, pb) < 0.3: continue
            sim = SequenceMatcher(None, txt.replace(' ', ''), pt).ratio()
            if sim > best: best, bi = sim, i
        if bi is not None: used.add(bi); s += best
    fp = len(pred)-len(used)
    return s/len(gt) - 0.25*fp/max(1, len(pred)), s/len(gt), fp

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--psm', type=int, default=3); ap.add_argument('--quick', action='store_true')
    a = ap.parse_args()
    gt = load_gt(); man = list(csv.DictReader(open(ROOT/'data/provided/manifest.csv', newline='')))
    grays = {}
    for r in man:
        im = np.asarray(Image.open(ROOT/'data/provided/images'/r['filename']).convert('RGB'), float)/255
        grays[r['image_id']] = np.rint((im @ [0.2989360213, 0.5870430745, 0.1140209043])*255)/255
    base = dict(lp=0.065, hc=0.025, hl=0.6, hh=1.2, bc=0.04, ba=0.3)
    def run(method, p):
        tot = []
        for iid, g in grays.items():
            P = to_u8(g) if method == 'M0' else preprocess(g, method, p)
            tot.append(score(gt[iid], ocr(P, a.psm)))
        return np.mean([t[0] for t in tot]), np.mean([t[1] for t in tot]), sum(t[2] for t in tot), [round(t[1], 2) for t in tot]
    print('M0', run('M0', base)); print('F1 default', run('F1', dict(base))); print('F2 default', run('F2', dict(base)))
    res = []
    lps = [0.04, 0.065, 0.09, 0.12, 0.18] if not a.quick else [0.065, 0.12]
    for lp in lps:
        res.append(('F1', dict(base, lp=lp), run('F1', dict(base, lp=lp))))
    hcs = [0.01, 0.025, 0.05] ; hls = [0.5, 0.7, 0.9]; bas = [0.0, 0.3, 0.8]
    if a.quick: hcs, hls, bas = [0.025], [0.6], [0.3]
    for lp, hc, hl, ba in itertools.product(lps, hcs, hls, bas):
        p = dict(base, lp=lp, hc=hc, hl=hl, ba=ba); res.append(('F2', p, run('F2', p)))
    res.sort(key=lambda r: -r[2][0])
    for m, p, r in res[:12]: print(m, {k: p[k] for k in ('lp', 'hc', 'hl', 'ba')}, 'score=%.3f charsim=%.3f FP=%d' % r[:3], r[3])

if __name__ == '__main__': main()
