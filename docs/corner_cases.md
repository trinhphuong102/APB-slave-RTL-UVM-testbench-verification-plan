# Corner Cases — APB Slave

Danh sách các tình huống biên của DUT (`rtl/async_apb_slave.sv`) và trạng thái phủ của testbench **ở phiên bản hiện tại**.
Tài liệu này đi kèm [verification_plan.md](verification_plan.md).

Corner case ở đây là một tình huống cụ thể mà bạn muốn **chắc chắn đã được thử**: giá trị biên, địa chỉ biên, chuỗi giao dịch đặc biệt, hoặc điều kiện hiếm của giao thức. Random chỉ làm tình huống đó dễ xảy ra hơn, không đảm bảo nó xảy ra.

## Cách đọc trạng thái

| Trạng thái | Ý nghĩa |
|---|---|
| ✅ Đã phủ | Có giao dịch directed trong `apb_sequence.sv` thử đúng tình huống này; có bằng chứng trong log hoặc waveform |
| 🟡 Chỉ nhờ random | Stage random có thể chạm tới nhưng không đảm bảo; cần xem coverage để xác nhận |
| ❌ Chưa phủ | Testbench hiện tại chưa tạo được tình huống này (ghi rõ lý do) |
| ⚪ Không áp dụng | DUT không có tính năng liên quan |

## Tổng hợp

| Trạng thái | Số lượng |
|---|---|
| ✅ Đã phủ | 7 |
| 🟡 Chỉ nhờ random | 8 |
| ❌ Chưa phủ | 9 |
| ⚪ Không áp dụng | 1 |
| **Tổng** | **25** |

Bằng chứng lấy từ lần chạy QuestaSim 10.7c / UVM-1.1d: `PASS = 57 | FAIL = 0`, `UVM_ERROR = 0`, kết thúc ở 3335 ns (xem [log.png](log.png) và [waveform.png](waveform.png)).

## Danh sách chi tiết

### A. Reset

| ID | Tình huống | Kết quả mong đợi | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|---|---|
| CC-01 | Giá trị sau reset: `sys_ctrl` và `data_in` bằng 0 khi đọc ngay sau reset | prdata = 0x0, pslverr = 0 | ❌ Chưa phủ | Sequence luôn ghi trước khi đọc. Cần mode đọc 4 thanh ghi ngay sau reset. |
| CC-02 | `sys_status` luôn bằng 0xCAFE_BABE | prdata = 0xCAFE_BABE, pslverr = 0 | ✅ Đã phủ | Stage 2 `TEST_READ_ALL`; log: `paddr=0x4 \| Data=0xcafebabe`. |
| CC-03 | Reset bất đồng bộ giữa mô phỏng khi `sys_ctrl`, `data_in` đang khác 0 | Cả hai về 0 ngay khi `presetn` xuống 0, không cần chờ clock | ❌ Chưa phủ | TB chỉ reset một lần ở đầu mô phỏng. |
| CC-04 | Reset xảy ra giữa một giao dịch ghi | Lệnh ghi không có hiệu lực, thanh ghi về 0 | ❌ Chưa phủ | Driver chưa điều khiển được `presetn`. |

### B. Thanh ghi đọc/ghi (0x00, 0x08)

| ID | Tình huống | Kết quả mong đợi | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|---|---|
| CC-05 | Ghi rồi đọc lại `sys_ctrl` với dữ liệu random | Đọc ra đúng giá trị đã ghi | ✅ Đã phủ | Stage 1 + 2; log: `sys_ctrl = 0x1e102a97`. |
| CC-06 | Ghi rồi đọc lại `data_in` với dữ liệu random | Đọc ra đúng giá trị đã ghi | ✅ Đã phủ | Stage 1 + 2; log: `data_in = 0x3db0b7ea`. |
| CC-07 | Giá trị biên: 0x0000_0000, 0xFFFF_FFFF, walking-1 | Đọc lại đúng, đủ 32 bit | ❌ Chưa phủ | `pwdata` random không ràng buộc nên gần như không chạm các giá trị này. |
| CC-08 | Ghi đè liên tiếp vào cùng một thanh ghi; ghi thanh ghi này không làm đổi thanh ghi kia | Giá trị sau cùng thắng; thanh ghi còn lại không đổi | 🟡 Chỉ nhờ random | Random stage 4; scoreboard bắt lỗi khi đọc lại. |

### C. Chế độ đảo (`sys_ctrl[0]` → `data_out`)

| ID | Tình huống | Kết quả mong đợi | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|---|---|
| CC-09 | `sys_ctrl[0] = 1`: `data_out = ~data_in` | Đọc 0x0C ra giá trị đảo bit của `data_in` | ✅ Đã phủ | Stage 2; log: `~0x3db0b7ea = 0xc24f4815`. |
| CC-10 | `sys_ctrl[0] = 0`, kể cả khi 31 bit còn lại bằng 1: `data_out = data_in` | Không đảo | 🟡 Chỉ nhờ random | Random stage 4; log @895 ns: `data_out` bằng `data_in` vừa đọc. |
| CC-11 | Thay đổi động: đổi `data_in` khi đang đảo; đổi bit 0 liên tiếp 0→1→0→1 | `data_out` đổi theo ngay ở lần đọc kế tiếp | 🟡 Chỉ nhờ random | Random stage 4; chưa có kịch bản chủ ý. |

### D. Thanh ghi chỉ đọc (0x04, 0x0C)

