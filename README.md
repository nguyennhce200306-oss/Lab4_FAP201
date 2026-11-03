# Lab4_FAP201 - Switch Debouncing & Edge Detection

## Thông tin chung
* **Môn học:** FAP201 - FPGA Programming
* **Bài thực hành:** Lab04 - Debouncing a Switch
* **Mục tiêu:** Thiết kế, kiểm chứng và hiện thực mạch chống rung phím (Debouncing) kết hợp đồng bộ hóa tín hiệu 2 tầng (2-stage Synchronizer) và bắt cạnh nhả nút (Release Event) để điều khiển lật trạng thái (Toggle) đèn LED ổn định trên bo mạch FPGA[cite: 24, 26].

## Môi trường và Phần cứng
* **Công cụ phát triển:** Gowin EDA[cite: 24]
* **Bo mạch (Board):** Xiaomeige ACG525[cite: 24]
* **Chip FPGA (Target Device):** GW5A-LV25UG324C2/I1[cite: 24]
* **Xung nhịp hệ thống (Clock):** 50 MHz (Chu kỳ 20 ns)[cite: 25]
* **Thời gian chống rung (Debounce Time):** $1.000.000$ chu kỳ clock = $20\text{ ms}$ (ở tần số $50\text{ MHz}$)[cite: 26]
* **Ngôn ngữ:** VHDL (IEEE 1164 STD_LOGIC & NUMERIC_STD)[cite: 26]

## Nguyên lý hoạt động & Kiến trúc Thiết kế

### 1. Đồng bộ hóa 2 tầng (2-Stage Synchronizer)
Tín hiệu từ nút nhấn vật lý (`i_sw_raw`) là tín hiệu bất đồng bộ. Khi đưa trực tiếp vào clock domain $50\text{ MHz}$, nó có thể gây ra hiện tượng bất ổn định trạng thái (Metastability)[cite: 26]. 
Mạch sử dụng 2 Flip-Flop nối tiếp (`sw_sync1`, `sw_sync2`) để đồng bộ hóa tín hiệu ngõ vào vào miền xung nhịp `clk`[cite: 26]. Tín hiệu ngõ vào cũng được đảo qua toán tử `not` để quy về logic tích cực mức cao (`'1'` = Đang nhấn nút)[cite: 26].

### 2. Mạch đếm chống rung (Debounce Counter)
* Hàm `clog2` tự động tính toán số bit cần thiết cho bộ đếm: $20\text{ bits}$ cho $1.000.000$ chu kỳ[cite: 26].
* Nếu tín hiệu `sw_sync2` khác với trạng thái ổn định hiện tại (`sw_stable`), bộ đếm `stable_count` bắt đầu tăng dần[cite: 26].
* Nếu tín hiệu duy trì ổn định đủ $1.000.000$ chu kỳ clock ($20\text{ ms}$), trạng thái mới sẽ được cập nhật vào `sw_stable`[cite: 26].
* Nếu tín hiệu bị nhiễu/bật nẩy (bounce) trước khi đếm xong, bộ đếm bị reset về `0` để đếm lại từ đầu[cite: 26].

### 3. Mạch phát hiện cạnh nhả nút (Release Event Detector)
* `evt_cur` và `evt_prev` lưu trạng thái hiện tại và chu kỳ trước đó của tín hiệu đã khử rung `sw_stable`[cite: 26].
* Biểu thức `release_event <= evt_prev and (not evt_cur);` phát hiện chính xác thời điểm tín hiệu chuyển từ `'1'` (Đang nhấn) về `'0'` (Đã nhả nút)[cite: 26].

### 4. Lật trạng thái LED & Reset hệ thống
* Khi `release_event = '1'`, thanh ghi `led_state` lật trạng thái (`led_state <= not led_state`)[cite: 26].
* Tín hiệu reset ngõ vào `i_rst` hoạt động theo cơ chế **Active-Low** (`i_rst = '0'`)[cite: 26].

---

## Cấu hình Chân & Ràng buộc Thời gian (Constraints & Timing)

