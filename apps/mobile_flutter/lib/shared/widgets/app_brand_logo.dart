import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Kích thước chuẩn cho Logo AgriAn trên ứng dụng và web
enum BrandLogoSize {
  /// Kích thước nhỏ (32x32) cho thanh App Bar, Header hoặc Chip
  small(32),

  /// Kích thước trung bình (48x48) cho Card, List Item
  medium(48),

  /// Kích thước tiêu chuẩn (64x64) cho Hero Banner, Modal
  large(64),

  /// Kích thước lớn (96x96+) cho Splash Screen, Onboarding, Profile Header
  hero(96);

  const BrandLogoSize(this.dimension);
  final double dimension;
}

/// **AgriAn Brand Logo — Concept 2: Chiếc Khiên Bảo Vệ Đa Nhánh**
///
/// Biểu tượng chính thức của hệ sinh thái **AgriAn**:
/// - **Tên thương hiệu:** AgriAn (Giao thoa giữa "Agri" và "An" - An tâm, An toàn;
///   quốc tế đọc như "Agrarian" - nền văn minh nông nghiệp).
/// - **Vành khiên bảo vệ (Shield):** Tượng trưng cho sự chở che, an tâm, phòng ngừa dịch bệnh.
/// - **Mầm cây xanh vươn lên (Plant Domain):** Đại diện cho nông nghiệp trồng trọt tươi tốt.
/// - **Bóng gia súc vàng lúa (Animal Domain):** Đại diện cho ngành chăn nuôi trù phú.
/// - **Các điểm kết nối vi mạch (AI Nodes):** Đại diện cho trí tuệ nhân tạo và tri thức chuyên gia.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.size = BrandLogoSize.medium,
    this.customDimension,
    this.showBorder = true,
    this.semanticLabel = 'AgriAn Logo - Chiếc khiên bảo vệ cây trồng và vật nuôi',
  });

  final BrandLogoSize size;
  final double? customDimension;
  final bool showBorder;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dimension = customDimension ?? size.dimension;
    final borderRadius = BorderRadius.circular(dimension * 0.24);

    final logoImage = Image.asset(
      'assets/images/agrian_logo.png',
      width: dimension,
      height: dimension,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/agrian_logo.jpg',
        width: dimension,
        height: dimension,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _FallbackShieldIcon(
          dimension: dimension,
        ),
      ),
    );

    if (!showBorder) {
      return Semantics(
        label: semanticLabel,
        image: true,
        child: Container(
          width: dimension,
          height: dimension,
          alignment: Alignment.center,
          child: logoImage,
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: dimension * 0.16,
              offset: Offset(0, dimension * 0.04),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: logoImage,
      ),
    );
  }
}

/// Fallback vector icon khi chạy trong môi trường test hoặc asset chưa tải
class _FallbackShieldIcon extends StatelessWidget {
  const _FallbackShieldIcon({required this.dimension});
  final double dimension;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBFBF6),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shield_rounded,
            color: AppColors.primary,
            size: dimension * 0.72,
          ),
          Positioned(
            child: Icon(
              Icons.eco_rounded,
              color: const Color(0xFFE8B923),
              size: dimension * 0.38,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị tiêu đề thương hiệu kèm Logo nằm ngang
class AgriAnBrandHeader extends StatelessWidget {
  const AgriAnBrandHeader({
    super.key,
    this.logoSize = BrandLogoSize.small,
    this.showTagline = true,
  });

  final BrandLogoSize logoSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppBrandLogo(size: logoSize),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            if (showTagline)
              const Text(
                'Vụ mùa an tâm, nông gia thịnh vượng',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

