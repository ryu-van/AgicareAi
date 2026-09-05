import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'features/chat/chat_page.dart';
import 'features/diagnosis/diagnosis_page.dart';
import 'features/farm/farm_page.dart';
import 'features/home/home_page.dart';
import 'features/journal/journal_page.dart';
import 'features/knowledge/knowledge_page.dart';
import 'features/profile/profile_page.dart';
import 'features/reminders/reminders_page.dart';
import 'features/sync/sync_page.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_components.dart';
import 'shared/widgets/domain_picker.dart';

class AgriCareApp extends StatelessWidget {
  AgriCareApp({super.key, ApiClient? apiClient, this.initialRoute})
    : apiClient = apiClient ?? ApiClient();
  final ApiClient apiClient;
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    final normalizedInitialRoute = _normalizeRoute(initialRoute);
    final hasValidInitialRoute = _isSupportedRoute(normalizedInitialRoute);
    return MaterialApp(
      title: 'AgriCare AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: hasValidInitialRoute ? normalizedInitialRoute : null,
      routes: {
        '/chat': (_) => ChatPage(apiClient: apiClient, domain: Domain.plant),
        '/farm': (_) => FarmPage(apiClient: apiClient),
        '/diagnosis': (_) => DiagnosisPage(apiClient: apiClient),
        '/journal': (_) => JournalPage(apiClient: apiClient),
        '/reminders': (_) => RemindersPage(apiClient: apiClient),
        '/sync': (_) => SyncPage(apiClient: apiClient),
      },
      onGenerateRoute: (settings) {
        final route = _normalizeRoute(settings.name);
        if (route == '/chat') {
          return MaterialPageRoute(
            builder: (_) =>
                ChatPage(apiClient: apiClient, domain: Domain.plant),
          );
        }
        if (route == '/farm') {
          return MaterialPageRoute(builder: (_) => FarmPage(apiClient: apiClient));
        }
        if (route == '/diagnosis') {
          return MaterialPageRoute(builder: (_) => DiagnosisPage(apiClient: apiClient));
        }
        if (route == '/journal') {
          return MaterialPageRoute(builder: (_) => JournalPage(apiClient: apiClient));
        }
        if (route == '/reminders') {
          return MaterialPageRoute(builder: (_) => RemindersPage(apiClient: apiClient));
        }
        if (route == '/sync') {
          return MaterialPageRoute(builder: (_) => SyncPage(apiClient: apiClient));
        }
        final segments = Uri.tryParse(route)?.pathSegments ?? const <String>[];
        if (segments.length == 2 && segments.first == 'knowledge') {
          final articleId = segments.last;
          return MaterialPageRoute(
            builder: (_) => ArticleDetailPage(
              apiClient: apiClient,
              articleId: articleId,
              preview: KnowledgeArticle(
                id: articleId,
                domain: Domain.plant,
                title: 'Kiến thức AgriCare',
              ),
            ),
          );
        }
        return null;
      },
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => _HomeShell(apiClient: apiClient)),
      home: hasValidInitialRoute ? null : _HomeShell(apiClient: apiClient),
    );
  }
}

String _normalizeRoute(String? name) {
  final uri = Uri.tryParse(name ?? '');
  if (uri == null) return '/';
  if (uri.scheme == 'agricare-ai') {
    final path = uri.pathSegments.isEmpty
        ? ''
        : '/${uri.pathSegments.join('/')}';
    return uri.host == 'chat'
        ? '/chat'
        : uri.host == 'knowledge'
        ? '/knowledge$path'
        : uri.host == 'farm'
        ? '/farm'
        : uri.host == 'diagnosis'
        ? '/diagnosis'
        : uri.host == 'journal'
        ? '/journal'
        : uri.host == 'reminders'
        ? '/reminders'
        : uri.host == 'sync'
        ? '/sync'
        : path.isEmpty
        ? '/'
        : path;
  }
  return uri.path.isEmpty ? '/' : uri.path;
}

bool _isSupportedRoute(String route) {
  if (['/chat', '/farm', '/diagnosis', '/journal', '/reminders', '/sync'].contains(route)) {
    return true;
  }
  final segments = Uri.tryParse(route)?.pathSegments ?? const <String>[];
  return segments.length == 2 && segments.first == 'knowledge';
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({required this.apiClient});
  final ApiClient apiClient;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(apiClient: widget.apiClient),
            KnowledgePage(apiClient: widget.apiClient),
            ChatPage(apiClient: widget.apiClient, domain: Domain.plant),
            ProfilePage(apiClient: widget.apiClient),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: AppFloatingCenterNavShell(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          onCenterTap: _startChat,
        ),
      ),
    );
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
}
