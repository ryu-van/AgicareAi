# ADR-002: Chuyển mobile client sang Flutter/Dart

- Status: Accepted and implemented
- Date: 2026-08-30
- Scope: `apps/mobile_flutter` mobile client
- Owners: Chưa chỉ định

## Context

AgriCare hiện có mobile client dùng Expo, React Native, TypeScript và Expo Router. Backend FastAPI, API contract và dữ liệu local demo đang hoạt động độc lập với framework mobile.

Team muốn chuyển mobile client sang Flutter/Dart để có một UI toolkit mobile chuyên biệt, kiểm soát visual consistency tốt hơn và không phụ thuộc Expo Go.

## Decision

Chuyển mobile client sang Flutter tại `apps/mobile_flutter`. Giữ nguyên FastAPI, database, API contract và các safety rules. Rollback dùng Flutter release artifact trước đó.

Target architecture:

```text
Flutter/Dart mobile client
        |
        | HTTP + bearer auth + idempotency keys
        v
FastAPI modular monolith
        |
        v
SQLite local / PostgreSQL-Supabase target
```

## Alternatives considered

### Continue with Expo

Giữ nguyên code và giảm migration cost. Không được chọn vì team muốn chuyển khỏi Expo/Expo Go và cần đánh giá lại mobile UI foundation.

### React Native CLI

Giữ TypeScript/React nhưng tự quản lý nhiều native tooling hơn. Không được chọn vì không giải quyết mục tiêu chuyển sang một mobile UI toolkit khác.

### Flutter/Dart

Được chọn. Chi phí là phải rewrite mobile UI/state/client integration, nhưng backend và API boundary được giữ nguyên.

## Consequences

- Mobile client chính thức là Flutter; migration checklist tiếp tục theo dõi release evidence.
- Rollback dùng Flutter release artifact trước đó.
- Team cần cài Flutter/Dart, Android toolchain và toolchain iOS trên macOS/CI.
- API contract không được thay đổi chỉ để thuận tiện cho Flutter.
- Bản Expo/React Native cũ đã được xoá sau khi hoàn tất migration cleanup.

## Revisit trigger

Xem xét lại quyết định nếu Flutter migration không đạt parity trong milestone đã thống nhất, thiếu năng lực build iOS, hoặc native dependency bắt buộc chỉ hỗ trợ tốt trên React Native.
