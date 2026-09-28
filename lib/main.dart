import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init(debug: true);
  runApp(const ProviderScope(child: LabInventoryApp()));
}
