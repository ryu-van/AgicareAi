import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'app_components.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .82,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadii.lg),
            topRight: const Radius.circular(AppRadii.lg),
            bottomLeft: Radius.circular(isUser ? AppRadii.lg : AppRadii.xs),
            bottomRight: Radius.circular(isUser ? AppRadii.xs : AppRadii.lg),
          ),
          boxShadow: isUser
              ? AppShadows.softFloating(
                  shadowColor: AppColors.primary,
                  opacity: 0.25,
                )
              : AppShadows.neumorphicRaised(
                  distance: 4,
                  blur: 8,
                  isDark: isDark,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.foreground,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (!isUser && message.status != 'completed') ...[
              const SizedBox(height: AppSpacing.sm),
              StatusChip(
                label: _statusLabel(message.status),
                tone: message.status == 'failed'
                    ? StatusTone.danger
                    : StatusTone.info,
              ),
            ],
            if (message.safetyLevel == 'urgent') ...[
              const SizedBox(height: AppSpacing.sm),
              const StatusChip(
                label: 'Cảnh báo khẩn cấp: hãy liên hệ chuyên gia.',
                tone: StatusTone.warning,
              ),
            ],
            if (message.citations.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: message.citations
                    .map((citation) => CitationChip(label: citation))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CitationChip extends StatelessWidget {
  const CitationChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Nguồn tham khảo: $label',
    child: Chip(
      avatar: const Icon(
        Icons.menu_book_outlined,
        size: 16,
        color: AppColors.info,
      ),
      label: Text(
        'Nguồn: $label',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.info,
        ),
      ),
      backgroundColor: AppColors.surfaceAlt,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      visualDensity: VisualDensity.compact,
    ),
  );
}

String _statusLabel(String status) => switch (status) {
  'queued' => 'Đang xếp hàng xử lý...',
  'processing' => 'AI đang xử lý...',
  'failed' => 'Xử lý thất bại.',
  'safety_blocked' => 'Câu hỏi cần được xem xét an toàn.',
  _ => 'Đã xử lý',
};
