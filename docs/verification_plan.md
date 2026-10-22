# Verification Plan — APB Slave

| | |
|---|---|
| DUT | `async_apb_slave` (`rtl/async_apb_slave.sv`), APB3 slave 32-bit, 4 thanh ghi |
| Phương pháp | UVM 1.1d: constrained-random + directed, scoreboard với reference model, functional coverage |
| Công cụ | QuestaSim 10.7c (Windows), script Python `script/run_sim.py` |
| Cập nhật | 2026-10-22 |
| Tài liệu liên quan | [corner_cases.md](corner_cases.md), [README](../README.md) |

Tài liệu này ghi lại **kế hoạch** và **trạng thái thực tế** của testbench. Mục nào chưa làm được ghi rõ là chưa làm (mục 10 và 11).

---

## 1. Mục tiêu và phạm vi

**Mục tiêu:** chứng minh DUT hoạt động đúng theo đặc tả ở mục 2 trên các giao dịch APB hợp lệ và các giao dịch lỗi.

**Trong phạm vi**
- Truy cập đọc/ghi 4 thanh ghi qua giao thức APB 2 pha.
- Chế độ đảo bit của `data_out`.
- Báo lỗi `pslverr` khi ghi vào thanh ghi chỉ đọc hoặc truy cập ngoài vùng.
- Reset bất đồng bộ (kế hoạch, chưa kiểm tra bằng test — xem mục 11).

**Ngoài phạm vi**
- Wait state (`pready` luôn bằng 1).
- APB4 (`PSTRB`, `PPROT`) — DUT là APB3.
- Mô hình thanh ghi UVM (RAL), kiểm tra công suất, timing.

---

## 2. Đặc tả DUT tóm tắt

| Địa chỉ | Tên | Truy cập | Reset | Mô tả |
|---|---|---|---|---|
| 0x00 | `sys_ctrl` | RW | 0x0000_0000 | 32 bit lưu được; chỉ bit 0 có tác dụng: điều khiển chế độ đảo |
| 0x04 | `sys_status` | RO | — | Hằng số 0xCAFE_BABE |
| 0x08 | `data_in` | RW | 0x0000_0000 | Dữ liệu 32 bit |
| 0x0C | `data_out` | RO | — | `sys_ctrl[0] ? ~data_in : data_in` (tổ hợp) |

**Quy tắc chính**
- `pready = 1` cố định: mọi giao dịch kéo dài đúng 2 chu kỳ (setup, access).
- Giao dịch xảy ra khi `psel && penable && pready`; ghi được chốt ở cạnh clock cuối của pha access.
- Ghi vào 0x04, 0x0C hoặc địa chỉ không phải 0x00/0x04/0x08/0x0C: `pslverr = 1`, không thanh ghi nào đổi.
- Đọc địa chỉ không hợp lệ: `prdata = 0`, `pslverr = 1`.
- `prdata` và `pslverr` bằng 0 ngoài pha access.
- Reset bất đồng bộ, tích cực mức thấp (`presetn`): xóa `sys_ctrl` và `data_in`.
- Chỉ decode `paddr[7:0]`: địa chỉ có bit cao khác 0 trùng (alias) với địa chỉ có 8 bit thấp tương ứng; địa chỉ không căn 4 byte (ví dụ 0x01, 0x09) coi như ngoài vùng.

---

## 3. Kiến trúc testbench

```
┌──────────────────────────────── apb_test ────────────────────────────────┐
│  apb_sequence (4 mode)  ── start trên sequencer                          │
│        │ item                                                            │
│  ┌─────▼──────────────────────── apb_env ────────────────────────────┐   │
│  │  ┌─────────────────────── apb_agent ───────────────────────┐      │   │
│  │  │  uvm_sequencer ──item──▶ apb_driver ──▶ [apb_if] ◀──▶ DUT      │   │
│  │  │                                            │             │      │   │
│  │  │                                       apb_monitor        │      │   │
│  │  └────────────────────────────────────────────┬─────────────┘      │   │
│  │                                               │ item               │   │
│  │                                ┌──────────────┴───────────┐        │   │
│  │                                ▼                          ▼        │   │
│  │                         apb_scoreboard             apb_coverage    │   │
│  └───────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────┘
```

