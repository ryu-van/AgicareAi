# AgriAn — Hướng Dẫn Nhận Diện Thương Hiệu & Logo (Brand Identity & Logo Guidelines)

> **Tài liệu chuẩn hóa thương hiệu chính thức cho toàn bộ hệ thống Web & Mobile**  
> **Áp dụng từ:** Tháng 09/2026  
> **Thương hiệu:** **AgriAn** (Hệ sinh thái Nông nghiệp Thông minh & An tâm)  
> **Khẩu hiệu (Tagline):** *"Vụ mùa an tâm, nông gia thịnh vượng"*

---

## 1. TRIẾT LÝ THƯƠNG HIỆU (BRAND PHILOSOPHY)

### 1.1. Tên gọi: `AgriAn`
- **Cấu trúc ngôn ngữ:**
  - **Agri** (Nông nghiệp - Agriculture): Thể hiện tính chuyên môn, hiện đại, vươn tầm quốc tế.
  - **An** (An tâm, An toàn, An lành trong tiếng Việt): Giá trị cốt lõi mang lại cho bà con nông dân.
- **Phiên âm quốc tế:** Đồng âm với từ **"Agrarian"** (`/əˈɡreəriən/`) — mang ý nghĩa nền văn minh nông nghiệp, gắn kết với đất đai màu mỡ.
- **Tên gọi thuần Việt thân thương:** **"Nông An"** — Dễ đọc, dễ nhớ, gần gũi với mọi thế hệ nông dân Việt Nam.

---

## 2. BIỂU TƯỢNG CHÍNH THỨC (OFFICIAL LOGO)

### Concept: Chiếc Khiên Bảo Vệ Đa Nhánh (The Protective Dual-Domain Shield)

Tệp asset chuẩn:
- Mobile: `apps/mobile_flutter/assets/images/agrian_logo.jpg`
- Thiết kế & Web: `design-system/agrian_logo.jpg`

```text
                     / \
                   /     \       <-- Vành khiên lá bảo vệ (Shield of Protection)
                 /   / \   \
                |   |   |   |
                |   \  /    |    <-- Mầm cây xanh (Cây trồng / Crops Domain)
                |    \/     |
                |   (o o)   |    <-- Bóng gia súc vàng lúa (Vật nuôi / Livestock Domain)
                |  o--o--o  |    <-- Nút mạng dữ liệu & vi mạch (AI Knowledge Nodes)
                 \         /
                   \     /
                     \ /
```

### 2.1. Phân tích chi tiết các thành phần hình học
1. **Khung Khiên Hữu Cơ (Organic Shield):**
   - Hình tượng chiếc khiên bao bọc thể hiện sự **chở che, phòng ngừa dịch bệnh**, bảo vệ an toàn sinh học cho toàn bộ nông trang.
   - Các đường viền lấy cảm hứng từ hai phiến lá xanh đan chéo, giữ nét mềm mại sinh thái thay vì góc cạnh kim loại.
2. **Mầm Cây Xanh Vươn Lên (Green Sprout — Trồng trọt):**
   - Đại diện cho nhánh Cây trồng (lúa nước, hoa màu, cây ăn trái).
   - Nằm ở trung tâm vươn thẳng đứng, biểu trưng cho sự sinh sôi nảy nở và mùa màng bội thu.
3. **Bóng Đàn Vật Nuôi Vàng Lúa (Golden Livestock — Chăn nuôi):**
   - Đại diện cho nhánh Vật nuôi (gia súc, gia cầm).
   - Màu vàng ấm áp của lúa chín và đất đai trù phú, tạo thế cân bằng sinh thái "Vườn - Ao - Chuồng".
4. **Các Điểm Kết Nối Vi Mạch & Dữ Liệu (AI Circuit Nodes):**
   - Tượng trưng cho trí tuệ nhân tạo (AI), hệ thống kiến thức khuyến nông chính thống đã qua kiểm định chuyên gia.

---

## 3. BẢNG MÀU THƯƠNG HIỆU CHUẨN (COLOR SPECIFICATION)

Để đảm bảo đồng nhất 100% giữa **Mobile App Flutter** và **Giao diện Web/Landing Page sau này**, bắt buộc sử dụng đúng các mã màu sau:

| Tên màu | Mã Hex | RGB | Ý nghĩa & Vùng sử dụng |
|---|---|---|---|
| **Agri Primary Green** | `#3B6D11` | `rgb(59, 109, 17)` | Màu chủ đạo: Điểm nhấn cây trồng, nút CTA chính, viền logo |
| **Harvest Gold** | `#D49A00` | `rgb(212, 154, 0)` | Điểm nhấn mùa gặt: Thóc lúa, vật nuôi, huy hiệu sổ tay & mẹo hay |
| **Harvest Gold Light** | `#FEF6E4` | `rgb(254, 246, 228)` | Nền thẻ mẹo nông nghiệp, thẻ nông trại ấm áp |
| **Sun Amber** | `#D97706` | `rgb(217, 119, 6)` | Dự báo thời tiết, mùa vụ, cảnh báo vừa phải |
| **Forest Dark (Nav/Header)** | `#275300` | `rgb(39, 83, 0)` | Màu thanh điều hướng dưới đáy (Bottom Nav), Header trang trọng |
| **Tech Info Blue** | `#1665B5` | `rgb(22, 101, 181)` | Màu công nghệ: Trợ lý AI chat, tính năng AI, liên kết |
| **Clean Ivory (Surface)** | `#FBFBF6` | `rgb(251, 251, 246)` | Màu nền thẻ (Card background), nền icon app dịu mắt |
| **Alert Danger Red** | `#A32D2D` | `rgb(163, 45, 45)` | Cảnh báo dịch bệnh bùng phát, tình huống khẩn cấp cần chuyên gia |