| ID | Tình huống | Kết quả mong đợi | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|---|---|
| CC-12 | Ghi vào `sys_status` (0x04) | pslverr = 1, giá trị không đổi | 🟡 Chỉ nhờ random | Random stage 4 (xác suất khoảng 5% mỗi giao dịch); xác nhận bằng ô (sys_status, write) của cross. |
| CC-13 | Ghi vào `data_out` (0x0C) | pslverr = 1, giá trị không đổi | 🟡 Chỉ nhờ random | Random stage 4; xác nhận bằng ô (data_out, write) của cross. |
| CC-14 | Ghi đúng giá trị đang có vào thanh ghi chỉ đọc | Vẫn báo pslverr = 1 | ❌ Chưa phủ | Cần sequence chủ ý. |

### E. Địa chỉ

| ID | Tình huống | Kết quả mong đợi | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|---|---|
| CC-15 | Đọc địa chỉ ngoài vùng, căn 4 byte (0x10 trở lên) | prdata = 0, pslverr = 1 | ✅ Đã phủ | Stage 3 đọc 0x20; log: `paddr=0x20 \| Data=0x0 \| Err=1`; random: 0xac, 0x7c, 0x34... |
| CC-16 | Ghi địa chỉ ngoài vùng, căn 4 byte | pslverr = 1 | ✅ Đã phủ | Stage 3 ghi 0x14 (xung pslverr trong waveform). |
| CC-17 | Địa chỉ sát biên: 0x10 và cuối dải 0xFC | pslverr = 1 | 🟡 Chỉ nhờ random | Random trong dải 0x10–0xFF; chưa có kịch bản chủ ý. |
| CC-18 | Truy cập ngoài vùng không làm đổi bất kỳ thanh ghi nào | Các thanh ghi giữ nguyên | 🟡 Chỉ nhờ random | Scoreboard bắt lỗi ở lần đọc lại sau đó. |
| CC-19 | Địa chỉ không căn 4 byte (0x01, 0x02, 0x03, 0x05, 0x09, 0x0D...) | Coi như ngoài vùng: pslverr = 1 | ❌ Chưa phủ | Constraint `addr_c` (`paddr[1:0] == 0`) chặn không cho sinh. |
| CC-20 | Alias: địa chỉ có bit cao khác 0 (0x100, 0x108, 0xFFFF_FF0C...) | Trùng thanh ghi có 8 bit thấp tương ứng (RTL chỉ decode `paddr[7:0]`) | ❌ Chưa phủ | Dải random chỉ đến 0xFF; covergroup chưa có bin cho alias. |

### F. Giao thức và thời gian

| ID | Tình huống | Kết quả mong đợi | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|---|---|
| CC-21 | Giao dịch liên tiếp không nghỉ (back-to-back) và khoảng nghỉ nhiều chu kỳ | Kết quả không đổi | ❌ Chưa phủ | Driver luôn chèn đúng 1 chu kỳ nghỉ (mỗi giao dịch 30 ns); transaction không có trường `idle_cycles`. |
| CC-22 | `prdata` và `pslverr` bằng 0 ngoài pha access (kể cả pha setup) | Không có lỗi hay dữ liệu ngoài pha access | ❌ Chưa phủ | Chưa có assertion; scoreboard chỉ lấy mẫu ở pha access. |
| CC-23 | Wait state (`pready = 0`) | — | ⚪ Không áp dụng | RTL gán `pready = 1` cố định. |
| CC-24 | Xen kẽ giao dịch hợp lệ và giao dịch lỗi liên tiếp | `pslverr` đúng theo từng giao dịch, giao dịch hợp lệ sau lỗi vẫn có hiệu lực | 🟡 Chỉ nhờ random | Random stage 4. |
| CC-25 | Chuỗi dài giao dịch random (100) | Scoreboard không báo FAIL | ✅ Đã phủ | Stage 4: 100 giao dịch, `FAIL = 0`. |

## Việc cần làm để đóng các case ❌

Sắp theo độ tốn công, từ ít đến nhiều:

| Ưu tiên | Việc | Đóng được | Sửa ở đâu |
|---|---|---|---|
| 1 | Thêm mode đọc 4 thanh ghi ngay sau reset, trước khi ghi | CC-01 | `apb_sequence.sv`, `apb_test.sv` |
| 2 | Thêm lệnh ghi chủ ý vào 0x04, 0x0C (dữ liệu khác và trùng giá trị hiện tại) vào `TEST_ERROR_HANDLING` | CC-12, 13, 14 | `apb_sequence.sv` |
| 3 | Thêm mode `TEST_INVERT`: ghi giá trị biên (0x0, 0xFFFF_FFFF), bật/tắt bit 0 liên tiếp, đổi `data_in` khi đang đảo | CC-07, 10, 11 | `apb_sequence.sv` |
| 4 | Thêm loại địa chỉ không căn 4 byte và alias: nới `addr_c`, thêm bin cho `cp_addr` | CC-19, 20 | `apb_transaction.sv`, `apb_coverage.sv` |
| 5 | Thêm trường `idle_cycles` vào transaction, driver chờ đúng số chu kỳ (0 = back-to-back) | CC-21 | `apb_transaction.sv`, `apb_driver.sv` |
| 6 | Cho driver điều khiển `presetn` (reset lúc rảnh và giữa giao dịch), monitor báo sự kiện reset cho scoreboard | CC-03, 04 | `apb_driver.sv`, `apb_monitor.sv`, `apb_scoreboard.sv` |
| 7 | Thêm assertion `prdata`/`pslverr` bằng 0 ngoài pha access | CC-22 | file SVA mới, `bind` vào DUT |

Sau mỗi bước, chạy lại, kiểm tra log và coverage, rồi cập nhật cột trạng thái trong bảng ở trên.

## Lịch sử

| Ngày | Thay đổi |
|---|---|
| 2026-10-22 | Bản đầu, đối chiếu với testbench gồm `apb_sequence` (4 mode), `apb_test` (4 stage) và lần chạy 108 giao dịch |
