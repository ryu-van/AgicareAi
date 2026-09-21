import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.apiClient,
    this.authService,
  });

  final ApiClient apiClient;
  final AuthService? authService;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Profile? _profile;
  final _nameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  AuthService? get _authService =>
      widget.authService ?? widget.apiClient.authService;

  @override
  void initState() {
    super.initState();
    _authService?.addListener(_onAuthChanged);
    _loadProfile();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authService?.removeListener(_onAuthChanged);
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await widget.apiClient.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _nameController.text = profile.displayName ??
              _authService?.currentDisplayName ??
              '';
        });
      }
    } catch (_) {
      if (mounted) {
        final localName = _authService?.currentDisplayName ?? '';
        if (localName.isNotEmpty) {
          _nameController.text = localName;
        }
        setState(() {
          // In guest mode or offline, don't show fatal error
          if (_authService?.isGuest != true) {
            _error = 'Không thể tải hồ sơ lúc này.';
          }
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (_saving) return;
    if (name.isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên hiển thị.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      Profile? updatedProfile;
      try {
        updatedProfile = await widget.apiClient.updateProfile(name);
      } catch (_) {
        // Fallback for offline/guest or mock
      }

      await _authService?.updateDisplayName(name);

      if (mounted) {
        setState(() {
          _profile = updatedProfile ?? Profile(displayName: name);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể lưu hồ sơ. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Xác nhận đăng xuất',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi AgriAn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = _authService;
      if (service != null) {
        await service.logout();
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            apiClient: widget.apiClient,
            authService: service,
          ),
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = _authService;
    final isGuest = service?.isGuest ?? false;
    final effectiveDisplayName = _profile?.displayName?.isNotEmpty == true
        ? _profile!.displayName!
        : (service?.currentDisplayName?.isNotEmpty == true
            ? service!.currentDisplayName!
            : (isGuest ? 'Bà con (Khách)' : 'Người dùng AgriAn'));
    final phone = service?.currentPhone;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'Hồ sơ',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),

        // Guest Banner
        if (isGuest) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.harvestGoldLight,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: AppColors.harvestGold.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      LucideIcons.cloudOff,
                      color: AppColors.primaryPressed,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Chế độ dùng thử ngoại tuyến',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.primaryPressed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Đăng nhập để đồng bộ dữ liệu nhật ký của bạn và nhận hỗ trợ từ chuyên gia AI.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoginPage(
                          apiClient: widget.apiClient,
                          authService: service,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.logIn, size: 16),
                  label: const Text(
                    'Đăng nhập ngay',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        Center(
          child: CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              effectiveDisplayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryPressed,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Text(
                effectiveDisplayName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
              ),
              if (phone != null && phone.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.phone),
                  title: const Text('Số điện thoại liên kết'),
                  subtitle: Text(phone),
                ),
              ],
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.language_rounded),
                title: Text('Ngôn ngữ'),
                subtitle: Text('Tiếng Việt (vi-VN)'),
              ),
            ],
          ),
        ),

        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.warning),
            ),
          ),
        const SizedBox(height: 16),

        AppPrimaryButton(
          label: 'Lưu thay đổi',
          onPressed: _saving ? null : _saveProfile,
          icon: _saving ? Icons.hourglass_top_rounded : Icons.save_outlined,
          loading: _saving,
        ),

        const SizedBox(height: 20),

        // Nút Đăng xuất
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: BorderSide(
              color: AppColors.danger.withValues(alpha: 0.5),
              width: 1.2,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
          ),
          onPressed: _confirmLogout,
          icon: const Icon(LucideIcons.logOut, size: 18),
          label: Text(
            isGuest ? 'Thoát chế độ khách' : 'Đăng xuất tài khoản',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              const AppBrandLogo(size: BrandLogoSize.medium),
              const SizedBox(height: 8),
              const Text(
                'AgriAn',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.primaryPressed,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Vụ mùa an tâm, nông gia thịnh vượng',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Phiên bản 0.1.0-dev',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
