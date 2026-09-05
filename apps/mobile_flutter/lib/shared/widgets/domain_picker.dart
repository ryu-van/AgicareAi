import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

Future<Domain?> showDomainPicker(BuildContext context) =>
    showModalBottomSheet<Domain>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn cần hỗ trợ về gì?',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn ngữ cảnh cho cuộc trò chuyện này.',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.eco_outlined, color: AppColors.primary),
                ),
                title: const Text('Cây trồng'),
                subtitle: const Text('Sâu bệnh, chăm sóc và mùa vụ'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pop(Domain.plant),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.infoSurface,
                  child: Icon(Icons.pets_outlined, color: AppColors.info),
                ),
                title: const Text('Vật nuôi'),
                subtitle: const Text('Sức khỏe, dinh dưỡng và chăn nuôi'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pop(Domain.animal),
              ),
            ],
          ),
        ),
      ),
    );
