# แผนทดลองตาม Challenge02

## สิ่งที่ต้องทำและส่ง

ใช้ชุดภาพที่ผู้ใช้ส่งมา 7 ภาพ ทำ Preprocessing ด้วย Frequency Domain เป็นแกน แล้วใช้ MATLAB OCR แสดงข้อความ/Confidence ทุกกรอบ เปรียบเทียบภาพเดิม M0 กับ F1 และ F2

โจทย์ Challenge02 หน้า 3 ไม่ได้บังคับว่าต้องถ่ายภาพเพิ่ม 30 ภาพ จึงใช้ทั้ง 7 ภาพเป็นงานหลัก ไม่สมมติการแบ่ง simple/moderate/complex แบบเดิม และไม่เรียกชุดนี้ว่า held-out test

## ลำดับการทำงาน

1. รัน run_tests และ run_challenge บน MATLAB จริง
2. ดู ocr_results.csv ของทุกภาพ/ทุกวิธี ไม่เลือกเฉพาะกรอบ Confidence สูง
3. แสดง frequency_comparison ของภาพที่มีลายชัด เช่น PSD / FUR / CANDY CANE
4. เปรียบเทียบ M0 กับ F1/F2 ว่า Texture ลดหรือ stroke เสียหายตรงไหน
5. เปลี่ยน cutoff ทีละค่าโดยใช้ทั้งชุดในรอบเดียว บันทึก config ของแต่ละรอบ
6. หากต้องวัด Accuracy ให้ตรวจ Ground Truth ครบก่อน; หากไม่ครบให้รายงานคำ/Confidence พร้อมภาพและข้อจำกัด
7. สรุปผลเป็น case study บน 7 ภาพ การใช้ภาพเดียวกันเลือกค่าและวัดผลต้องระบุในรายงาน

## ตารางหลัก

| Image | Method | Box | Confidence | Recognized text |
|---|---|---|---|---|
| ดึงจาก ocr_results.csv | | | | |

เพิ่ม Recognition Rate / CER / WER / Detection P/R/F1 ได้เมื่อ annotations ของภาพนั้น reviewed จริง อ่านสูตรใน METRICS.md ไม่ใช้ Confidence แทน Accuracy

## โครงสไลด์ที่เสนอ

1. ชื่อ Challenge และข้อกำหนด Frequency Domain ≥50% ของงาน
2. Dataset จริง 7 ภาพ: texture ภายในตัวอักษร/ขอบเอียง/หลายมุม
3. FFT2 / shifted spectrum / IFFT2 และ frequency grid
4. Gaussian Low-pass: สูตร transfer และผล cutoff
5. Homomorphic log/exp: เหตุผลและการจัดการแสง
6. Frequency high-boost และ tradeoff เรื่อง Texture/ความคมชัด
7. Spectrum → H(u,v) → filtered spectrum → reconstructed
8. ภาพ Original / F1 / F2 และ OCR ทุกกรอบ
9. ตาราง Confidence/ข้อความ; เพิ่ม metrics เฉพาะ GT reviewed
10. วิเคราะห์คำอ่านถูก/ผิด กรณี F1/F2 แย่ลง และข้อจำกัด

เกณฑ์คะแนนเดิม 60 คะแนนยังใช้เตรียมงานได้: ความพร้อม 5, ลำดับ 10, การนำเสนอ 10, ผลทดลอง 15, วิเคราะห์ 10, MATLAB code/comments 10 โดยให้สมาชิกแต่ละคนอธิบายส่วนที่ทำและวิเคราะห์ได้ เนื้อหาส่วนหลักต้องเป็น Frequency methods ตามโจทย์ใหม่

## สิ่งที่ไม่ควรสรุปเกินข้อมูล

- Confidence สูงไม่ได้พิสูจน์ว่า text ถูกหรือไม่มีคำตกหล่น
- จำนวน boxes เพิ่มอาจเป็น false positives
- ผลบน 7 ภาพไม่ได้พิสูจน์ความแม่นยำในภาพทั่วไป
- Filtering ที่ลด Texture อาจทำลาย stroke หรือขอบพิมพ์เล็ก
- Frequency filters ไม่ได้แก้ perspective/rotated-text ทั้งหมด
- อธิบายส่วน OCR สำเร็จรูปและส่วน Preprocessing ที่พัฒนาเองให้ชัด
