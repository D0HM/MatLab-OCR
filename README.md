# Challenge02: Scene Text Detection and Recognition under Texture Text Images

See README_TH.md for the complete Thai guide.

This revision uses the seven supplied original images and makes Frequency Domain Transformation the preprocessing core required by Challenge02.pdf (at least 50% of the actual project workload; the PDF does not specify a counting formula).

Requirements: MATLAB R2020b+, Image Processing Toolbox, Computer Vision Toolbox.

```matlab
check_requirements
run_tests
run_challenge
```

Default experiment: M0 original vs F1 FFT Gaussian lowpass vs F2 FFT homomorphic illumination correction + FFT Gaussian lowpass + FFT highboost. Every returned OCR bounding box, recognized text and word confidence is exported to ocr_results.csv. Frequency spectra, transfer functions and reconstruction panels are exported for slides.

The seven images are a case study, not an independent held-out benchmark. All 19 seed word annotations are drafts. Accuracy is intentionally unavailable until annotations have been completed/reviewed using review_annotations. OCR predictions and confidence require no GT approval to run. Do not mark incomplete full-image annotations as reviewed.

The authoring environment did not contain MATLAB. Runtime OCR integration and MATLAB unit tests must be verified locally. Python frequency previews/numerical checks are supplementary and are not MATLAB or OCR results. start_demo remains available for the separate synthetic smoke-test dataset.

## Method F3 (optional, slow): multi-variant FFT lowpass + OCR voting
Enable: `cfg = project_config('provided'); cfg.Methods = ["M0","F1","F2","F3"]; run_experiment(cfg)`.
For each channel (gray, saturation) x Gaussian cutoff x downscale, `fft_variants` builds an OCR input, `ocr_variants_core` runs OCR on all, maps boxes back to the original image, keeps letters/digits only, requires `F3MinVotes` agreeing reads, then merges by confidence. Settings: `cfg.F3*` in project_config.m.
Cost: 2 channels x 3 cutoffs x 15 scales = 90 OCR calls per image (CPU-only: expect minutes per image). `fft_variants` uses base MATLAB only; `ocr` still needs Computer Vision Toolbox.
Supplementary (not MATLAB): `python tools/tune_frequency.py [--quick]` sweeps F1/F2 cutoffs with Tesseract.
