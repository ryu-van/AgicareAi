import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';
import '../../shared/widgets/domain_picker.dart';
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
        widget.apiClient.getArticles(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Profile;
        _articles = [
          for (final article in results[1] as List<KnowledgeArticle>)
            _TaggedArticle(article: article, domain: article.domain),
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
              const AppBrandLogo(size: BrandLogoSize.medium),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AgriAn',
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
                    LucideIcons.bell,
                    color: AppColors.foreground,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ConsultationHeroCard(onTap: _startChat),
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
            childAspectRatio: 1.35,
            children: [
              FeatureCard(
                icon: LucideIcons.scanLine,
                title: 'Chẩn đoán',
                subtitle: 'Phân tích hình ảnh',
                status: 'Sắp có',
                iconColor: AppColors.primary,
                iconBackgroundColor: AppColors.primaryLight,
                statusTone: StatusTone.success,
                onTap: _startChat,
              ),
              FeatureCard(
                icon: LucideIcons.messageSquare,
                title: 'Hỏi AI',
                subtitle: 'Nhận tư vấn nhanh',
                status: 'Sắp có',
                iconColor: AppColors.techBlue,
                iconBackgroundColor: AppColors.techBlueLight,
                statusTone: StatusTone.info,
                onTap: _startChat,
              ),
              FeatureCard(
                icon: LucideIcons.bookOpen,
                title: 'Sổ tay Nông nghiệp',
                subtitle: 'Tra cứu dịch hại',
                status: 'Khuyên dùng',
                iconColor: AppColors.harvestGoldDark,
                iconBackgroundColor: AppColors.harvestGoldLight,
                statusTone: StatusTone.warning,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KnowledgePage(apiClient: widget.apiClient),
                  ),
                ),
              ),
              const FeatureCard(
                icon: LucideIcons.sun,
                title: 'Dự báo Mùa vụ',
                subtitle: 'Thời tiết & Cảnh báo',
                status: 'Trực tuyến',
                iconColor: AppColors.sunAmber,
                iconBackgroundColor: AppColors.sunAmberLight,
                statusTone: StatusTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.harvestGoldLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.harvestGold.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.lightbulb,
                  color: AppColors.harvestGoldDark,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mẹo hôm nay',
                        style: TextStyle(
                          color: AppColors.harvestGoldDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Theo dõi đều đặn cây trồng và vật nuôi để phát hiện dấu hiệu bất thường sớm.',
                        style: TextStyle(
                          color: Color(0xFF6B4D00),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
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

class _ConsultationHeroCard extends StatelessWidget {
  const _ConsultationHeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFEFDF7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.harvestGold.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.harvestGold.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.harvestGoldLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.harvestGold.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                LucideIcons.messageSquare,
                color: AppColors.harvestGoldDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hỏi chuyên gia về vấn đề của bạn',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tư vấn kỹ thuật cây trồng & vật nuôi',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.softFloating(
                  shadowColor: AppColors.primary,
                  opacity: 0.25,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hỏi ngay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    LucideIcons.arrowRight,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFFAFBF7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2E7DD), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Đang phát triển tốt',
                      style: TextStyle(
                        color: AppColors.primaryPressed,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nông trại của bạn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Theo dõi sức khỏe và nhận gợi ý chăm sóc mỗi ngày.',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _FarmIcon(),
      ],
    ),
  );
}

class _FarmIcon extends StatelessWidget {
  const _FarmIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    height: 54,
    decoration: BoxDecoration(
      color: AppColors.harvestGoldLight,
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.harvestGold.withValues(alpha: 0.3),
        width: 1.5,
      ),
    ),
    child: const Icon(
      LucideIcons.sprout,
      color: AppColors.harvestGoldDark,
      size: 26,
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
          LucideIcons.chevronRight,
          size: 18,
          color: AppColors.mutedForeground,
        ),
      ],
    ),
  );
}
