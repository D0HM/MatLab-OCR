# Frequency Domain เป็นแกนของงาน

## เหตุผลที่เวอร์ชันเดิมต้องเปลี่ยน

Scope เดิมเน้น CLAHE/Morphology เป็นหลัก แต่ Challenge02.pdf หน้า 3 กำหนดให้ใช้ Frequency Domain Transformation เป็นฐานอย่างน้อย 50% ของปริมาณงานทั้งหมด จึงเปลี่ยนรอบหลักเป็น M0/F1/F2 และคง spatial methods ไว้เฉพาะส่วนเสริม

ภาพ Texture Text มีลวดลายใน stroke ของตัวอักษร ไม่ใช่เฉพาะพื้นหลัง การทำให้รายละเอียดความถี่สูงลดลงอาจช่วยให้ OCR เห็นรูปทรงรวม แต่ถ้ากรองมากเกินไปก็เสียเส้นตัวอักษร จึงต้องทดลองเปรียบเทียบและอธิบาย tradeoff

## Frequency grid และ DFT

ใช้ภาพ grayscale และ symmetric padding แล้วคำนวณ:

F = fftshift(fft2(A))
G = H .* F
B = real(ifft2(ifftshift(G)))

แกนความถี่ u/v คิดเป็น cycles/pixel ไม่ใช้ระยะพิกเซลของ Spectrum ตรง ๆ ทำให้ค่า cutoff สื่อความหมายสม่ำเสมอกว่าเมื่อขนาดภาพต่างกัน ต้องใช้ ifftshift กลับให้ตรงก่อน IFFT; โค้ดตรวจ imaginary residual ด้วย

D² = u² + v²

## F1: Gaussian Low-pass

H_LP = exp(-D² / (2*sigma_LP²))

ใช้ลดรายละเอียดความถี่สูงของตาข่าย ขน หญ้า และลายเฉียง รักษา DC ไว้ที่ 1 ค่าเริ่มต้น sigma_LP = 0.065 cycles/pixel ผลยังขึ้นกับขนาด stroke จริง: ภาพเล็กอาจสูญเสียรูปทรงตัวอักษรง่ายกว่าภาพใหญ่

## F2: Frequency pipeline 3 ขั้น

### 1. Homomorphic illumination correction

สมมติความเข้มเป็นองค์ประกอบแสง × รายละเอียด จึงใช้ log(max(I,1/255)) และกรองใน Frequency domain:

H_HOMO = gamma_L + (gamma_H-gamma_L) * (1-exp(-D²/(2*sigma_H²)))

ค่าเริ่มต้น gamma_L=0.6, gamma_H=1.2, sigma_H=0.025 ลดองค์ประกอบความถี่ต่ำใน log domain และให้น้ำหนักรายละเอียดสูงกว่า ก่อนย้อนกลับด้วย exp ฟิลเตอร์นี้อาจขยาย Texture ด้วย จึงตามด้วย Low-pass

### 2. Gaussian texture suppression

คำนวณ FFT ใหม่ของผล illumination correction และใช้ H_LP ตาม F1 ขั้นนี้กรองภาพความเข้มหลังกลับจาก log domain ไม่ใช่คูณ H ซ้ำโดยสมมติว่า exp เป็น linear

### 3. Mild frequency high-boost

H_HB = 1 + amount * (1-exp(-D²/(2*sigma_B²)))

ค่าเริ่มต้น amount=0.3, sigma_B=0.04 ชดเชยรายละเอียดบางส่วนหลัง smooth ไม่สามารถสร้าง stroke ที่หายไปกลับมาอย่างสมบูรณ์ และอาจเพิ่ม Texture ที่เหลืออีก จึงต้องดูผล OCR เทียบ F1

ท้ายสุดตัด padding กลับขนาดภาพเดิมและ normalize ช่วงความเข้ม ทำให้พิกัด OCR เปรียบเทียบกับภาพต้นฉบับได้โดยไม่ scale bounding boxes

## หลักฐานที่ควรนำเสนอ

- transfer function ของ Gaussian/Homomorphic/High-boost พร้อมสูตรและ cutoff
- log magnitude spectrum ก่อน/หลังคูณ filter
- reconstructed images ก่อน OCR
- เปรียบเทียบ M0/F1/F2 และคำ/Confidence ทุกกรอบ
- ผลเปลี่ยน cutoff และกรณีที่ stroke เบลอ/Texture ยังอยู่

## การจัดสัดส่วนงานตามโจทย์

ข้อกำหนด 50% เป็นปริมาณงานทั้งหมด ไม่ใช่เพียงจำนวนขั้นหรือจำนวนบรรทัด ทีมควรใช้เวลาและเนื้อหาหลักกับ Frequency core:

1. อธิบาย FFT/IFFT และ frequency grid
2. ออกแบบ Gaussian filter และตรวจ cutoff
3. พัฒนา Homomorphic log/exp pipeline
4. พัฒนา high-boost และตรวจผลต่อ stroke
5. วิเคราะห์ spectrum / transfer / inverse reconstruction / ขอบภาพ
6. เปรียบเทียบผล Frequency methods บนชุดโจทย์

Spatial conversion/normalization, OCR สำเร็จรูป, CSV/กราฟ และ Ground Truth เป็นส่วนสนับสนุน ไม่ควรทำสไลด์เกือบทั้งหมดเกี่ยวกับ OCR แล้วแสดง FFT เพียงภาพเดียว การยืนยันว่าปริมาณงานถึงเกณฑ์ต้องอาศัยงานที่ทำและคำอธิบายจริงของทีม เอกสารโจทย์ไม่ได้กำหนดตัวนับอัตโนมัติ

ข้อจำกัด: spatial texture และรูปทรงตัวอักษรอาจมีความถี่ทับกัน Gaussian filtering จึงไม่แยกสองส่วนได้สมบูรณ์ โค้ดนี้ไม่ได้ตรวจ spectral peaks เพื่อทำ notch filter อัตโนมัติ และไม่ได้เพิ่มฟิลเตอร์ที่ไม่มีบทบาทเพียงเพื่อให้นับขั้นได้มาก
