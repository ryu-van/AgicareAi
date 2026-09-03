# ADR-001: Modular monolith cho MVP

- Status: proposed
- Date: 2026-08-25
- Owner: Product/Engineering owner (cần chỉ định)

## Context

MVP cần dùng chung auth, chatbot, knowledge base, nhật ký và sync offline; team, traffic và ownership chưa được xác định. Hệ thống có rủi ro AI/pháp lý nên cần rollback nhanh và ít điểm vận hành.

## Decision

Dùng một FastAPI modular monolith với các module độc lập: `identity`, `chat`, `knowledge`, `journal`, `diagnosis`, `expert-escalation`. PostgreSQL là source of truth; mobile giữ outbox cục bộ cho dữ liệu chưa sync.

## Alternatives

- Microservices: loại vì tăng operational burden, network failure và chi phí khi chưa có scale/ownership chứng minh.
- Chỉ gọi trực tiếp Supabase từ mobile: loại vì policy AI, secret, citation và idempotency cần server boundary.

## Consequences

Đổi module nhanh và deploy đơn giản; đổi lại API là một failure domain. Khi có module cần scale/ownership riêng, tách qua port/API sau khi có số liệu.

## Rollback/revisit

Có thể tắt feature flag diagnosis hoặc thay provider mà không đổi mobile contract. Xem xét tách service khi có bằng chứng về tải, SLA, team ownership hoặc isolation requirement.
