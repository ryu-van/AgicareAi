# Đặc tả Kỹ thuật Hệ thống AI & Multimodal RAG (AgriAn AI Specification)

- **Phiên bản:** 1.0.0
- **Ngày cập nhật:** 2026-09-07
- **Tài liệu tham chiếu:** [ADR-003: Kiến trúc AI Multimodal RAG](adr/ADR-003-ai-rag-multimodal-architecture.md), [Kiến trúc tổng thể](architecture.md)

---

## 1. Tổng quan Kiến trúc Kỹ thuật

Hệ thống AI của **AgriAn** được thiết kế để giải quyết bài toán tư vấn kỹ thuật nông nghiệp đa nhánh (**Trồng trọt** & **Chăn nuôi**). Hệ thống tiếp nhận cả văn bản (mô tả triệu chứng) và hình ảnh hiện trường (lá cây, quả, thân, da, mắt, phân vật nuôi...), sau đó đối chiếu với cơ sở cẩm nang nông nghiệp chuẩn hóa để đưa ra khuyến nghị an toàn, có trích dẫn nguồn xác thực.

### Sơ đồ Luồng Dữ liệu Chi tiết (End-to-End Flow):

```text
[Farmer Mobile App]
       │
       │ (1) Gửi Ảnh nén (<200KB) + Câu hỏi (Tiếng Việt)
       ▼
[FastAPI: POST /api/v1/chat/sessions/{id}/messages]
       │
       ├──► (2) Tier 1: Emergency Disease Pre-Check
       │          └─ Nếu phát hiện bệnh dịch nhóm A (ASF, H5N1...) ──► Trả về Khẩn cấp & Ngắt luồng
       │
       ├──► (3) Tier 2: Vision Extraction (Gemini 1.5 Flash)
       │          └─ Input: Image Buffer
       │          └─ Output: Pydantic Structured JSON (Symptom Features)
       │
       ├──► (4) Tier 3: Hybrid Retrieval Engine (PostgreSQL)
       │          ├─ Dense Search (pgvector Cosine Distance <=> 1536 dim)
       │          ├─ Sparse Search (pg_trgm Trigram % on title, symptoms, keywords)
       │          └─ Merge & Rank: Reciprocal Rank Fusion (RRF score)
       │
       ├──► (5) Tier 4: Grounded Synthesis (Gemini 1.5 Flash)
       │          └─ Input: Top 3 Context Chunks + User Question + Symptoms JSON
       │          └─ Output: Câu trả lời có Citation & Disclaimer
       │
       └──► (6) Tier 5: Post-Guardrail Verification
                  └─ Kiểm tra không xuất hiện hoạt chất cấm + Kiểm tra format trích dẫn
                  └─ Trả kết quả về Mobile Client (< 1.8s)
```

---

## 2. Thiết kế Cơ sở Dữ liệu & Vector Storage (`pgvector`)

### 2.1. Cấu trúc Bảng `articles` mở rộng Vector
Trên PostgreSQL (Supabase Target), kích hoạt extension `vector` và `pg_trgm`:

```sql
-- Kích hoạt tiện ích mở rộng
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Bổ sung cột vector embedding vào bảng articles
ALTER TABLE articles ADD COLUMN IF NOT EXISTS embedding vector(1536);
ALTER TABLE articles ADD COLUMN IF NOT EXISTS structured_data jsonb DEFAULT '{}'::jsonb;

-- Chỉ mục HNSW cho tìm kiếm Vector tương đồng nhanh
CREATE INDEX IF NOT EXISTS idx_articles_embedding_hnsw 
ON articles 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Chỉ mục GIN Trigram cho tìm kiếm từ khóa/hoạt chất chính xác
CREATE INDEX IF NOT EXISTS idx_articles_title_trgm ON articles USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_articles_summary_trgm ON articles USING gin (summary gin_trgm_ops);
```

### 2.2. Định dạng Cấu trúc Cẩm nang (Hierarchical Document Chunk)
Mỗi bài viết được lưu trữ với metadata cấu trúc chi tiết trong cột `structured_data`:

```json
{
  "article_id": "art-rice-blast-01",
  "domain": "plant",
  "subject_code": "lua",
  "disease_name": "Bệnh đạo ôn (Cháy lá)",
  "pathogen": "Nấm Pyricularia oryzae",
  "visual_markers": [
    "Vết bệnh hình thoi",
    "Tâm màu xám trắng hoặc tro",
    "Viền ngoài màu nâu đậm hoặc đỏ nâu"
  ],
  "approved_active_ingredients": [
    "Tricyclazole",
    "Isoprothiolane",
    "Fenoxanil",
    "Azoxystrobin"
  ],
  "banned_or_restricted_substances": [
    "Paraquat",
    "2,4-D",
    "Chlorpyrifos Ethyl"
  ],
  "prevention_measures": "Bón phân cân đối N-P-K, ngưng bón đạm khi chớm bệnh, giữ mực nước ruộng thích hợp.",
  "warning_level": "medium",
  "source_organization": "Cục Bảo vệ Thực vật - Bộ NN&PTNT",
  "verified_by": "Chuyên gia BVTV Viện Lúa ĐBSCL"
}
```

---

## 3. Đặc tả Giao diện Vision AI (Multimodal Schema)

Khi người dùng gửi ảnh, adapter `services/api/app/adapters/ai/vision.py` gọi Gemini 1.5 Flash với **Structured Output Mode** sử dụng Pydantic Schema:

```python
from pydantic import BaseModel, Field
from typing import Literal

class VisualSymptomExtraction(BaseModel):
    subject_type: Literal["plant", "animal", "unknown"] = Field(
        description="Loại đối tượng nhận diện được trong ảnh (cây trồng hoặc vật nuôi)"
    )
    detected_target: str = Field(
        description="Tên cụ thể của cây hoặc con (ví dụ: lúa, sầu riêng, heo, gà...)"
    )
    affected_part: str = Field(
        description="Bộ phận tổn thương quan sát được (lá, thân, rễ, da, mắt, phân, mũi...)"
    )
    lesion_color: list[str] = Field(
        description="Màu sắc của tổn thương (ví dụ: vàng nâu, xám tro, đỏ tía...)"
    )
    lesion_shape: list[str] = Field(
        description="Hình dạng tổn thương (ví dụ: hình thoi, đốm tròn, sọc viền, mụn loét...)"
    )
    severity_level: Literal["early", "moderate", "severe", "critical"] = Field(
        description="Mức độ nghiêm trọng quan sát được"
    )
    is_emergency_suspected: bool = Field(
        default=False,
        description="Có dấu hiệu nghi ngờ dịch bệnh nguy cấp nhóm A (ASF, H5N1, FMD...) hay không"
    )
    confidence_score: float = Field(
        ge=0.0, le=1.0,
        description="Độ tin cậy của việc nhận diện hình ảnh"
    )
```

---

## 4. Thuật toán Tìm kiếm Lai (Hybrid Search Engine)

Được triển khai trong `services/api/app/adapters/ai/rag.py`:

```python
def hybrid_search(
    session: Session, 
    query_text: str, 
    query_vector: list[float], 
    domain: str, 
    limit: int = 3,
    rrf_k: int = 60
) -> list[Article]:
    """
    Kết hợp Dense Vector Search và Sparse Trigram Search sử dụng Reciprocal Rank Fusion (RRF).
    
    RRF Score = 1 / (k + rank_dense) + 1 / (k + rank_sparse)
    """
    # 1. Dense retrieval: Lấy top 10 theo Cosine Distance
    # 2. Sparse retrieval: Lấy top 10 theo Full-text / Trigram similarity
    # 3. Hợp nhất bằng công thức RRF và trả về top K bài viết có điểm cao nhất
    pass
```

---

## 5. Quy chuẩn Phân tầng An toàn (Safety Guardrails Engine)

### 5.1. Danh mục Bệnh Khẩn cấp Nhóm A (Cấm tự điều trị tại chỗ)

| Nhánh | Tên dịch bệnh | Hành vi bắt buộc của hệ thống |
| :--- | :--- | :--- |
| **Chăn nuôi (Heo)** | Dịch tả lợn châu Phi (ASF), Lở mồm long móng (FMD), Tai xanh (PRRS thể độc lực cao) | **CHẶN ĐƠN THUỐC**. Phát cảnh báo đỏ: Yêu cầu cách ly chuồng nuôi, không bán tháo, gọi ngay Trạm Chăn nuôi & Thú y Huyện. |
| **Chăn nuôi (Gia cầm)** | Cúm gia cầm (A/H5N1, H5N6, H5N8) | **CHẶN ĐƠN THUỐC**. Cảnh báo lây sang người. Hướng dẫn tiêu độc khử trùng và khai báo khẩn cấp. |
| **Trồng trọt** | Vàng lá thối rễ diện rộng, Bệnh chổi rồng, Khảm lá sắn vi rút | Cảnh báo mức độ lây lan nhanh, hướng dẫn tiêu hủy tàn dư đúng quy trình kiểm dịch. |

### 5.2. Mẫu Phản hồi Bắt buộc (Mandatory Output Structure)

Mọi phản hồi của trợ lý AI bắt buộc phải tuân theo 4 khối nội dung:

1. **Khối 1 - Đánh giá sơ bộ:** Nêu rõ khả năng cao nhất và 1-2 khả năng phụ dựa trên triệu chứng.
2. **Khối 2 - Biện pháp kỹ thuật an toàn:** Ưu tiên biện pháp canh tác/vệ sinh chuồng trại trước khi dùng hóa chất. Nếu đề xuất hoạt chất, chỉ nêu **Tên hoạt chất (Generic Name)**, không nêu nhãn hiệu thương mại độc quyền.
3. **Khối 3 - Trích dẫn nguồn (Citations):**
   * Format: `[Nguồn: <Tên bài viết>, <Cơ quan ban hành>]`
4. **Khối 4 - Cảnh báo giới hạn (Disclaimer):**
   * *"Thông tin chỉ mang tính tham khảo kỹ thuật. Người nuôi/trồng cần quan sát thực tế và tham vấn bác sĩ thú y hoặc cán bộ khuyến nông địa phương trước khi ra quyết định."*

---

## 6. Chỉ số Hiệu năng & Ngân sách Chi phí (SLO & Budget)

| Chỉ số kỹ thuật | Mục tiêu thiết kế (SLO) | Giải pháp bảo đảm |
| :--- | :--- | :--- |
| **P95 Latency (Text Chat)** | $< 1.5$ giây | Streaming response, Gemini 1.5 Flash |
| **P95 Latency (Image + Vision RAG)** | $< 2.5$ giây | Nén ảnh tại client Flutter (<200KB), chạy song song Hybrid search |
| **Chi phí API / 1.000 lượt tương tác** | $< 0.15$ USD (~3.800 VNĐ) | Áp dụng Semantic Caching và Context Caching |
| **Tỷ lệ Ảo giác (Hallucination Rate)** | $< 1\%$ trên các trường hoạt chất | RAG Grounding + Post-guardrail regex validator |

