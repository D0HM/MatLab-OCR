# Challenge02 — Scene Text Detection and Recognition under Texture Text Images

เวอร์ชันนี้ปรับตาม **Challenge02.pdf ที่ผู้ใช้ส่งมา** โดยตรง ใช้ภาพต้นฉบับ 7 ภาพเป็นชุดข้อมูลหลัก และใช้ Frequency Domain Transformation เป็นแกนของ Preprocessing แทน Scope เวอร์ชันก่อน

## เริ่มรัน

1. แตก ZIP แล้วเปิดโฟลเดอร์ SceneTextTextureMATLAB เป็น Current Folder ของ MATLAB
2. ใช้ MATLAB R2020b ขึ้นไป พร้อม Image Processing Toolbox และ Computer Vision Toolbox
3. รัน:

```matlab
check_requirements
run_tests
outDir = run_challenge;
```

รอบหลักใช้ **7 ภาพ × 3 วิธี × OCR = 21 ชุดผล** ไม่มีการดาวน์โหลด dataset ภาพที่อยู่ใน `data/provided/images/` เป็นสำเนาไฟล์ต้นฉบับที่ส่งมา ไม่มีการครอปหรือปรับภาพไว้ล่วงหน้า

`start_demo` ยังใช้ได้สำหรับชุดสังเคราะห์ แต่ **run_challenge คือทางรันโปรเจกต์ตามโจทย์จริง**

## แก้คำเตือนว่าไม่พบโฟลเดอร์ src

หาก `inspect_image` แจ้ง `Name is nonexistent or not a directory: ...\MATLAB\src` แปลว่าโฟลเดอร์ `src` ที่ควรอยู่ข้างไฟล์ `inspect_image.m` ไม่มีอยู่ในตำแหน่งที่ MATLAB เรียกใช้ การเปลี่ยน Current Folder อย่างเดียวไม่แก้กรณีที่ MATLAB ยังเรียกสำเนาเก่าจาก path

1. แตก ZIP ทั้งโปรเจกต์ ไม่คัดลอกเฉพาะ `inspect_image.m` ไปไว้ใน `Documents\MATLAB`
2. เลือกโฟลเดอร์ `SceneTextTextureMATLAB` ที่มี `inspect_image.m`, `project_config.m` และโฟลเดอร์ `src` เป็น Current Folder
3. รันคำสั่งต่อไปนี้จากโฟลเดอร์นั้น:

```matlab
addpath(pwd, '-begin');
clear inspect_image
which inspect_image -all
isfolder(fullfile(pwd, 'src'))
inspect_image
```

`which` ควรแสดงไฟล์ในโฟลเดอร์โปรเจกต์เป็นรายการแรก และ `isfolder` ควรคืนค่า `1` จากนั้น `inspect_image` จะเปิดหน้าต่างให้เลือกรูป ถ้ามีสำเนาเก่าใน `Documents\MATLAB` ให้ใช้สำเนาในโฟลเดอร์โปรเจกต์เป็นหลัก

เวอร์ชันนี้ตรวจไฟล์เริ่มต้นที่จำเป็นก่อนเรียก `addpath` และแจ้งตำแหน่งที่คาดหวัง หากแตกไฟล์ไม่ครบ ยังต้องแตก ZIP ใหม่ให้ครบ การตรวจนี้ไม่ได้สร้างไฟล์ `src` ที่หายไปให้เอง

## ข้อกำหนดจากโจทย์

Challenge02.pdf หน้า 3 ระบุ:

- พัฒนา Preprocessing โดยใช้ Frequency Domain Transformation เป็นฐาน อย่างน้อย 50% ของปริมาณงานทั้งหมด
- สามารถใช้เทคนิคหัวข้ออื่นร่วมเพื่อเพิ่มประสิทธิภาพได้
- OCR ต้องแสดง Confidence ของทุก Text Bounding Box ที่ตรวจพบ และข้อความที่อ่านได้
- เอกสารชี้ไปยัง OCR Toolbox ของ MATLAB

