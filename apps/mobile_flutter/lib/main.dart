import 'package:flutter/material.dart';

import 'app.dart';
import 'core/auth/auth_service.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/notifications/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validateForProduction();
  await LocalNotificationService.instance.initialize();
  final authService = AuthService();
  await authService.initialize();
  final apiClient = ApiClient(authService: authService);
  runApp(AgriCareApp(apiClient: apiClient, authService: authService));
}
