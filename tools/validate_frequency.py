#!/usr/bin/env python3
"""Independent NumPy reproduction of FFT formulas, NOT MATLAB execution/OCR.
Checks conjugate symmetry, DC behavior and lowpass attenuation, and exports
a numerical preprocessing preview for all supplied images.
"""
from pathlib import Path
import io
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
CFG = dict(lp=0.065, homo=0.025, gamma_l=0.6, gamma_h=1.2, boost_sigma=0.04, boost=0.3)

def filter_fft(array, kind):
    rows, cols = array.shape
    u = np.arange(-(cols//2), (cols+1)//2) / cols
    v = np.arange(-(rows//2), (rows+1)//2) / rows
    U, V = np.meshgrid(u, v)
    radius2 = U**2 + V**2
    if kind == 'lowpass':
        H = np.exp(-radius2/(2*CFG['lp']**2))
    elif kind == 'homomorphic':
        H = CFG['gamma_l'] + (CFG['gamma_h']-CFG['gamma_l'])*(1-np.exp(-radius2/(2*CFG['homo']**2)))
    elif kind == 'highboost':
        H = 1 + CFG['boost']*(1-np.exp(-radius2/(2*CFG['boost_sigma']**2)))
    else:
        raise ValueError(kind)
    spectrum = np.fft.fftshift(np.fft.fft2(array))
    inverse = np.fft.ifft2(np.fft.ifftshift(spectrum*H))
    assert np.max(np.abs(inverse.imag)) <= 1e-8*max(1, np.max(np.abs(inverse)))
    return inverse.real

def scaled_u8(array):
    if np.ptp(array) <= np.finfo(float).eps:
        return np.zeros(array.shape, dtype=np.uint8)
    return np.clip(np.rint(255*(array-array.min())/np.ptp(array)),0,255).astype(np.uint8)

def preprocess(image, method):
    rgb = np.asarray(image.convert('RGB'),dtype=float)/255
    # MATLAB rgb2gray weights; tiny rounding differences can remain.
    gray = rgb @ np.array([0.2989360213, 0.5870430745, 0.1140209043])
    gray = np.rint(gray*255)/255
    pad = max(8, round(min(gray.shape)*0.15))
    A = np.pad(gray, ((pad,pad),(pad,pad)), mode='symmetric')
    if method == 'F2':
        A = np.exp(filter_fft(np.log(np.maximum(A,1/255)),'homomorphic'))
    A = filter_fft(A,'lowpass')
    if method == 'F2':
        A = filter_fft(A,'highboost')
    return Image.fromarray(scaled_u8(A[pad:-pad,pad:-pad]))

def main():
    for shape in [(15,18),(16,17),(19,20)]:
        constant = np.full(shape,0.4)
        np.testing.assert_allclose(filter_fft(constant,'lowpass'),constant,atol=1e-12)
        np.testing.assert_allclose(filter_fft(constant,'highboost'),constant,atol=1e-12)
        np.testing.assert_allclose(filter_fft(constant,'homomorphic'),constant*CFG['gamma_l'],atol=1e-12)
    x = np.meshgrid(np.arange(64),np.arange(64))[0]
    A = np.sin(2*np.pi*0.25*x)
    assert filter_fft(A,'lowpass').std() < 0.01*A.std()
    paths = sorted((ROOT/'data/provided/images').glob('*.jpg'))
    assert len(paths) == 7
    canvas = Image.new('RGB',(1080, len(paths)*260+100),'white')
    draw = ImageDraw.Draw(canvas)
    font_path = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
    font = ImageFont.truetype(font_path,18) if Path(font_path).is_file() else ImageFont.load_default()
    draw.text((12,10),'NumPy formula preview - NOT MATLAB output or OCR results',fill='black',font=font)
    for c,label in enumerate(['Original', 'F1: FFT lowpass','F2: three FFT stages']):
        draw.text((c*360+12,45),label,fill='black',font=font)
    for r,path in enumerate(paths):
        image = Image.open(path).convert('RGB')
        outputs = [image,preprocess(image,'F1'),preprocess(image,'F2')]
        for c,result in enumerate(outputs):
            assert result.size == image.size
            if c > 0:
                assert np.isfinite(np.asarray(result)).all()
            thumb = result.convert('RGB'); thumb.thumbnail((340,210))
            canvas.paste(thumb,(c*360+10,95+r*260))
        draw.text((12,315+r*260),path.name,fill='black',font=font)
    folder = ROOT/'docs/previews'; folder.mkdir(parents=True,exist_ok=True)
    encoded=io.BytesIO(); canvas.save(encoded,format='PNG')
    destination=folder/'frequency_formula_preview.png'; temp=destination.with_suffix('.tmp')
    with temp.open('wb') as stream:
        stream.write(encoded.getvalue()); stream.flush(); os.fsync(stream.fileno())
    temp.replace(destination)
    print('PASS: independent FFT DC/symmetry/attenuation checks and 7-image preprocessing preview.')
    print('This does NOT execute the MATLAB code or measure OCR accuracy.')

if __name__ == '__main__':
    main()
