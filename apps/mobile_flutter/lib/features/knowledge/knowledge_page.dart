import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';

class ArticleDetailPage extends StatefulWidget {
  const ArticleDetailPage({
    super.key,
    required this.apiClient,
    required this.articleId,
    required this.preview,
  });

  final ApiClient apiClient;
  final String articleId;
  final KnowledgeArticle preview;

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late KnowledgeArticle _article = widget.preview;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final article = await widget.apiClient.getArticle(widget.articleId);
      if (mounted) setState(() => _article = article);
    } catch (_) {
      // The preview remains available when article detail cannot be refreshed.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết kiến thức')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              _article.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (_article.sourceName != null)
              Text(
                'Nguồn: ${_article.sourceName}',
                style: const TextStyle(color: AppColors.mutedForeground),
              ),
            const SizedBox(height: 20),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Text(
              _article.content ??
                  _article.summary ??
                  'Nội dung đang được cập nhật.',
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 24),
            AppCard(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.info),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Thông tin chỉ mang tính tham khảo. Hãy hỏi chuyên gia khi tình huống nghiêm trọng.',
                      style: TextStyle(color: AppColors.info, height: 1.4),
                    ),
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

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  Domain? _filter;
  final _searchController = TextEditingController();
  List<_TaggedArticle> _articles = const [];
  bool _loading = true;
  String? _error;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), _loadArticles);
  }

  Future<void> _loadArticles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final domains = _filter == null ? Domain.values : [_filter!];
      final results = await Future.wait(
        domains.map(
          (domain) => widget.apiClient.getArticles(
            domain,
            query: _searchController.text,
          ),
        ),
      );
      if (!mounted) return;
      final seenArticleIds = <String>{};
      final articles = <_TaggedArticle>[];
      for (var index = 0; index < domains.length; index++) {
        for (final article in results[index]) {
          if (seenArticleIds.add(article.id)) {
            articles.add(
              _TaggedArticle(article: article, domain: domains[index]),
            );
          }
        }
      }
      setState(() => _articles = articles);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể tải kiến thức lúc này.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setFilter(Domain? filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _loadArticles();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    children: [
      Text(
        'Kiến thức',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      const Text(
        'Thông tin thực hành đáng tin cậy cho nông trại của bạn.',
        style: TextStyle(color: AppColors.mutedForeground),
      ),
      const SizedBox(height: 20),
      AppSearchField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        label: 'Tìm kiếm kiến thức',
        onClear: () {
          _searchController.clear();
          _loadArticles();
        },
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppFilterChip<Domain?>(
            label: 'Tất cả',
            icon: Icons.apps_outlined,
            selected: _filter == null,
            onSelected: (_) => _setFilter(null),
          ),
          AppFilterChip<Domain?>(
            label: Domain.plant.label,
            icon: Icons.eco_outlined,
            selected: _filter == Domain.plant,
            onSelected: (_) => _setFilter(Domain.plant),
          ),
          AppFilterChip<Domain?>(
            label: Domain.animal.label,
            icon: Icons.pets_outlined,
            selected: _filter == Domain.animal,
            onSelected: (_) => _setFilter(Domain.animal),
          ),
        ],
      ),
      const SizedBox(height: 24),
      AsyncStateView(
        state: _loading
            ? AsyncState.loading
            : _error != null
            ? AsyncState.error
            : _articles.isEmpty
            ? AsyncState.empty
            : AsyncState.content,
        errorMessage: _error ?? 'Chưa có bài viết phù hợp.',
        emptyTitle: 'Chưa có bài viết phù hợp',
        emptyMessage: 'Thử từ khóa khác hoặc thay đổi bộ lọc.',
        onRetry: _loadArticles,
        child: Column(
          children: _articles
              .map(
                (tagged) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ArticleDetailPage(
                          apiClient: widget.apiClient,
                          articleId: tagged.article.id,
                          preview: tagged.article,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusChip(
                                label: tagged.domain.label,
                                tone: StatusTone.neutral,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                tagged.article.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (tagged.article.summary != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  tagged.article.summary!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
}

class _TaggedArticle {
  const _TaggedArticle({required this.article, required this.domain});

  final KnowledgeArticle article;
  final Domain domain;
}