### 3.1. Nguyên tắc phối màu hài hòa: "Trắng - Xanh - Vàng" (Tránh tràn ngập màu xanh lá)
- **Tuyệt đối tránh "Mono-green"**: Không đổ tràn màu xanh lá đặc khối lên toàn bộ màn hình khiến giao diện bị nặng nề, bí bách.
- **Tỉ lệ vàng 60 - 30 - 10**:
  - **60% Trắng / Ngà sáng (`#FFFFFF`, `#FBFBF6`)**: Làm nền tảng sạch sẽ, tạo khoảng thở cho mắt, tối ưu khả năng đọc ngoài trời.
  - **30% Xanh lá (`#3B6D11`, `#275300`)**: Dành cho thanh điều hướng, nút kích hoạt hành động quan trọng (Call to Action), trạng thái cây trồng khỏe mạnh.
  - **10% Vàng lúa / Hổ phách ấm (`#D49A00`, `#FEF6E4`) & Xanh công nghệ (`#1665B5`)**: Điểm xuyết cho các thẻ tri thức, sổ tay dịch hại, mẹo hàng ngày, biểu tượng nông trại và trợ lý AI thông minh.

---

## 4. TYPOGRAPHY (PHÔNG CHỮ)

- **Tiêu đề & Logo (Headings & Wordmark):** **Be Vietnam Pro**
  - Trọng lượng (Weight): `SemiBold (600)`, `Bold (700)`, `Black (900)`.
  - Đặc tính: Được thiết kế riêng cho tiếng Việt, dấu thanh cân đối, nét chữ mở và thoáng giúp người dùng đọc tốt ngay cả trên màn hình điện thoại giá rẻ ngoài trời nắng.
- **Nội dung thân bài (Body text):** **Noto Sans** hoặc hệ thống phông mặc định của hệ điều hành.

---

## 5. QUY TẮC HIỂN THỊ TRÊN GIAO DIỆN (UI IMPLEMENTATION RULES)

### 5.1. Dành cho Mobile (Flutter)
- Luôn sử dụng widget dùng chung đã đóng gói:
  ```dart
  import 'package:agricare_ai_mobile/shared/widgets/app_brand_logo.dart';

  // Biểu tượng kích thước chuẩn
  AppBrandLogo(size: BrandLogoSize.small)   // 32x32 cho AppBar
  AppBrandLogo(size: BrandLogoSize.medium)  // 48x48 cho Card/Header
  AppBrandLogo(size: BrandLogoSize.large)   // 64x64 cho Hero banner

  // Thanh tiêu đề có logo + tên thương hiệu + slogan
  AgriAnBrandHeader()
  ```

### 5.2. Dành cho Web (HTML / CSS / Tailwind / Next.js sau này)
- Thẻ logo luôn có bo góc squircle chuẩn tỉ lệ `border-radius: 24%`:
  ```css
  .agrian-logo {
    width: 48px;
    height: 48px;
    border-radius: 24%;
    border: 1.5px solid rgba(59, 109, 17, 0.2);
    box-shadow: 0 4px 12px rgba(59, 109, 17, 0.12);
    object-fit: cover;
  }
  ```
- **Khoảng trống an toàn (Clear Space):** Luôn chừa lề tối thiểu bằng 20% chiều cao logo xung quanh để không bị các nút bấm khác lấn át.
- **Độ tương phản:** Khi đặt trên nền tối (`#1C1D1A`), luôn giữ nền trắng/ngà bên trong khung squircle của logo để các chi tiết mầm cây và vật nuôi không bị chìm.

---

## 6. DANH SÁCH NHỮNG ĐIỀU CẤM KỴ (ANTI-PATTERNS)

- ❌ **Không** tự ý bóp méo tỉ lệ khung hình của logo (luôn giữ tỉ lệ 1:1).
- ❌ **Không** đổi màu hình bóng con vật sang các màu nóng gắt (như đỏ, tím neon).
- ❌ **Không** tách rời chiếc khiên ra khỏi mầm cây/vật nuôi khi dùng làm biểu tượng ứng dụng chính.
- ❌ **Không** gõ sai tên thương hiệu thành *Agrian* (viết thường toàn bộ) hoặc *AGRIAN* (in hoa toàn bộ). Quy chuẩn chuẩn duy nhất: **`AgriAn`**.