| Thành phần | File | Vai trò |
|---|---|---|
| Interface | `tb/apb_if.sv` | Các tín hiệu APB, clocking block `cb_driver`/`cb_monitor`, modport `driver_mp`/`monitor_mp` |
| Transaction | `tb/apb_transaction.sv` | Một giao dịch: `paddr`, `pwdata`, `pwrite` (random); `prdata`, `pslverr` (quan sát). Chứa constraint địa chỉ |
| Sequence | `tb/apb_sequence.sv` | Một class, chọn kịch bản bằng biến `mode` (kiểu `test_mode`) |
| Driver | `tb/apb_driver.sv` | Đóng vai APB master: pha setup, pha access, trả bus về idle |
| Monitor | `tb/apb_monitor.sv` | Đọc bus, tạo transaction khi `psel && penable && pready`, gửi qua analysis port |
| Scoreboard | `tb/apb_scoreboard.sv` | Reference model và so sánh |
| Coverage | `tb/apb_coverage.sv` | Covergroup `apb_cg`, in kết quả ở `report_phase` |
| Agent / Env / Test | `tb/apb_agent.sv`, `apb_env.sv`, `apb_test.sv` | Ghép thành phần; test chạy lần lượt 4 stage |
| Package / Top | `tb/apb_pkg.sv`, `tb/apb_tb_top.sv` | Include các class; tạo clock, reset, nối DUT, đưa `vif` vào `config_db` |

**Luồng dữ liệu:** sequence → sequencer → driver → DUT là luồng lái; DUT → monitor → scoreboard và coverage là luồng quan sát. Scoreboard chỉ dùng dữ liệu từ monitor (không dùng dữ liệu từ driver), để kiểm tra đúng những gì xuất hiện thật trên bus.

---

## 4. Danh sách tính năng cần kiểm tra

| ID | Tính năng | Cách kiểm tra | Corner case | Trạng thái |
|---|---|---|---|---|
| F-01 | Giao thức 2 pha, giao dịch hoàn tất đúng | Mọi giao dịch qua monitor và scoreboard; waveform | CC-25 | ✅ |
| F-02 | `sys_ctrl` đọc/ghi 32 bit | Ghi rồi đọc lại, scoreboard so sánh | CC-05, 07 | 🟡 (giá trị biên chưa có) |
| F-03 | `sys_status` hằng 0xCAFE_BABE | Đọc 0x04 | CC-02 | ✅ |
| F-04 | `data_in` đọc/ghi 32 bit | Ghi rồi đọc lại | CC-06, 08 | ✅ |
| F-05 | `data_out` đảo theo `sys_ctrl[0]` | Ghi `sys_ctrl[0]=1`, đọc 0x0C | CC-09, 10, 11 | ✅ bật đảo; 🟡 tắt đảo và đổi động |
| F-06 | Ghi vào thanh ghi RO báo lỗi | Ghi 0x04, 0x0C, kiểm tra `pslverr` | CC-12, 13, 14 | 🟡 (chỉ random) |
| F-07 | Truy cập ngoài vùng báo lỗi, `prdata = 0` | Đọc/ghi 0x14, 0x20 và random | CC-15, 16, 17, 18 | ✅ |
| F-08 | Decode `paddr[7:0]`: alias và không căn 4 byte | Chưa tạo được địa chỉ này | CC-19, 20 | ❌ |
| F-09 | Reset bất đồng bộ | Chưa có test | CC-01, 03, 04 | ❌ |
| F-10 | `pready = 1`, không wait state | Driver và monitor dùng `pready`; không có kịch bản riêng | CC-23 | ⚪ |
| F-11 | `prdata`, `pslverr` bằng 0 ngoài pha access | Chưa có assertion | CC-22 | ❌ |

Trạng thái chi tiết từng tình huống: [corner_cases.md](corner_cases.md) (25 tình huống: 7 đã phủ, 8 chỉ nhờ random, 9 chưa phủ, 1 không áp dụng).

---

## 5. Kế hoạch test

`apb_test` chạy lần lượt 4 stage; mỗi stage tạo một `apb_sequence` và gán `mode`:

| Stage | Mode | Giao dịch | Mục đích | Kết quả mong đợi |
|---|---|---|---|---|
| 1 | `TEST_CONFIG_ACTIVE` | 2 ghi | Ghi `sys_ctrl` (ép bit 0 = 1, các bit khác random) và `data_in` (random) | `pslverr = 0` |
| 2 | `TEST_READ_ALL` | 4 đọc | Đọc 0x00, 0x04, 0x08, 0x0C | Đúng giá trị đã ghi; 0x04 = 0xCAFE_BABE; 0x0C = `~data_in` |
| 3 | `TEST_ERROR_HANDLING` | 1 ghi, 1 đọc | Ghi 0x14, đọc 0x20 (ngoài vùng) | `pslverr = 1`; đọc: `prdata = 0` |
| 4 | `TEST_RANDOM_STRESS` | 100 (random) | Địa chỉ và dữ liệu random theo constraint | Scoreboard không báo FAIL |

Tổng: 108 giao dịch. Stage 1 và 2 phải chạy trước nhau vì stage 2 kiểm tra kết quả stage 1.

---

## 6. Chiến lược stimulus