เอกสารไม่ได้ระบุวิธีนับสัดส่วน 50% จึงไม่ใช้จำนวนบรรทัดโค้ดเป็นข้ออ้าง โครงงานนี้จัดให้ส่วนที่พัฒนาและทดลองหลักเป็นการออกแบบ/สร้าง/ประยุกต์/อธิบาย Frequency filters ใน F1/F2 โดยตรง ดู `docs/FREQUENCY_METHOD_TH.md` และแผนแบ่งงาน การตัดสินสัดส่วนงานจริงยังขึ้นกับผลงานและคำอธิบายที่ส่ง

## วิธีเปรียบเทียบ

| วิธี | Processing |
|---|---|
| M0 | ภาพต้นฉบับ ใช้เป็น baseline |
| F1 | Grayscale → symmetric padding → FFT2 → Gaussian Low-pass → IFFT2 → normalize |
| F2 | Grayscale → padding → log → FFT Homomorphic illumination correction → exp → FFT Gaussian Low-pass → FFT High-boost → normalize |

F2 มี Frequency filtering จริง 3 ขั้น ไม่ใช่เพียงเรียก FFT เพื่อแสดงภาพแล้วประมวลผลด้วย spatial filter ส่วน FFT แต่ละขั้นสร้าง H(u,v) คูณ Spectrum และ reconstruct ด้วย IFFT

Texture ในชุดภาพไม่ได้อยู่เฉพาะพื้นหลัง: มีลายตาข่าย ขน หญ้า และลายสีอยู่ภายในตัวอักษรด้วย Low-pass อาจลดลายแต่ทำให้ stroke เบลอ F2 จึงทดลองทั้งการจัดการแสงและ high-boost แบบอ่อน ผลดีขึ้นหรือแย่ลงต้องดูผล OCR จริง

ตัวเลือกเก่า M1/M2 และ detector mser ยังคงอยู่สำหรับ supplementary experiments แต่ไม่ได้เป็นรอบหลักที่ตอบข้อกำหนด Frequency Domain

## Dataset ที่ใช้จริง

| ไฟล์ | ลักษณะ |
|---|---|
| Image07.jpg | ป้าย THE WORDS DON'T FIT THE PICTURE มี texture ภายในตัวอักษร และคำเล็กด้านล่าง |
| Image22.jpg | COMING SOON ตัวอักษรบนป้ายเก่า มีเอียงและเส้นพาดผ่าน |
| TextureText02.jpg | PSD ลายตาข่ายและแสงบนตัวอักษร |
| TextureText03.jpg | EARTH ตัวอักษรหญ้า มีข้อความเล็กด้านล่างและขอบคำถูกตัด |
| TextureText04.jpg | FUR ตัวอักษรขน ขนาดภาพเล็กและแถบดำ |
| TextureText07.jpg | CANDY CANE ลายเฉียงและเงา |
| texture text.jpg | หลายคำ หลายขนาด หลายมุม และคำถูกตัดขอบ |

มี 2 ภาพกลุ่ม scene_sign, 4 ภาพ textured_glyph และ 1 ภาพ mixed_layout กลุ่มเหล่านี้เป็นป้ายอธิบายชุดภาพ ไม่ใช่ระดับความยากที่วัดด้วยสูตร ห้ามสรุปคะแนนของ 1 ภาพในกลุ่ม mixed_layout ว่าเป็นตัวแทนของทุกภาพประเภทนี้

ทั้ง 7 ภาพใช้ split=`provided` โดยไม่ได้แบ่ง test แบบอิสระ ชุดนี้จึงเป็น **case study / การทดลองตามชุดโจทย์** ถ้าปรับพารามิเตอร์โดยดูภาพเหล่านี้ ต้องไม่อ้างผลเป็นความแม่นยำบน held-out test

## ผลลัพธ์และ Confidence ทุก Box

