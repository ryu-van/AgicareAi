import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppErrorType { unauthenticated, forbidden, notFound, serverError, offline }

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.type, this.onPrimaryAction});

  const ErrorPage.unauthenticated({Key? key, VoidCallback? onPrimaryAction})
    : this(
        key: key,
        type: AppErrorType.unauthenticated,
        onPrimaryAction: onPrimaryAction,
      );

  const ErrorPage.forbidden({Key? key, VoidCallback? onPrimaryAction})
    : this(
        key: key,
        type: AppErrorType.forbidden,
        onPrimaryAction: onPrimaryAction,
      );

  const ErrorPage.notFound({Key? key, VoidCallback? onPrimaryAction})
    : this(
        key: key,
        type: AppErrorType.notFound,
        onPrimaryAction: onPrimaryAction,
      );

  const ErrorPage.serverError({Key? key, VoidCallback? onPrimaryAction})
    : this(
        key: key,
        type: AppErrorType.serverError,
        onPrimaryAction: onPrimaryAction,
      );

  const ErrorPage.offline({Key? key, VoidCallback? onPrimaryAction})
    : this(
        key: key,
        type: AppErrorType.offline,
        onPrimaryAction: onPrimaryAction,
      );

  final AppErrorType type;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final specification = _ErrorSpecification.forType(type);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final illustration = Semantics(
      image: true,
      label: specification.illustrationLabel,
      child: ExcludeSemantics(
        child: SvgPicture.string(
          _svgIllustration(specification),
          width: 208,
          height: 168,
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (reduceMotion)
                    illustration
                  else
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 480),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) => Opacity(
                        opacity: value.clamp(0, 1),
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 10),
                          child: Transform.scale(
                            scale: .88 + (.12 * value),
                            child: child,
                          ),
                        ),
                      ),
                      child: illustration,
                    ),
                  const SizedBox(height: 28),
                  Text(
                    specification.code,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: specification.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    specification.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    specification.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed:
                        onPrimaryAction ??
                        () => Navigator.of(context).maybePop(),
                    icon: Icon(specification.icon),
                    label: Text(specification.actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorSpecification {
  const _ErrorSpecification({
    required this.code,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.illustrationLabel,
    required this.color,
    required this.icon,
  });

  final String code;
  final String title;
  final String message;
  final String actionLabel;
  final String illustrationLabel;
  final Color color;
  final IconData icon;

  static _ErrorSpecification forType(AppErrorType type) => switch (type) {
    AppErrorType.unauthenticated => const _ErrorSpecification(
      code: '401',
      title: 'Phiên đăng nhập đã hết hạn',
      message: 'Hãy đăng nhập lại để tiếp tục sử dụng AgriAn.',
      actionLabel: 'Đăng nhập lại',
      illustrationLabel: 'Minh họa lỗi 401',
      color: Color(0xFFF57C00),
      icon: Icons.login_rounded,
    ),
    AppErrorType.forbidden => const _ErrorSpecification(
      code: '403',
      title: 'Bạn không có quyền truy cập',
      message: 'Khu vực này chỉ dành cho tài khoản được cấp quyền.',
      actionLabel: 'Quay lại',
      illustrationLabel: 'Minh họa lỗi 403',
      color: Color(0xFFC62828),
      icon: Icons.arrow_back_rounded,
    ),
    AppErrorType.notFound => const _ErrorSpecification(
      code: '404',
      title: 'Không tìm thấy trang này',
      message: 'Đường dẫn có thể đã thay đổi hoặc không còn tồn tại.',
      actionLabel: 'Về trang chủ',
      illustrationLabel: 'Minh họa lỗi 404',
      color: Color(0xFF2E7D32),
      icon: Icons.home_rounded,
    ),
    AppErrorType.serverError => const _ErrorSpecification(
      code: '500',
      title: 'Máy chủ đang gặp sự cố',
      message: 'Dữ liệu của bạn vẫn an toàn. Vui lòng thử lại sau ít phút.',
      actionLabel: 'Thử lại',
      illustrationLabel: 'Minh họa lỗi 500',
      color: Color(0xFF6A1B9A),
      icon: Icons.refresh_rounded,
    ),
    AppErrorType.offline => const _ErrorSpecification(
      code: 'OFFLINE',
      title: 'Bạn đang ngoại tuyến',
      message:
          'Hãy kiểm tra kết nối mạng. Nhật ký cục bộ vẫn được giữ an toàn.',
      actionLabel: 'Thử lại',
      illustrationLabel: 'Minh họa trạng thái ngoại tuyến',
      color: Color(0xFF1565C0),
      icon: Icons.refresh_rounded,
    ),
  };
}

String _svgIllustration(_ErrorSpecification spec) =>
    '''
<svg viewBox="0 0 240 190" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="sky" x1="0" x2="1" y1="0" y2="1">
      <stop stop-color="#F1F8E9"/><stop offset="1" stop-color="#E8F5E9"/>
    </linearGradient>
  </defs>
  <rect x="8" y="8" width="224" height="174" rx="32" fill="url(#sky)"/>
  <path d="M24 151c30-25 50-17 73-34 22-17 45-44 81-26 16 8 24 8 42-2v42H24z" fill="#C8E6C9"/>
  <circle cx="186" cy="47" r="18" fill="#FFE082"/>
  <path d="M122 138c-4-46 10-76 42-89-3 38-20 68-42 89Z" fill="#81C784"/>
  <path d="M123 138c3-43-10-67-35-79 1 36 12 63 35 79Z" fill="#A5D6A7"/>
  <path d="M122 139V83" stroke="#2E7D32" stroke-width="5" stroke-linecap="round"/>
  <circle cx="122" cy="139" r="16" fill="#FFFFFF"/>
  <text x="122" y="145" text-anchor="middle" font-family="Arial, sans-serif" font-size="18" font-weight="700" fill="${_svgColor(spec.color)}">!</text>
</svg>''';

String _svgColor(Color color) {
  final red = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final green = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final blue = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#${'$red$green$blue'.toUpperCase()}';
}