**Directed (stage 1–3):** dùng `randomize() with {...}` để ép địa chỉ và chiều đọc/ghi, dữ liệu vẫn random.

**Constrained random (stage 4):** `apb_transaction` có hai constraint:

| Constraint | Nội dung | Tác dụng |
|---|---|---|
| `addr_c` | `paddr[1:0] == 0` | Chỉ sinh địa chỉ căn 4 byte |
| `c_corner_cases` | `paddr dist {0x00 := 3, 0x04 := 1, 0x08 := 3, 0x0C := 1, [0x10:0xFF] :/ 2}` | Thiên về thanh ghi RW; khoảng 20% là ngoài vùng |

Tỉ lệ xấp xỉ theo trọng số: 0x00 30%, 0x04 10%, 0x08 30%, 0x0C 10%, ngoài vùng 20%. Tỉ lệ thực tế có thể lệch nhẹ vì `addr_c` loại các địa chỉ không căn 4 byte khỏi dải 0x10–0xFF. `pwrite` và `pwdata` không bị ràng buộc (đọc/ghi khoảng 50/50).

**Hệ quả của constraint hiện tại:** không bao giờ sinh địa chỉ không căn 4 byte hoặc alias; `pwdata` hầu như không bao giờ bằng 0 hoặc 0xFFFF_FFFF (xem CC-07, 19, 20).

---

## 7. Chiến lược kiểm tra

Scoreboard giữ model gồm `exp_sys_ctrl`, `exp_data_in` (khởi tạo 0), cập nhật theo từng giao dịch monitor gửi tới:

| Giao dịch | Cập nhật model | Kiểm tra |
|---|---|---|
| Ghi 0x00 | `exp_sys_ctrl = pwdata` | `pslverr == 0` |
| Ghi 0x08 | `exp_data_in = pwdata` | `pslverr == 0` |
| Ghi địa chỉ khác | không đổi | `pslverr == 1` |
| Đọc 0x00 | — | `prdata == exp_sys_ctrl`, `pslverr == 0` |
| Đọc 0x04 | — | `prdata == 0xCAFE_BABE`, `pslverr == 0` |
| Đọc 0x08 | — | `prdata == exp_data_in`, `pslverr == 0` |
| Đọc 0x0C | — | `prdata == (exp_sys_ctrl[0] ? ~exp_data_in : exp_data_in)`, `pslverr == 0` |
| Đọc địa chỉ khác | — | `prdata == 0`, `pslverr == 1` |

Model viết theo đặc tả ở mục 2, tách biệt với code RTL. Sai lệch báo `uvm_error` với ID `SCB_FAIL`.

---

## 8. Kế hoạch coverage

**Functional coverage hiện có** (`apb_cg`, lấy mẫu mỗi giao dịch từ monitor):

| Thành phần | Nội dung |
|---|---|
| `cp_addr` | 5 bin: `sys_ctrl` (0x00), `sys_status` (0x04), `data_in` (0x08), `data_out` (0x0C), `unmapped` (0x10–0xFF) |
| `cp_write` | `read`, `write` |
| `cp_err` | `no_error`, `error` |
| `cross_addr_write` | `cp_addr` × `cp_write` (10 ô) |

Kết quả in ở `report_phase` với ID `COV_REPORT`.

**Mục tiêu:** 100% các bin trên.

**Chưa có:**
- Bin cho địa chỉ không căn 4 byte và alias.
- Cross `cp_err` với `cp_addr`/`cp_write` (để chặn tổ hợp mà spec cấm, ví dụ ghi vào 0x00 mà báo lỗi).
- Coverage cho chế độ đảo (`sys_ctrl[0]` tại thời điểm đọc 0x0C).
- Coverage cho khoảng nghỉ giữa giao dịch.
- Code coverage (line, branch, condition) chưa đo.

---

## 9. Kết quả hiện tại

Lần chạy trên QuestaSim 10.7c, UVM-1.1d (xem [log.png](log.png), [waveform.png](waveform.png)):

| Hạng mục | Kết quả |
|---|---|
| Biên dịch | 0 lỗi, 0 cảnh báo |
| Thời gian mô phỏng | 3335 ns |
| Số giao dịch | 108 (2 + 4 + 2 + 100) |
| Scoreboard | `PASS = 57`, `FAIL = 0` (57 là số lệnh **đọc**; 51 lệnh ghi vẫn được kiểm tra `pslverr` nhưng không được đếm) |
| UVM_ERROR / UVM_FATAL / UVM_WARNING | 0 / 0 / 0 |
| Functional coverage | Chưa ghi lại số liệu; xem dòng `COV_REPORT` trong log mỗi lần chạy |

