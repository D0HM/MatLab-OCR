# Validation status — Challenge02 revision

Completed in the authoring environment:

- Fixed fieldless empty-struct initialization in summarize_results and run_experiment: assign the first complete record directly, then append subsequent records. Strengthened pooled-metric assertions and added three summary regression cases (multiple groups, draft only, mixed review status). The patch is statically checked; its MATLAB runtime results are pending.

- Added an early inspect_image check for a missing src folder or missing initial dependencies, with full-project extraction and duplicate-copy guidance. Checked statically; the MATLAB warning/error and file-picker paths were not executed here.

- Static MATLAB R2020b syntax/lint checks of all 34 .m files: no syntax errors.
- Decoded all seven supplied JPGs, checked source SHA-256 values and byte-identical copies.
- Validated bounds and uniqueness of the 19 seed word boxes. They remain DRAFT, not complete GT.
- Independently reproduced the FFT filter formulas in NumPy and checked DC preservation (lowpass/highboost), homomorphic DC gain, odd/even grid conjugate symmetry and high-frequency attenuation.
- Generated and visually inspected the seven-image Original/F1/F2 numerical preview. It is explicitly labelled NumPy output, not MATLAB or OCR results.
- Retained validation of the separate 30-image synthetic dataset and 60 word boxes.
- Verified packaged ZIP integrity and safe relative paths.

User-reported MATLAB run of the previous version: 17 of 18 tests passed; test_metrics/testSummaryPooling errored with MATLAB:heterogeneousStrucAssignment. This prompted the initialization fixes above. This log is evidence for the previous version, not a successful run of this patch.

NOT executed here: MATLAB itself, the 21 bundled MATLAB unit-test cases in this patched version, the OCR model/toolbox runtime, the full batch/sweep, annotation GUI interaction and MATLAB figure export. There is no MATLAB executable in the authoring environment. NumPy checks do not execute or validate all runtime semantics of the MATLAB implementation.

Run locally:

```matlab
check_requirements
run_tests
run_challenge
% Optional frequency parameter experiment:
run_frequency_sweep
```

The 21 MATLAB tests cover 16 metric/summary cases plus five FFT/draft-status cases. They do not call OCR. The batch entry tests actual installed toolbox integration and produces genuine outputs. Review annotation completeness before enabling accuracy reporting; run_challenge can show recognized text and every box confidence while annotations are draft.

Optional developer checks (Python + NumPy + Pillow):

```bash
python tools/validate_dataset.py
python tools/validate_frequency.py
```

`docs/previews/frequency_formula_preview.png` reproduces the nominal formulas with NumPy/Pillow. Tiny differences from MATLAB grayscale conversion or integer rounding can remain. It does not contain recognition confidence, recognized text or accuracy measurements.

Only a run.log ending in COMPLETE is a completed experiment. FAILED/partial output must not be presented as a completed run. No OCR scores are pre-filled in this package.
