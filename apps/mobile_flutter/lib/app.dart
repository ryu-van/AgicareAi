import 'package:flutter/material.dart';

import 'core/auth/auth_service.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/chat/chat_page.dart';
import 'features/diagnosis/diagnosis_page.dart';
import 'features/farm/farm_page.dart';
import 'features/home/home_page.dart';
import 'features/journal/journal_page.dart';
import 'features/knowledge/knowledge_page.dart';
import 'features/profile/profile_page.dart';
import 'features/reminders/reminders_page.dart';
import 'features/sync/sync_page.dart';
import 'shared/widgets/app_components.dart';
import 'shared/widgets/domain_picker.dart';
import 'shared/widgets/error_page.dart';

typedef AgriAnApp = AgriCareApp;

class AgriCareApp extends StatefulWidget {
  AgriCareApp({
    super.key,
    ApiClient? apiClient,
    AuthService? authService,
    this.initialRoute,
    this.requireAuth,
  })  : authService = authService ?? apiClient?.authService,
        apiClient = apiClient ??
            ApiClient(authService: authService ?? apiClient?.authService);

  final ApiClient apiClient;
  final AuthService? authService;
  final String? initialRoute;
  final bool? requireAuth;

  @override
  State<AgriCareApp> createState() => _AgriCareAppState();
}

class _AgriCareAppState extends State<AgriCareApp> {
  @override
  void initState() {
    super.initState();
    widget.authService?.addListener(_onAuthStateChanged);
  }

  @override
  void didUpdateWidget(AgriCareApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authService != widget.authService) {
      oldWidget.authService?.removeListener(_onAuthStateChanged);
      widget.authService?.addListener(_onAuthStateChanged);
    }
  }

  @override
  void dispose() {
    widget.authService?.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) setState(() {});
  }

  bool get _shouldShowLogin {
    if (widget.requireAuth == false) return false;
    final service = widget.authService;
    if (service != null) {
      return service.state.isUnauthenticated;
    }
    return widget.requireAuth == true;
  }

  @override
  Widget build(BuildContext context) {
    final normalizedInitialRoute = _normalizeRoute(widget.initialRoute);
    final hasValidInitialRoute = _isSupportedRoute(normalizedInitialRoute);

    final effectiveHome = _shouldShowLogin
        ? LoginPage(
            apiClient: widget.apiClient,
            authService: widget.authService,
          )
        : _HomeShell(
            apiClient: widget.apiClient,
            authService: widget.authService,
          );

    return MaterialApp(
      title: 'AgriAn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: widget.initialRoute == null ? null : normalizedInitialRoute,
      routes: {
        '/login': (_) => LoginPage(
              apiClient: widget.apiClient,
              authService: widget.authService,
            ),
        '/register': (_) => RegisterPage(
              apiClient: widget.apiClient,
              authService: widget.authService,
            ),
        '/chat': (_) => ChatPage(apiClient: widget.apiClient, domain: Domain.plant),
        '/farm': (_) => FarmPage(apiClient: widget.apiClient),
        '/diagnosis': (_) => DiagnosisPage(apiClient: widget.apiClient),
        '/journal': (_) => JournalPage(apiClient: widget.apiClient),
        '/reminders': (_) => RemindersPage(apiClient: widget.apiClient),
        '/sync': (_) => SyncPage(apiClient: widget.apiClient),
        '/errors/401': (_) => const ErrorPage.unauthenticated(),
        '/errors/403': (_) => const ErrorPage.forbidden(),
        '/errors/500': (_) => const ErrorPage.serverError(),
        '/errors/offline': (_) => const ErrorPage.offline(),
      },
      onGenerateRoute: (settings) {
        final route = _normalizeRoute(settings.name);
        if (route == '/login') {
          return MaterialPageRoute(
            builder: (_) => LoginPage(
              apiClient: widget.apiClient,
              authService: widget.authService,
            ),
          );
        }
        if (route == '/register') {
          return MaterialPageRoute(
            builder: (_) => RegisterPage(
              apiClient: widget.apiClient,
              authService: widget.authService,
            ),
          );
        }
        if (route == '/chat') {
          return MaterialPageRoute(
            builder: (_) =>
                ChatPage(apiClient: widget.apiClient, domain: Domain.plant),
          );
        }
        if (route == '/farm') {
          return MaterialPageRoute(
            builder: (_) => FarmPage(apiClient: widget.apiClient),
          );
        }
        if (route == '/diagnosis') {
          return MaterialPageRoute(
            builder: (_) => DiagnosisPage(apiClient: widget.apiClient),
          );
        }
        if (route == '/journal') {
          return MaterialPageRoute(
            builder: (_) => JournalPage(apiClient: widget.apiClient),
          );
        }
        if (route == '/reminders') {
          return MaterialPageRoute(
            builder: (_) => RemindersPage(apiClient: widget.apiClient),
          );
        }
        if (route == '/sync') {
          return MaterialPageRoute(
            builder: (_) => SyncPage(apiClient: widget.apiClient),
          );
        }
        final segments = Uri.tryParse(route)?.pathSegments ?? const <String>[];
        if (segments.length == 2 && segments.first == 'knowledge') {
          final articleId = segments.last;
          return MaterialPageRoute(
            builder: (_) => ArticleDetailPage(
              apiClient: widget.apiClient,
              articleId: articleId,
              preview: KnowledgeArticle(
                id: articleId,
                domain: Domain.plant,
                title: 'Kiến thức AgriAn',
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (context) => ErrorPage.notFound(
            onPrimaryAction: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => effectiveHome,
              ),
              (_) => false,
            ),
          ),
        );
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (context) => ErrorPage.notFound(
          onPrimaryAction: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => effectiveHome,
            ),
            (_) => false,
          ),
        ),
      ),
      home: hasValidInitialRoute ? null : effectiveHome,
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
        : uri.host == 'login'
        ? '/login'
        : uri.host == 'register'
        ? '/register'
        : path.isEmpty
        ? '/'
        : path;
  }
  return uri.path.isEmpty ? '/' : uri.path;
}

bool _isSupportedRoute(String route) {
  if ([
    '/chat',
    '/farm',
    '/diagnosis',
    '/journal',
    '/reminders',
    '/sync',
    '/login',
    '/register',
  ].contains(route)) {
    return true;
  }
  final segments = Uri.tryParse(route)?.pathSegments ?? const <String>[];
  return segments.length == 2 && segments.first == 'knowledge';
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({
    required this.apiClient,
    this.authService,
  });

  final ApiClient apiClient;
  final AuthService? authService;

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
            ProfilePage(
              apiClient: widget.apiClient,
              authService: widget.authService,
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppFloatingCenterNavShell(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        onCenterTap: _startChat,
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