Bằng chứng chức năng chính trong log:
- `sys_ctrl = 0x1e102a97` (bit 0 = 1, đảo bật); `data_in = 0x3db0b7ea`; đọc 0x0C ra `0xc24f4815 = ~0x3db0b7ea`.
- Đọc 0x04 ra `0xcafebabe`.
- Đọc 0x20 ra `Data=0x0 | Err=1`.
- Xung `pslverr` trong waveform khớp lệnh ghi 0x14 và đọc 0x20.

---

## 10. Tiêu chí hoàn thành

| Tiêu chí | Trạng thái |
|---|---|
| Biên dịch sạch | ☑ |
| Mô phỏng chạy hết, không `UVM_ERROR`/`UVM_FATAL` | ☑ |
| Scoreboard `FAIL = 0` | ☑ |
| Mỗi thanh ghi được đọc và ghi (nếu ghi được) ít nhất một lần | ☑ |
| Functional coverage đạt mục tiêu | ☐ chưa ghi số liệu |
| Tất cả corner case ở mức ✅ hoặc 🟡 có xác nhận bằng coverage | ☐ (9 case ❌) |
| Có assertion giao thức | ☐ |
| Bug injection: mỗi lỗi cố tình chèn vào RTL đều bị bắt | ☐ |
| Code coverage đo và giải thích phần chưa phủ | ☐ |

---

## 11. Hạn chế đã biết

1. **Chưa kiểm tra reset.** Reset chỉ có ở đầu mô phỏng (`presetn = 0` đến 20 ns); chưa có test reset giữa chừng hay reset giữa giao dịch. Driver cũng chưa chờ `presetn` nhả: giao dịch đầu bắt đầu pha setup khi reset còn tích cực (theo waveform) và vẫn đúng nhờ thời điểm, chưa chủ ý.
2. **Không có địa chỉ không căn 4 byte hay alias** vì `addr_c` và dải `dist` giới hạn.
3. **Không có back-to-back.** Driver luôn chèn một chu kỳ nghỉ sau mỗi giao dịch (mỗi giao dịch 30 ns); transaction không có trường `idle_cycles`.
4. **Không có assertion.** `pslverr`/`prdata` ngoài pha access chưa được kiểm tra tự động.
5. **Số PASS chỉ đếm lệnh đọc.** Lệnh ghi được kiểm tra nhưng không tăng `pass_count`.
6. **Driver lấy `prdata`/`pslverr` sớm một chu kỳ** (ngay sau khi đặt `penable`, tức giá trị của pha setup). Không ảnh hưởng kết quả kiểm tra vì scoreboard dùng dữ liệu từ monitor, nhưng trường này trong transaction của driver không đáng tin.
7. **Driver chưa xử lý wait state** (`wait` một lần thay vì lặp theo clock); không ảnh hưởng vì `pready = 1`.
8. **Dữ liệu random không có giá trị biên** (0x0, 0xFFFF_FFFF).
9. **Không có bug injection**, nên chưa có bằng chứng định lượng rằng testbench bắt được lỗi RTL.

---

## 12. Lộ trình cải thiện

| Bước | Việc | Đóng được |
|---|---|---|
| 1 | Mode đọc 4 thanh ghi ngay sau reset; thêm lệnh ghi chủ ý vào 0x04/0x0C | CC-01, 12, 13, 14 |
| 2 | Mode `TEST_INVERT` với giá trị biên và đổi động | CC-07, 10, 11 |
| 3 | Đếm PASS cho cả lệnh ghi; thêm cross `cp_err`, bin chế độ đảo | mục 11.5, mục 8 |
| 4 | Nới `addr_c`, thêm loại địa chỉ không căn và alias; thêm bin | CC-19, 20 |
| 5 | `idle_cycles` trong transaction, driver hỗ trợ back-to-back | CC-21 |
| 6 | Driver điều khiển reset; monitor và scoreboard xử lý sự kiện reset | CC-01, 03, 04 |
| 7 | Assertion SVA cho giao thức (`bind`) | CC-22 |
| 8 | Bug injection: chèn 5–7 lỗi vào bản sao RTL, kiểm tra mỗi lỗi bị bắt | mục 10 |
| 9 | Chạy regression nhiều seed, đo code coverage | mục 10 |

---

## 13. Cách chạy

Từ thư mục `script/` (đường dẫn trong script là tương đối):

```
py run_sim.py          # biên dịch và chạy không giao diện
py run_sim.py -gui     # mở QuestaSim kèm waveform
```

Sửa `QUESTA_BIN` ở đầu `run_sim.py` cho đúng đường dẫn cài đặt. Kết quả thành công: dòng `SCB_REPORT` có `FAIL = 0`, bảng `UVM Report Summary` có `UVM_ERROR : 0` và `UVM_FATAL : 0`.
