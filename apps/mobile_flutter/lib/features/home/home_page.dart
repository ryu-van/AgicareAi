import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';
import '../../widgets/domain_picker.dart';
import '../chat/chat_page.dart';
import '../knowledge/knowledge_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Profile? _profile;
  List<_TaggedArticle> _articles = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.apiClient.getProfile(),
        widget.apiClient.getArticles(Domain.plant),
        widget.apiClient.getArticles(Domain.animal),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Profile;
        _articles = [
          for (final article in results[1] as List<KnowledgeArticle>)
            _TaggedArticle(article: article, domain: Domain.plant),
          for (final article in results[2] as List<KnowledgeArticle>)
            _TaggedArticle(article: article, domain: Domain.animal),
        ];
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể tải dữ liệu lúc này.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startChat() async {
    final domain = await showDomainPicker(context);
    if (!mounted || domain == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(apiClient: widget.apiClient, domain: domain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.displayName;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AgriCare AI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryPressed,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name == null ? 'Xin chào' : 'Xin chào, $name',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  tooltip: 'Thông báo',
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Hỏi chuyên gia về vấn đề của bạn',
            icon: Icons.chat_bubble_outline_rounded,
            onPressed: _startChat,
          ),
          const SizedBox(height: 16),
          const _HeroCard(),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Bạn muốn làm gì hôm nay?'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              FeatureCard(
                icon: Icons.camera_alt_outlined,
                title: 'Chẩn đoán',
                subtitle: 'Phân tích hình ảnh',
                status: 'Sắp có',
                onTap: _startChat,
              ),
              FeatureCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Hỏi AI',
                subtitle: 'Nhận tư vấn nhanh',
                status: 'Sắp có',
                onTap: _startChat,
              ),
              FeatureCard(
                icon: Icons.menu_book_outlined,
                title: 'Sổ tay Nông nghiệp',
                subtitle: 'Tra cứu dịch hại',
                status: 'Khuyên dùng',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KnowledgePage(apiClient: widget.apiClient),
                  ),
                ),
              ),
              const FeatureCard(
                icon: Icons.wb_sunny_outlined,
                title: 'Dự báo Mùa vụ',
                subtitle: 'Thời tiết & Cảnh báo',
                status: 'Trực tuyến',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.info,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mẹo hôm nay\nTheo dõi đều đặn cây trồng và vật nuôi để phát hiện dấu hiệu bất thường sớm.',
                    style: TextStyle(
                      color: AppColors.info,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Kiến thức mới nhất'),
          const SizedBox(height: 12),
          AsyncStateView(
            state: _loading
                ? AsyncState.loading
                : _error != null
                ? AsyncState.error
                : _articles.isEmpty
                ? AsyncState.empty
                : AsyncState.content,
            errorMessage:
                _error ?? 'Kết nối API để xem bài viết phù hợp với bạn.',
            emptyTitle: 'Chưa có kiến thức mới',
            emptyMessage: 'Hãy thử lại sau hoặc mở mục Kiến thức để tìm kiếm.',
            onRetry: _loadData,
            child: Column(
              children: _articles
                  .map(
                    (tagged) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ArticleCard(
                        tagged: tagged,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ArticleDetailPage(
                              apiClient: widget.apiClient,
                              articleId: tagged.article.id,
                              preview: tagged.article,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Thông tin chỉ mang tính tham khảo. Với tình huống khẩn cấp, hãy liên hệ chuyên gia.',
            style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFE8F5D6), Color(0xFFF5F7F0)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
    ),
    child: const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nông trại của bạn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryPressed,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Theo dõi sức khỏe và nhận gợi ý chăm sóc mỗi ngày.',
                style: TextStyle(color: AppColors.mutedForeground, height: 1.4),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        _FarmIcon(),
      ],
    ),
  );
}

class _FarmIcon extends StatelessWidget {
  const _FarmIcon();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: const Icon(
      Icons.agriculture_rounded,
      size: 40,
      color: AppColors.primary,
    ),
  );
}

class _TaggedArticle {
  const _TaggedArticle({required this.article, required this.domain});

  final KnowledgeArticle article;
  final Domain domain;
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.tagged, required this.onTap});

  final _TaggedArticle tagged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    onTap: onTap,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusChip(label: tagged.domain.label, tone: StatusTone.neutral),
              const SizedBox(height: AppSpacing.sm),
              Text(
                tagged.article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (tagged.article.summary != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  tagged.article.summary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.mutedForeground,
        ),
      ],
    ),
  );
}
