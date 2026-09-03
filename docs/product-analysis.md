# Phân tích sản phẩm

## Quyết định cần làm

Đầu tư một MVP mobile-first cho hộ chăn nuôi/trồng trọt nhỏ lẻ, tập trung vào hỏi đáp có nguồn và triage ca bệnh; chưa đầu tư bản đồ dịch bệnh hay mạng chuyên gia quy mô lớn.

## Bằng chứng và mức tin cậy

- **Stakeholder claim:** tài liệu ý tưởng mô tả khó tiếp cận thú y/khuyến nông, tự đoán bệnh và mạng yếu.
- **Assumption:** hộ nhỏ lẻ là phân khúc ban đầu; chưa có phỏng vấn hay dữ liệu sử dụng.
- **Inference:** chatbot + thư viện kiến thức có thể tạo giá trị sớm hơn vision model vì ít phụ thuộc dữ liệu ảnh gán nhãn.
- **Evidence gap:** vùng thí điểm, loại cây/con, willingness-to-pay, đối tác chuyên môn và bộ dữ liệu Việt Nam.

## So sánh lựa chọn

| Lựa chọn | Lợi ích | Chi phí/rủi ro | Quyết định |
|---|---|---|---|
| Không làm | Không tốn chi phí | Không kiểm chứng nhu cầu | Không chọn |
| MVP chatbot + knowledge base + nhật ký | Học nhanh, rủi ro AI thấp hơn | Cần biên tập/chuyên gia | **Chọn** |
| Đưa vision + bản đồ ngay | Demo hấp dẫn | Dữ liệu, pháp lý, false positive, vận hành cao | Loại khỏi MVP |

## MVP hypothesis

Với hộ nhỏ lẻ tại một khu vực thí điểm, chatbot tiếng Việt có nguồn + thư viện theo cây/con sẽ tăng tỷ lệ người dùng quay lại để xử lý vấn đề chăm sóc, vì giải quyết được câu hỏi thường ngày ngay cả khi chưa có ảnh tốt.

- Leading metric: tỷ lệ người dùng hoàn tất ít nhất một phiên hỏi đáp hữu ích/tuần.
- Guardrail: tỷ lệ câu trả lời bị chuyên gia đánh dấu nguy hiểm hoặc không có nguồn.
- Cách học: pilot nhỏ 4 tuần, ghi nhận câu hỏi, câu trả lời được đánh giá và nhu cầu chuyển chuyên gia.
- Quyết định: mở rộng nội dung nếu leading metric đạt ngưỡng do product owner đặt ra và guardrail không vượt ngưỡng an toàn; nếu không, phỏng vấn lại và thu hẹp phạm vi.
