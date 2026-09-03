# Yêu cầu MVP

## Phạm vi

### Must-have

- R1: Người dùng chọn nhánh `Trồng trọt` hoặc `Chăn nuôi`.
- R2: Người dùng gửi câu hỏi tiếng Việt; hệ thống trả lời dựa trên knowledge base đúng nhánh, kèm nguồn và cảnh báo giới hạn.
- R3: Người dùng xem thư viện kiến thức theo cây/con hoặc vật nuôi được hỗ trợ.
- R4: Người dùng lưu nhật ký chăm sóc và tạo nhắc lịch cơ bản.
- R5: Người dùng có thể đánh dấu ca cần chuyên gia; hệ thống không tự nhận là chẩn đoán cuối cùng.
- R6: Câu hỏi/nhật ký chưa đồng bộ được lưu cục bộ và retry idempotent khi online.

### Should-have sau vertical slice đầu tiên

- R7: Upload ảnh và trả top-3 khả năng cho đúng tập vật nuôi/cây đã có dữ liệu kiểm định.
- R8: Kết nối danh bạ chuyên gia theo khu vực thí điểm.

### Out of scope

- Bản đồ vùng dịch bệnh realtime.
- Tư vấn kê đơn/liều thuốc tự động trước review pháp lý/chuyên gia.
- Marketplace, quảng cáo thuốc, microservices, model tự huấn luyện online.

## Acceptance criteria

- **AC1:** Given người dùng ở nhánh chăn nuôi, when hỏi về triệu chứng, then câu trả lời chỉ dùng nội dung của nhánh đó, hiển thị nguồn, thời điểm cập nhật và nút “Cần chuyên gia”.
- **AC2:** Given API/AI timeout, when gửi câu hỏi, then app hiển thị trạng thái đang thử lại, không tạo câu trả lời giả, và cho phép retry.
- **AC3:** Given offline, when lưu nhật ký hoặc câu hỏi nháp, then dữ liệu được đánh dấu pending và không mất sau khi đóng/mở app.
- **AC4:** Given người dùng gửi trùng request do retry, when server nhận cùng idempotency key, then chỉ tạo một bản ghi.
- **AC5:** Given kết quả ảnh có độ tin cậy thấp, when hiển thị, then app yêu cầu thêm ảnh/thông tin hoặc chuyển chuyên gia, không khẳng định bệnh.
- **AC6:** Các nút chính có vùng chạm tối thiểu 44pt, nhãn accessibility, trạng thái loading/error rõ ràng và không che bởi safe area.

## Edge cases

| Trường hợp | Hành vi |
|---|---|
| Câu hỏi rỗng/ảnh quá lớn | Validate tại client, hướng dẫn sửa |
| Không có kết quả phù hợp | Nói rõ không đủ cơ sở, đề nghị chuyên gia |
| Không có mạng | Queue cục bộ, hiển thị trạng thái pending |
| Token hết hạn | Refresh hoặc yêu cầu đăng nhập lại, không mất draft |
| Retry/duplicate | Idempotency key và upsert theo client event id |
| Nội dung nguy hiểm | Chặn/đưa cảnh báo và escalation |

## Open questions (blocking trước production)

1. Khu vực thí điểm và ngôn ngữ/giọng địa phương nào?
2. Chọn heo/gà hay cây trồng nào dựa trên dữ liệu/đối tác thực tế?
3. Ai chịu trách nhiệm duyệt knowledge base và câu trả lời nguy cơ cao?
4. Có team AI/ML và chuyên gia thú y/BVTV chưa?
5. Ngân sách, deadline và tiêu chí pilot thành công?
