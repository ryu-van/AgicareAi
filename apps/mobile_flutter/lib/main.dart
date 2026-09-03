import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_config.dart';

void main() {
  AppConfig.validateForProduction();
  runApp(AgriCareApp());
}
