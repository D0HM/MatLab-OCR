# Sources

Primary assignment: the user-supplied Challenge02.pdf, bundled at docs/Challenge02.pdf. Page 3 requires Frequency Domain Transformation as the preprocessing foundation (at least 50% of actual project workload), recognized text and confidence for every detected text bounding box, and links MATLAB OCR documentation. It does not specify an exact workload-counting formula, a fixed data count, train/test split, or an accuracy-metric formula.

User-supplied course context: Chapter 4 EP I (Frequency Domain Processing / DFT / IDFT) and Chapter 4 EP II (Frequency Domain Filtering). The other course PDFs are not redistributed. The original grading rubric is referenced in the experiment plan and was visually inspected in the earlier project turn.

Official MathWorks documentation checked during project authoring:

- https://www.mathworks.com/help/vision/ref/ocr.html
- https://www.mathworks.com/help/releases/R2022b/vision/ref/ocr.html
- https://www.mathworks.com/help/vision/ref/ocrtext.html
- https://www.mathworks.com/help/vision/ref/detectmserfeatures.html
- https://www.mathworks.com/help/vision/ug/automatically-detect-and-recognize-text-in-natural-images.html

The frequency core, dataset runner, annotation workflow and evaluation code were authored for this project. MSER/OCR are toolbox functions, not new algorithms claimed by the project. The seven main photographs/images are original user-supplied bytes; see data/provided/source_checksums.csv. They are included for the user's course project; no unrelated source/license attribution is invented. The separate 30-image synthetic dataset remains a developer smoke test, not the assigned dataset.
