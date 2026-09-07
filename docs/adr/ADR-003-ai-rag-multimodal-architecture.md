# ADR-003: Kiến trúc AI Multimodal RAG và Tìm kiếm lai (Hybrid Search) cho AgriAn

- Status: Accepted
- Date: 2026-09-07
- Scope: `services/api/app/adapters/ai`, `services/api/app/modules/chat`, `services/api/app/modules/diagnosis`
- Owners: Engineering Team / AI Lead

---

## 1. Context (Bối cảnh kỹ thuật)

Nền tảng **AgriAn** cần cung cấp giải pháp tư vấn kỹ thuật nông nghiệp thông minh (Trồng trọt & Chăn nuôi) cho nông hộ Việt Nam. Khác với các hệ thống chatbot văn phòng thông thường, bài toán AI nông nghiệp có các ràng buộc nghiêm ngặt:

1. **Đa phương thức (Multimodal Input):** Nông dân thường chụp ảnh lá cây bị đốm, quả bị thối, da vật nuôi tổn thương hoặc chất thải... kèm câu hỏi ngắn bằng ngôn ngữ địa phương.
2. **Rủi ro ảo giác (Hallucination Risk) & Trách nhiệm pháp lý:** Đưa ra sai hoạt chất thuốc bảo vệ thực vật hoặc kháng sinh thú y có thể gây chết hàng loạt, vi phạm quy định dư lượng hóa chất, gây thiệt hại kinh tế nghiêm trọng cho người nông dân.
3. **Từ vựng chuyên ngành & Phương ngữ:** Tên hoạt chất (*Azoxystrobin*, *Tebuconazole*, *Amoxicillin*...), tên bệnh dân gian (*đạo ôn*, *thối đọt*, *tai xanh*, *phân sáp*...) đòi hỏi độ khớp từ khóa chính xác.
4. **Hạ tầng & Chi phí (Unit Economics):** Ứng dụng phục vụ nông dân với mức độ sẵn sàng trả tiền (WTP) ban đầu bằng 0, yêu cầu chi phí suy luận (inference cost) trên mỗi truy vấn phải tiệm cận mức tối thiểu.

---

## 2. Decision (Quyết định kiến trúc)

Chúng tôi quyết định thiết kế hệ thống AI của AgriAn theo kiến trúc **Multimodal Hybrid RAG với 3 tầng Guardrail an toàn**:

```text
[Mobile App (Ảnh nén < 200KB + Text)]
                 |
                 v
   FastAPI Modular Monolith API
     ├─ Tier 1: Safety Pre-Guardrail (Nhận diện bệnh khẩn cấp Nhóm A)
     ├─ Tier 2: Vision Extraction (Gemini 1.5 Flash -> JSON triệu chứng)
     ├─ Tier 3: Hybrid Search (PostgreSQL: pgvector Dense + pg_trgm Sparse)
     ├─ Tier 4: Grounded LLM Reasoning (Gemini 1.5 Flash + Citation Rules)
     └─ Tier 5: Safety Post-Guardrail (Factuality check + Disclaimer bắt buộc)
```

### 2.1. Lựa chọn Mô hình Suy luận (LLM & Vision)
* **Lựa chọn:** **Google Gemini 1.5 Flash** (Managed API-first).
* **Lý do:**
  * Khả năng thị giác máy tính vượt trội đối với ảnh thực địa phức tạp, mờ hoặc thiếu sáng.
  * Tối ưu hóa tiếng Việt tự nhiên sâu sắc, hiểu tốt văn cảnh nông nghiệp.
  * Tốc độ phản hồi cực nhanh (Time to First Token < 800ms, tổng thời gian < 1.5s).
  * Chi phí rẻ nhất phân khúc multimodal ($0.075 / 1M input tokens).
  * Hỗ trợ **Context Caching** cho bộ cẩm nang nền tảng, giúp giảm tiếp 75% chi phí truy vấn.

### 2.2. Động cơ Tìm kiếm Ngữ nghĩa (Retrieval Engine)
* **Lựa chọn:** **PostgreSQL + `pgvector` kết hợp `pg_trgm` / Full-Text Search**.
* **Cơ chế:** **Hybrid Search (Dense + Sparse)** với thuật toán xếp hạng hợp nhất **RRF (Reciprocal Rank Fusion)**:
  * *Dense Vector (Cosine Distance `<=>`):* Nắm bắt ngữ nghĩa và sự tương đồng về triệu chứng bệnh lý.
  * *Sparse Lexical (BM25 / Trigram `%`):* Bắt chính xác tên cây, con, tên hoạt chất và thuật ngữ địa phương.
* **Lưu trữ:** Tích hợp trực tiếp trên PostgreSQL (Supabase target), không dùng Vector DB độc lập.