ผลแต่ละรอบอยู่ใน `results/<รอบใหม่>/`:

| ไฟล์ | ความหมาย |
|---|---|
| ocr_results.csv | **ทุกกรอบที่ OCR คืนมา**: ImageID, Method, Detector, BoxIndex, x/y/width/height, text, confidence |
| image_results.csv | ข้อความรวม Confidence เฉลี่ย จำนวนกรอบ เวลา และคะแนนเมื่อ GT ผ่านการตรวจ |
| images/*/predicted_words.csv | ข้อความ/Confidence ทุกกรอบของภาพและวิธีนั้น |
| images/*/overlay.png | ตำแหน่งกับข้อความ/Confidence บนภาพต้นฉบับ |
| images/*/comparison.png | ภาพต้นฉบับ / ประมวลผล / ผล OCR |
| images/*/frequency_comparison.png | Spectrum ก่อนกรอง / H(u,v) / Spectrum หลังกรอง / reconstructed ของแต่ละขั้น FFT |
| images/*/stage_fft_*.png | ภาพ FFT diagnostics แยกไฟล์เพื่อใส่สไลด์ |
| summary.csv / chart_ocr.png | สรุปแต่ละวิธีและกลุ่มภาพ |
| word_results.csv | เทียบคำกับ GT เมื่อภาพนั้นผ่านการตรวจ annotations แล้ว |
| REPORT.md | รายงานสรุปจากการรันจริง |
| config.json / environment.json | พารามิเตอร์และเวอร์ชันที่ใช้ |
| manifest_used.csv / ground_truth_used.csv | ข้อมูลกำกับที่ใช้ในรอบนั้น |
| run.log | COMPLETE เมื่อจบรอบ; FAILED ถ้าหยุดและมีเพียง partial results |

ค่าเริ่มต้น `MinConfidence=0` ไม่ตัดคำ Confidence ต่ำออก และไม่มีการเลือกกรอบให้ตรงกับคำเฉลยก่อนทำนาย กรอบที่ OCR ไม่คืนมาไม่มีค่า Confidence จึงไม่มีการสร้างค่าแทน

หาก annotation ยังเป็น draft กราฟจะแสดง Confidence และจำนวนกรอบ ซึ่ง **ไม่ใช่ Accuracy** ส่วน Recognition Rate / CER / WER / F1 จะเป็น NaN ยังไม่คำนวณ ค่า NaN ไม่ได้แปลว่าคะแนน 0

## Ground Truth — ต้องตรวจให้ครบก่อนใช้ Accuracy

แนบ seed annotations ฉบับร่าง 19 คำเพื่อช่วยเริ่มงาน แต่ไม่ได้อ้างว่าครบทุกคำหรือกรอบถูกต้อง โดยเฉพาะคำเล็กและคำเอียง บันทึก `annotation_status=draft` ทั้ง 7 ภาพไว้เพื่อไม่รายงานคะแนนจากข้อมูลกำกับที่ยังไม่ครบ

```matlab
review_annotations
outDir = run_challenge;
```

ตัวช่วยให้แก้ข้อความและลากกรอบของคำเดิม จากนั้นเพิ่มทุกคำที่ขาด แล้วกดยืนยัน Reviewed เมื่อครบจริง การอ่านข้อความจริงต้องทำด้วยคน ไม่ใช้ผล OCR ของวิธีใดเป็น Ground Truth

สำหรับภาพ collage ที่มีหลายมุม ให้ตกลงลำดับอ่านและแก้ `word_index` ใน CSV ให้ชัด เพราะตัวช่วยใช้ลำดับแนวนอนเป็นค่าเริ่มต้น CER/WER อาจสูงเพราะลำดับผิดแม้บางคำอ่านถูก ส่วน word-level matching ใช้กรอบและไม่ขึ้นกับลำดับ

อย่ากด Reviewed หากยังติดป้ายเพียงข้อความหลักแล้วละคำเล็กที่อ่านได้ โปรแกรมยังไม่มี ignore-region protocol สำหรับคำที่ไม่นับ ดังนั้นเพื่อประเมินเต็มภาพ ให้ติดป้ายทุกคำที่อยู่ในเกณฑ์เดียวกัน หากมีคำขาดขอบ/อ่านไม่ได้ที่ไม่สามารถกำหนด reference อย่างเป็นธรรม ให้คง draft และรายงานเฉพาะข้อความ/Confidence หรือพัฒนา ignore-region evaluator ก่อนรายงาน full-image accuracy

กรอบเป็น axis-aligned word boxes จึงมีข้อจำกัดกับข้อความเอียงและตัวอักษรที่พาดทับกัน เอกสารโจทย์ไม่ได้บังคับ IoU evaluator นี้ คะแนน Detection เป็นการประเมินเพิ่มเติมของโปรเจกต์ อ่านนิยามใน `docs/METRICS.md`

## ลองภาพเดียว/ปรับค่า

```matlab
inspect_image('data/provided/images/TextureText02.jpg','F1','ocr')
inspect_image('data/provided/images/TextureText07.jpg','F2','ocr')

cfg = project_config('provided');
cfg.GaussianCutoff = 0.08;    % เปรียบเทียบกับค่าหลัก 0.065
cfg.SaveFigures = true;
outDir = run_experiment(cfg);
```

Frequency cutoffs เป็น cycles/pixel ค่า cutoff ต่ำลดรายละเอียดมากขึ้น แต่เสี่ยงทำลายตัวอักษร ไม่มีการเลือกพารามิเตอร์อัตโนมัติจากข้อความเฉลย ค่าเดียวกันใช้กับทุกภาพในรอบ

ทดลอง cutoff แบบเป็นระบบได้:

```matlab
run_frequency_sweep([0.035 0.05 0.065 0.09]);
```

รอบนี้รัน F1/F2 กับทั้ง 7 ภาพที่ cutoff แต่ละค่า รวม 56 ชุดผล บันทึก sweep_summary.csv และ path ของแต่ละรอบ เปรียบเทียบ spectrum/ภาพ/ข้อความให้เห็นผลของ cutoff หากใช้ผลชุดเดียวกันเลือกค่าที่ชอบ ต้องรายงานว่าเป็นการศึกษา parameter บนชุดโจทย์ ไม่ใช่ held-out tuning

ตัวอย่างพารามิเตอร์สำคัญ:

- GaussianCutoff: ลด Texture ความถี่สูง
- HomomorphicCutoff / LowGain / HighGain: แยกองค์ประกอบแสงช้าออกจากรายละเอียดใน log domain
- HighBoostCutoff / Amount: เพิ่มรายละเอียดแบบอ่อนหลัง smooth
- FFTPadFraction: symmetric padding เพื่อลดการเชื่อมขอบแบบ circular FFT

โค้ดนี้ไม่มี perspective rectification หรือ recognizer สำหรับข้อความโค้ง/หลายมุมโดยเฉพาะ จึงอาจอ่าน collage และป้ายเอียงได้ไม่ครบ การจัดการ Texture ด้วย FFT ไม่ได้แก้ปัญหาการวางตัวอักษรทั้งหมด

## การตรวจสอบ

เครื่องที่สร้างโปรเจกต์ไม่มี MATLAB จึงยังไม่มีผล OCR จริงที่อ้างว่ารันผ่าน มี MATLAB unit tests สำหรับ metrics/FFT และตรวจ syntax/data รวมถึงสูตร FFT ด้วย Python ดู `docs/VALIDATION.md`

คู่มือเพิ่มเติม: `docs/FREQUENCY_METHOD_TH.md`, `docs/EXPERIMENT_PLAN_TH.md`, `docs/METRICS.md`, `docs/REFERENCES.md` และสำเนาโจทย์ `docs/Challenge02.pdf`
