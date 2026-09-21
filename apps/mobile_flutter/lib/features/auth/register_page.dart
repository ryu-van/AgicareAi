import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.apiClient,
    this.authService,
    this.onRegisterSuccess,
  });

  final ApiClient apiClient;
  final AuthService? authService;
  final VoidCallback? onRegisterSuccess;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Lựa chọn lĩnh vực canh tác
  Domain _selectedDomain = Domain.plant;

  AuthService get _effectiveAuthService =>
      widget.authService ?? widget.apiClient.authService ?? AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _phoneController.text.trim();
      final name = _nameController.text.trim();
      final password = _passwordController.text;

      await _effectiveAuthService.register(
        identifier: phone,
        password: password,
        displayName: name,
        phone: phone,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo tài khoản thành công! Chào mừng bà con đến với AgriAn.'),
          backgroundColor: AppColors.primary,
        ),
      );

      if (widget.onRegisterSuccess != null) {
        widget.onRegisterSuccess!();
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thông tin cá nhân & canh tác',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryPressed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Giúp AgriAn cung cấp tư vấn phù hợp nhất cho bà con',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Họ tên
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            enabled: !_isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Họ và tên của bạn',
                              hintText: 'VD: Nguyễn Văn An',
                              prefixIcon: Icon(LucideIcons.user, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập họ và tên';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Số điện thoại
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            enabled: !_isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Số điện thoại',
                              hintText: 'VD: 0912345678',
                              prefixIcon: Icon(LucideIcons.phone, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập số điện thoại';
                              }
                              final digits = value.replaceAll(RegExp(r'\D'), '');
                              if (digits.length < 9 || digits.length > 11) {
                                return 'Số điện thoại không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Mật khẩu
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              hintText: 'Tối thiểu 6 ký tự',
                              prefixIcon: const Icon(LucideIcons.lock, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  size: 20,
                                ),
                                tooltip: _obscurePassword
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu';
                              }
                              if (value.length < 6) {
                                return 'Mật khẩu phải có ít nhất 6 ký tự';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Xác nhận mật khẩu
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            enabled: !_isLoading,
                            onFieldSubmitted: (_) => _handleRegister(),
                            decoration: InputDecoration(
                              labelText: 'Xác nhận mật khẩu',
                              prefixIcon: const Icon(LucideIcons.shieldCheck, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  size: 20,
                                ),
                                tooltip: _obscureConfirmPassword
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng xác nhận mật khẩu';
                              }
                              if (value != _passwordController.text) {
                                return 'Mật khẩu xác nhận không trùng khớp';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Nhánh canh tác quan tâm
                          const Text(
                            'Lĩnh vực canh tác quan tâm chính:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() {
                                    _selectedDomain = Domain.plant;
                                  }),
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedDomain == Domain.plant
                                          ? AppColors.primaryLight
                                          : theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(AppRadii.md),
                                      border: Border.all(
                                        color: _selectedDomain == Domain.plant
                                            ? AppColors.primary
                                            : Colors.grey.shade300,
                                        width: _selectedDomain == Domain.plant ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.sprout,
                                          size: 18,
                                          color: _selectedDomain == Domain.plant
                                              ? AppColors.primaryPressed
                                              : AppColors.mutedForeground,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Cây trồng',
                                          style: TextStyle(
                                            fontWeight: _selectedDomain == Domain.plant
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                            color: _selectedDomain == Domain.plant
                                                ? AppColors.primaryPressed
                                                : AppColors.foreground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() {
                                    _selectedDomain = Domain.animal;
                                  }),
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedDomain == Domain.animal
                                          ? AppColors.primaryLight
                                          : theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(AppRadii.md),
                                      border: Border.all(
                                        color: _selectedDomain == Domain.animal
                                            ? AppColors.primary
                                            : Colors.grey.shade300,
                                        width: _selectedDomain == Domain.animal ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.beef,
                                          size: 18,
                                          color: _selectedDomain == Domain.animal
                                              ? AppColors.primaryPressed
                                              : AppColors.mutedForeground,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Vật nuôi',
                                          style: TextStyle(
                                            fontWeight: _selectedDomain == Domain.animal
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                            color: _selectedDomain == Domain.animal
                                                ? AppColors.primaryPressed
                                                : AppColors.foreground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Error message
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadii.md),
                                border: Border.all(
                                  color: AppColors.danger.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.alertCircle,
                                    color: AppColors.danger,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Nút Tạo tài khoản
                          AppPrimaryButton(
                            label: 'Tạo tài khoản',
                            loading: _isLoading,
                            icon: LucideIcons.userPlus,
                            onPressed: _isLoading ? null : _handleRegister,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Đã có tài khoản
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text(
                          'Đã có tài khoản? Quay lại Đăng nhập',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryPressed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
