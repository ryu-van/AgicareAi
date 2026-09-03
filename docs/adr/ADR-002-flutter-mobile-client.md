# ADR-002: Chuyển mobile client sang Flutter/Dart cho Android

- Status: Accepted and implemented
- Date: 2026-08-30
- Scope: `apps/mobile_flutter` Android client
- Owners: Chưa chỉ định

## Context

AgriCare cần một ứng dụng Android cho nông hộ Việt Nam. Backend FastAPI, API
contract và dữ liệu local demo hoạt động độc lập với client mobile.

## Decision

Sử dụng Flutter/Dart tại `apps/mobile_flutter`, với Android là nền tảng duy
nhất của giai đoạn MVP. Giữ nguyên FastAPI, database, API contract và safety
rules. Các thư mục iOS, web và desktop không nằm trong phạm vi repository.

```text
Flutter Android client
        |
        | HTTP + bearer auth + idempotency keys
        v
FastAPI modular monolith
        |
        v
SQLite local / PostgreSQL-Supabase target
```

## Consequences

- CI chỉ xác minh Android APK, Android emulator và API.
- Release process chỉ yêu cầu Android signing/AAB.
- API contract không thay đổi chỉ để thuận tiện cho Flutter.
- Có thể bổ sung nền tảng khác sau bằng `flutter create --platforms=<target>`
  khi có quyết định sản phẩm và kế hoạch kiểm thử riêng.

## Revisit trigger

Xem xét lại khi pilot Android chứng minh cần một nền tảng bổ sung, có owner và
ngân sách kiểm thử/phát hành cho nền tảng đó.
