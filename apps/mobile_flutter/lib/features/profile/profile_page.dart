import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_components.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Profile? _profile;
  final _nameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await widget.apiClient.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _nameController.text = profile.displayName ?? '';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể tải hồ sơ lúc này.');
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
      final profile = await widget.apiClient.updateProfile(name);
      if (mounted) {
        setState(() => _profile = profile);
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    children: [
      Text(
        'Hồ sơ',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 24),
      Center(
        child: CircleAvatar(
          radius: 38,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            (_profile?.displayName ?? 'A').substring(0, 1).toUpperCase(),
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
        child: Text(
          _profile?.displayName ?? 'Người dùng AgriCare',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 28),
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
    ],
  );
}
