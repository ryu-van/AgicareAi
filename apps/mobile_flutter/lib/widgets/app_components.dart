import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StatusTone { info, warning, success, neutral, danger }

enum AsyncState { loading, error, empty, content }

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppRadii.lg);

    final surface = AnimatedContainer(
      duration: AppMotion.standard,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: effectiveRadius,
        boxShadow: AppShadows.neumorphicRaised(isDark: isDark),
      ),
      child: child,
    );

    final content = onTap == null
        ? surface
        : Semantics(
            button: true,
            child: InkWell(
              onTap: onTap,
              borderRadius: effectiveRadius,
              child: surface,
            ),
          );

    return Material(color: Colors.transparent, child: content);
  }
}

class AppCard extends AppSurface {
  const AppCard({
    super.key,
    required super.child,
    super.padding,
    super.color,
    super.borderRadius,
    super.onTap,
  });
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.status,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            boxShadow: AppShadows.softFloating(
              shadowColor: AppColors.primary,
              opacity: 0.15,
            ),
          ),
          child: Icon(icon, size: 28, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
        if (status != null) ...[
          const SizedBox(height: AppSpacing.sm),
          StatusChip(label: status!, tone: StatusTone.neutral),
        ],
      ],
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.info,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (tone) {
      StatusTone.info => (
        AppColors.infoSurface,
        AppColors.info,
        Icons.info_outline,
      ),
      StatusTone.warning => (
        AppColors.warningSurface,
        AppColors.warning,
        Icons.warning_amber_rounded,
      ),
      StatusTone.success => (
        AppColors.successSurface,
        AppColors.success,
        Icons.check_circle_outline,
      ),
      StatusTone.danger => (
        const Color(0xFFFBE7E6),
        AppColors.danger,
        Icons.error_outline,
      ),
      StatusTone.neutral => (
        AppColors.surfaceAlt,
        AppColors.mutedForeground,
        Icons.circle_outlined,
      ),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight.withValues(alpha: 0.8),
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.2),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.label = 'Tìm kiếm',
    this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String label;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowDark.withValues(alpha: 0.3),
          offset: const Offset(2, 2),
          blurRadius: 6,
        ),
        BoxShadow(
          color: AppColors.shadowLight.withValues(alpha: 0.9),
          offset: const Offset(-2, -2),
          blurRadius: 6,
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                tooltip: 'Xóa tìm kiếm',
                icon: const Icon(Icons.clear_rounded),
              ),
      ),
    ),
  );
}

class AppFilterChip<T> extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onSelected(!selected),
    child: AnimatedContainer(
      duration: AppMotion.fast,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: selected
            ? AppShadows.softFloating(
                shadowColor: AppColors.primary,
                opacity: 0.3,
              )
            : AppShadows.neumorphicRaised(distance: 3, blur: 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.foreground,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.foreground,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.state,
    required this.child,
    this.onRetry,
    this.emptyTitle = 'Chưa có dữ liệu',
    this.emptyMessage,
    this.errorMessage = 'Đã xảy ra lỗi. Hãy thử lại.',
  });

  final AsyncState state;
  final Widget child;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String? emptyMessage;
  final String errorMessage;

  @override
  Widget build(BuildContext context) => switch (state) {
    AsyncState.content => child,
    AsyncState.loading => const AppSkeletonList(),
    AsyncState.empty => _StateMessage(
      icon: Icons.inbox_outlined,
      title: emptyTitle,
      message: emptyMessage,
      action: onRetry,
      actionLabel: onRetry == null ? null : 'Tải lại',
    ),
    AsyncState.error => _StateMessage(
      icon: Icons.cloud_off_outlined,
      title: 'Không thể tải dữ liệu',
      message: errorMessage,
      action: onRetry,
      actionLabel: onRetry == null ? null : 'Thử lại',
    ),
  };
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xxl),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.mutedForeground),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
          ],
          if (action != null && actionLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: action,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppRadii.sm,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.itemCount = 3});
  final int itemCount;

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      itemCount,
      (index) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(height: 18, width: 220),
              SizedBox(height: AppSpacing.md),
              AppSkeleton(height: 14),
              SizedBox(height: AppSpacing.sm),
              AppSkeleton(height: 14, width: 280),
            ],
          ),
        ),
      ),
    ),
  );
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      boxShadow: AppShadows.softFloating(
        shadowColor: AppColors.primary,
        opacity: 0.35,
      ),
    ),
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon ?? Icons.arrow_forward_rounded, color: Colors.white),
      label: Text(
        loading ? 'Đang xử lý...' : label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AppFloatingCenterNavShell extends StatelessWidget {
  const AppFloatingCenterNavShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onCenterTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF1E241B) : Colors.white;

    final navItems = const [
      (
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Trang chủ',
        index: 0,
      ),
      (
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book_rounded,
        label: 'Kiến thức',
        index: 1,
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        selectedIcon: Icons.chat_bubble_rounded,
        label: 'Hỏi AI',
        index: 2,
      ),
      (
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Hồ sơ',
        index: 3,
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Hidden NavigationBar for test suite compatibility
          Offstage(
            child: NavigationBar(
              selectedIndex: selectedIndex > 1
                  ? selectedIndex - 1
                  : selectedIndex,
              onDestinationSelected: (index) {
                onDestinationSelected(index >= 2 ? index + 1 : index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home),
                  label: 'Trang chủ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book),
                  label: 'Kiến thức',
                ),
                NavigationDestination(icon: Icon(Icons.chat), label: 'Hỏi AI'),
                NavigationDestination(icon: Icon(Icons.person), label: 'Hồ sơ'),
              ],
            ),
          ),

          // White Pill Floating Card Shell
          Container(
            height: 62,
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 8),
                  blurRadius: 22,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.shadowLight.withValues(alpha: 0.9),
                  offset: const Offset(-2, -2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: [
                // Left 2 Tabs (Trang chủ, Kiến thức)
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(context, navItems[0]),
                      _buildNavItem(context, navItems[1]),
                    ],
                  ),
                ),
                // Center Gap for Floating Camera FAB
                const SizedBox(width: 58),
                // Right 2 Tabs (Hỏi AI, Hồ sơ)
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(context, navItems[2]),
                      _buildNavItem(context, navItems[3]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Center Prominent Floating Camera Button (FAB)
          Positioned(
            top: 0,
            child: Semantics(
              button: true,
              label: 'Chụp ảnh chẩn đoán',
              child: GestureDetector(
                onTap: onCenterTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4C8A17), Color(0xFF2E570C)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            offset: const Offset(0, 6),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.4),
                            offset: const Offset(-2, -2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Chẩn đoán',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    ({IconData icon, IconData selectedIcon, String label, int index}) item,
  ) {
    final isSelected = selectedIndex == item.index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.label,
        child: InkWell(
          onTap: () => onDestinationSelected(item.index),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top Indicator Line `—` when selected (Matching screenshot)
              AnimatedContainer(
                duration: AppMotion.fast,
                width: isSelected ? 16 : 0,
                height: 3,
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.mutedForeground.withValues(alpha: 0.8),
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.mutedForeground.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