### 2.3. Mô hình Vector Embedding
* **Giai đoạn MVP / Pilot:** Sử dụng **`text-embedding-3-small`** (1536 chiều hoặc rút gọn 512 chiều) qua API để tích hợp nhanh, không tốn chi phí server.
* **Giai đoạn Mở rộng (Scale):** Chuyển dịch sang tự host **`BAAI/bge-m3`** (1024 chiều) để đạt độ chính xác tối đa về biểu diễn ngữ nghĩa và hỗ trợ multi-vector tiếng Việt.

### 2.4. Chiến lược Phân mảnh Kiến thức (Hierarchical Chunking)
* Không sử dụng phân mảnh cố định theo độ dài ký tự (Fixed-size chunking).
* Áp dụng **Document-Structured Chunking**: Mỗi bài cẩm nang là một thực thể JSON hoàn chỉnh gồm: Định danh, Nhánh (Trồng trọt/Chăn nuôi), Đối tượng (Cây/Con), Bệnh lý, Triệu chứng đặc trưng, Biện pháp kỹ thuật, Hoạt chất được cấp phép lưu hành, Mức độ cảnh báo và Cơ quan ban hành.

### 2.5. Phân tầng An toàn 3 Cấp độ (Safety Guardrails)
1. **Pre-Guardrail:** Kiểm tra từ khóa và mẫu bệnh nguy cấp thuộc Danh mục bệnh động vật/thực vật phải công bố dịch (như Dịch tả lợn châu Phi - ASF, Cúm gia cầm H5N1...). Khi phát hiện: **Chặn ngay lập tức** việc tự ý chữa trị, hiển thị hướng dẫn cách ly và số điện thoại cơ quan thú y/BVTV địa phương.
2. **In-Generation:** Giới hạn câu trả lời chỉ được đề xuất hoạt chất nằm trong danh mục cẩm nang đã duyệt; cấm tuyệt đối việc tạo ra đơn thuốc hóa chất cấm.
3. **Post-Guardrail:** Luôn đính kèm trích dẫn nguồn ([Citation Title + Section]) và câu khuyến cáo pháp lý (Disclaimer).

---

## 3. Alternatives Considered (Các phương án thay thế đã xem xét)

| Phương án thay thế | Lý do không chọn |
| :--- | :--- |
| **Self-hosted vLLM + Qwen2.5-VL-7B trên GPU riêng** | Chi phí cố định cao (tối thiểu 8-15 triệu VNĐ/tháng cho server GPU A10G/4090); gánh nặng vận hành hạ tầng quá lớn trong giai đoạn S1/MVP. |
| **Dedicated Vector Database (Pinecone, Qdrant, Milvus)** | Làm phân mảnh hệ thống dữ liệu, tăng chi phí và phát sinh nguy cơ lệch dữ liệu giao dịch giữa DB chính và Vector DB. `pgvector` hoàn toàn đáp ứng tốt hàng trăm ngàn bài viết nông nghiệp. |
| **Pure Vector Search (Chỉ dùng Dense Embeddings)** | Thường xuyên bỏ sót các tên hoạt chất hóa học, tên hoạt chất kháng sinh hoặc từ vựng địa phương đặc thù. |
| **Chạy Edge AI (TFLite MobileNet) trên điện thoại** | Tập dữ liệu ảnh sâu bệnh đa dạng cây con tại Việt Nam chưa đủ gán nhãn chuẩn; mô hình mobile dễ sinh false-positive nguy hiểm nếu góc chụp không chuẩn. |

---

## 4. Consequences & Trade-offs (Hệ quả & Đánh đổi)

### Mặt tích cực:
* Độ chính xác cao, kiểm soát hoàn toàn hiện tượng ảo giác nhờ cơ chế Grounded Retrieval + Citations bắt buộc.
* Chi phí vận hành thấp nhất có thể, chỉ trả tiền theo lượng sử dụng thực tế.
* Kiến trúc tinh gọn (Modular Monolith) nhất quán với ADR-001 và công nghệ PostgreSQL hiện có.
* Tính an toàn pháp lý được bảo đảm ngay từ tầng kiến trúc.

### Mặt đánh đổi & Rủi ro:
* Phụ thuộc vào kết nối mạng và tính sẵn sàng của Google Gemini API (khi mất mạng, client dùng dữ liệu offline cache).
* Yêu cầu dữ liệu cẩm nang đưa vào Knowledge Base phải được chuyên gia kiểm định trước khi vector hóa.

---

## 5. Revisit Trigger (Điều kiện xem xét lại kiến trúc)

Kiến trúc này sẽ được đánh giá lại khi:
1. Chi phí API Gemini vượt quá ngưỡng $500/tháng (lúc này việc tự host vLLM trên cụm GPU riêng sẽ bắt đầu có lợi thế kinh tế).
2. Quy mô dữ liệu cẩm nang vượt quá 2.000.000 vectors cần cơ chế sharding chuyên biệt.
3. Có đối tác cung cấp mô hình AI chuyên biệt cho nông nghiệp Việt Nam được huấn luyện riêng biệt có kết quả kiểm định vượt trội.

