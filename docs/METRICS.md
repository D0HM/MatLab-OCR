# Challenge02 annotation status and scoring

All seven provided images start with annotation_status=draft. The 19 word-box seeds are incomplete/provisional. RequireReviewedGT=true prevents Recognition Rate, CER, WER and detection scores from being computed from these drafts. Raw recognized text, every returned box and confidence are still exported and displayed. summary.ScoredImages tells how many images actually supplied reviewed accuracy measurements; summary.Images includes every processed image. Confidence and returned-word counts are not accuracy.

Complete ALL readable word labels and verify boxes/order before marking an image reviewed. There is no ignore-region protocol in this version. Do not mark primary-word-only annotations reviewed on an image with additional readable text; that would count legitimate unlabelled words as false positives. Keep an image draft if cropped/unreadable text cannot be evaluated fairly, and report only raw OCR outputs for that image until an ignore-region evaluator or complete annotation policy is implemented.

The seven provided images are a case study, not an independent test split. Annotation boxes do not restrict OCR input regions; prediction always receives the full image. The OCR confidence CSV covers every returned box, including words outside the seed annotation set.

The definitions below apply only when labels are complete and reviewed.

# Evaluation contract

## Annotation and matching

One GT row per readable word. `word_index` is the explicit reading order in the image. All coordinates use the original image size, 1-based top-left position and `[x, y, width, height]`, interpreted as half-open extents `[x,x+width)` and `[y,y+height)`. Synthetic PIL coordinates are converted from zero-based to MATLAB coordinates.

IoU = intersection area / union area. Default threshold = 0.5. `match_boxes` uses maximum-cardinality bipartite matching, so no GT or prediction is counted twice. Candidate neighbors are tried in descending IoU order, but the algorithm does not optimize the sum of IoU across all maximum-cardinality solutions. These are project-specific axis-aligned evaluation rules, not a claim to implement an official ICDAR evaluator.

Predictions are not filtered by confidence at the default setting. No Ground Truth is passed to preprocessing or prediction. Change thresholds on dev only.

## Detection

TP = matched GT/candidate pairs; FP = unmatched candidates; FN = unmatched GT.

- Precision = TP/(TP+FP)
- Recall = TP/(TP+FN)
- F1 = 2TP/(2TP+FP+FN)

Zero denominator -> NaN (undefined). When GT exists but there are no detections, recall=0 and F1=0, while precision is undefined. Negative-only images with any candidates have F1=0. Negative images with no candidates have undefined F1 rather than an invented 100%.

**Two detector definitions must remain separate:** `ocr` candidates are the returned recognized-word boxes. `mser` candidates are word-like regions before recognition, even when OCR returns no word. `WordTP/WordFP/WordFN` in image_results always evaluate returned recognized-word boxes, independent of the detector's candidate evaluation. Detection depends only on geometry; a matched but incorrectly read word can still be a detection TP.

## Per-word Recognition Rate

For each GT word g, match against returned recognized-word boxes. Let d be Levenshtein character edit distance between normalized GT and its matched prediction. A missed word uses an empty prediction.

`RecognitionRatePct(g) = 100 * max(0, 1 - d / length(GT(g)))`

The image score is the mean over **all GT words**, including zeros for missed words. The summary score is the mean of defined image scores; each image gets equal weight. A word matched geometrically but read incorrectly contributes a partial score. Case is ignored by default, punctuation retained. This formula is explicitly chosen for this project; the instructor's example table provides recognition-rate examples but does not specify an edit-distance formula. If the instructor requires a different definition, change this function and clearly report that definition.

False-positive words appear in word_results with `Status=false_positive`, `WordIndex=0`, no GT, and an undefined word rate. They are penalized by detection FP and full-image CER/WER, rather than being averaged as legitimate GT words. Therefore a 100% GT macro recognition rate does NOT prove absence of false positives.

ExactWordRatePct = 100 * exactly correct, geometrically matched GT words / number of GT words. The summary pools word counts rather than averaging image rates.

## Standard full-image sequence CER and WER

Build the GT string from word_index order, joining words with one space. Build the predicted string using approximate horizontal reading order of returned word boxes. Normalize both using the same case/punctuation/whitespace policy.

- CER = character Levenshtein distance / number of GT characters (including normalized interword spaces).
- WER = word-token Levenshtein distance / number of GT tokens.

These are sequence metrics. They account for omitted and extra text without using geometric matching, and are sensitive to reading-order errors. CER and WER can exceed 1 due to insertions; they are **not clipped**. GT-empty image CER/WER is undefined. Summary CER/WER pool edit counts and GT lengths across images; extra text on negative images still contributes edits to the pooled numerator when positive images supply a denominator.

Example: GT `hello world`, prediction `hello` gives WER=0.5 and CER=6/11. Two perfect matched GT words plus an extra `fake` word give GT macro rate=100%, but WER=0.5 and nonzero CER/FP.

## Confidence

AvgConfidence(image) = arithmetic mean of finite returned word confidences. No returned words -> NaN. AvgConfidence(summary) = mean of defined image confidences. A word's confidence is taken from `ocrText.WordConfidences`, not estimated from correct text. It does not include a penalty for undetected words. Confidence is not measured recognition accuracy and is not assumed to be calibrated for this dataset.

## Summary weighting

| Quantity | Aggregation |
|---|---|
| RecognitionRatePct | Macro mean of defined image-level GT-word macro scores |
| AvgConfidence | Macro mean of defined image-level returned-word mean confidences |
| ExactWordRatePct | Pooled exact GT word count / GT word count |
| Detection P/R/F1 | Pooled candidate TP/FP/FN |
| CER / WER | Pooled edit counts / pooled GT lengths |
| SecondsPerImage | Mean preprocessing + detection/recognition wall time |

Time excludes dataset validation, evaluation, rendering and CSV writes. First OCR invocation may include initialization. It is descriptive, not a controlled runtime benchmark.
