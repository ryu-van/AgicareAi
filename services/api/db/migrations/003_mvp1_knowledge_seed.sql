-- Synthetic Vietnamese fixtures for the local MVP demo.
-- These records are not veterinary or agronomy advice and must not be presented as reviewed production content.

insert into public.subjects (id, domain, name, status) values
  ('chicken', 'animal', 'Gà', 'published'),
  ('pig', 'animal', 'Heo', 'published'),
  ('rice', 'plant', 'Lúa', 'published'),
  ('vegetables', 'plant', 'Rau', 'published')
on conflict (id) do update set domain = excluded.domain, name = excluded.name, status = excluded.status;

insert into public.knowledge_articles (
  id, domain, subject_id, title, summary, content, topic, source_name, status, published_at
) values
  ('10000000-0000-4000-8000-000000000001', 'animal', 'chicken', 'Theo dõi đàn gà bỏ ăn', 'Các bước quan sát ban đầu khi một số con gà giảm ăn.', 'Fixture tổng hợp: ghi nhận số con bỏ ăn, thời điểm bắt đầu, lượng nước uống và phân. Tách riêng con có biểu hiện nặng để theo dõi. Đây không phải kết luận bệnh.', 'observation', 'AgriGuard synthetic fixture', 'published', now()),
  ('10000000-0000-4000-8000-000000000002', 'animal', 'chicken', 'Kiểm tra chuồng gà hằng ngày', 'Danh sách kiểm tra thông thoáng, nước uống và vệ sinh.', 'Fixture tổng hợp: kiểm tra nước sạch, nền chuồng khô, mùi bất thường, mật độ nuôi và dấu hiệu ho hoặc khó thở. Nếu nhiều con cùng bất thường, cần liên hệ chuyên gia.', 'daily-care', 'AgriGuard synthetic fixture', 'published', now()),
  ('10000000-0000-4000-8000-000000000003', 'animal', 'pig', 'Theo dõi heo giảm ăn', 'Thông tin quan sát an toàn trước khi nhờ chuyên gia.', 'Fixture tổng hợp: ghi nhận nhiệt độ nếu có thiết bị phù hợp, lượng ăn, nước uống, phân và số cá thể có biểu hiện. Không tự dùng thuốc hoặc thay đổi liều khi chưa có hướng dẫn chuyên môn.', 'observation', 'AgriGuard synthetic fixture', 'published', now()),
  ('10000000-0000-4000-8000-000000000004', 'animal', 'pig', 'Vệ sinh khu nuôi heo', 'Các điểm cần kiểm tra trong khu vực nuôi.', 'Fixture tổng hợp: giữ nền khô, vệ sinh máng, kiểm tra thông gió và hạn chế người ra vào khi có nhiều con bất thường. Ghi lại diễn biến theo ngày để cung cấp cho chuyên gia.', 'daily-care', 'AgriGuard synthetic fixture', 'published', now()),
  ('20000000-0000-4000-8000-000000000001', 'plant', 'rice', 'Theo dõi ruộng lúa sau mưa', 'Các dấu hiệu cần ghi nhận sau thời tiết ẩm kéo dài.', 'Fixture tổng hợp: kiểm tra lá, thân, mặt ruộng và vùng có nước đọng. Chụp ảnh toàn cảnh lẫn cận cảnh để so sánh theo ngày. Chưa nên kết luận nguyên nhân chỉ từ một dấu hiệu.', 'field-observation', 'AgriGuard synthetic fixture', 'published', now()),
  ('20000000-0000-4000-8000-000000000002', 'plant', 'rice', 'Nhật ký chăm sóc lúa', 'Cách ghi nhật ký theo ngày để hỗ trợ quyết định chăm sóc.', 'Fixture tổng hợp: ghi ngày gieo, giai đoạn sinh trưởng, lượng nước, thời tiết, công việc đã làm và dấu hiệu bất thường. Nhật ký đều giúp chuyên gia đánh giá chính xác hơn.', 'record-keeping', 'AgriGuard synthetic fixture', 'published', now()),
  ('20000000-0000-4000-8000-000000000003', 'plant', 'vegetables', 'Kiểm tra luống rau hằng ngày', 'Các điểm quan sát cơ bản trên luống rau.', 'Fixture tổng hợp: kiểm tra mặt dưới lá, độ ẩm đất, lỗ thủng, cây héo và khu vực phát triển không đều. Ghi rõ vị trí và số cây bị ảnh hưởng trước khi xử lý.', 'field-observation', 'AgriGuard synthetic fixture', 'published', now()),
  ('20000000-0000-4000-8000-000000000004', 'plant', 'vegetables', 'Ghi nhận sâu hại trên rau', 'Cách ghi nhận dấu hiệu mà không vội kết luận.', 'Fixture tổng hợp: chụp ảnh rõ, ghi loại cây, tuổi luống, tỷ lệ cây có dấu hiệu và thời tiết gần đây. Không tự pha hoặc dùng thuốc khi chưa có hướng dẫn phù hợp.', 'safety', 'AgriGuard synthetic fixture', 'published', now())
on conflict (id) do update set
  domain = excluded.domain,
  subject_id = excluded.subject_id,
  title = excluded.title,
  summary = excluded.summary,
  content = excluded.content,
  topic = excluded.topic,
  source_name = excluded.source_name,
  status = excluded.status,
  published_at = excluded.published_at,
  updated_at = now();