### 1. Ánh xạ chân vật lý (`lab04.cst`)
Tín hiệu được cấu hình chi tiết trong file `lab04.cst`[cite: 24]:

| Tín hiệu VHDL | Chân FPGA | Linh kiện phần cứng | Mô tả |
| :--- | :---: | :--- | :--- |
| `clk` | `T9` | System Clock (50 MHz) | Xung nhịp hệ thống[cite: 24] |
| `i_sw_raw` | `B16` | Key / Switch ngõ vào | Nút nhấn cần khử rung[cite: 24] |
| `i_rst` | `C15` | Reset Key | Nút Reset hệ thống (Active-Low)[cite: 24] |
| `o_led` | `D14` | LED Output chính | Hiển thị trạng thái lật (Toggle)[cite: 24] |
| `o_dbg_stable` | `C14` | Debug LED | Hiển thị trực tiếp tín hiệu đã khử rung `sw_stable`[cite: 24, 26] |

### 2. Ràng buộc thời gian (`lab04.sdc`)
File `lab04.sdc` định nghĩa xung nhịp đầu vào $50\text{ MHz}$ (Chu kỳ $20\text{ ns}$)[cite: 25]:
```tcl
create_clock -name clk -period 20 -waveform {0 10} [get_ports {clk}]
```[cite: 25]

---

## Cấu trúc thư mục dự án (Project Structure)
* `src/lab04.vhd`: Mã nguồn VHDL tích hợp Synchronizer, Debouncer, Release Detector và LED Toggle[cite: 26].
* `constraints/lab04.cst`: File gán chân vật lý Gowin FPGA[cite: 24].
* `constraints/lab04.sdc`: File cấu hình định thì STA cho xung nhịp 50 MHz[cite: 25].
* `sim/lab04_tb.vhd`: Testbench tạo xung clock và giả lập tín hiệu nhiễu phím (Bounce) để kiểm thử bộ đếm.
* `waveform/`: Ảnh chụp sóng mô phỏng thể hiện các giai đoạn `sw_sync`, `stable_count`, `sw_stable` và `release_event`.
* `reports/`: Báo cáo Tổng hợp (Synthesis), P&R và phân tích định thì Static Timing Analysis.
* `evidence/`: Nhật ký Programmer và bằng chứng nghiệm thu thực tế trên bo mạch.
* `README.md`: Document tài liệu dự án.

---

## Hướng dẫn Build & Kiểm chứng (Execution & Verification)

1. **Mô phỏng (Simulation):**
   * Trong Testbench, có thể giảm bớt giá trị `STABLE_CYCLES` (ví dụ từ `1_000_000` xuống `10` hoặc `100`) để rút ngắn thời gian mô phỏng.
   * Giả lập nhiễu tín hiệu `i_sw_raw` chuyển trạng thái liên tục trong khoảng thời gian ngắn và xác nhận `sw_stable` không bị ảnh hưởng bởi nhiễu.
   * Xác nhận `o_led` chỉ đảo trạng thái đúng một lần khi nút nhấn được nhả ra (`release_event = '1'`)[cite: 26].

2. **Tổng hợp & Phân tích định thì (Synthesis & STA):**
   * Mở project trên Gowin EDA, nạp file `lab04.vhd`, `lab04.cst` và `lab04.sdc`[cite: 24, 25, 26].
   * Thực hiện **Synthesis** và **Place & Route**. 
   * Mở báo cáo Timing Analysis để đảm bảo bộ đếm $20\text{ bits}$ đạt yêu cầu tần số $50\text{ MHz}$ không bị vi phạm Setup/Hold Time[cite: 25, 26].

3. **Nạp phần cứng (Hardware Programming):**
   * Kết nối bo mạch Xiaomeige ACG525 và dùng Gowin Programmer nạp file bitstream (`.fs`)[cite: 24].
   * Nhấn nút `C15` để Reset hệ thống[cite: 24, 26].
   * Nhấn nút `B16`: Quan sát `o_dbg_stable` (LED `C14`) sáng khi nhấn/khử rung xong, và `o_led` (LED `D14`) sẽ đảo trạng thái mỗi khi nhả nút[cite: 24, 26].
