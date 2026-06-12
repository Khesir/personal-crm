import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'core/config/data_namespace.dart';
import 'core/theme/theme.dart';
import 'core/window/single_instance_service.dart';
import 'features/shell/presentation/screen/app_shell_screen.dart';

const kSettingsPrefix = '$kDataNamespace.env_override_';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final prefs = await SharedPreferences.getInstance();
  for (final key in prefs.getKeys()) {
    if (key.startsWith(kSettingsPrefix)) {
      final envKey = key.substring(kSettingsPrefix.length);
      final value = prefs.getString(key);
      if (value != null) dotenv.env[envKey] = value;
    }
  }

  await windowManager.ensureInitialized();

  final windowOptions = WindowOptions(
    size: const Size(1200, 760),
    minimumSize: const Size(960, 600),
    center: true,
    title: kDataNamespace == 'dev' ? 'Codex (Dev)' : 'Codex',
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: const Color(0xFF0D0D0F),
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.show();
    await windowManager.focus();
  });

  final singleInstance = SingleInstanceService();
  final acquired = await singleInstance.acquire();
  if (!acquired) {
    await windowManager.close();
    return;
  }
  singleInstance.onSecondInstanceLaunched = () async {
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
  };

  runApp(const CrmApp());
}

class CrmApp extends StatelessWidget {
  const CrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codex',
      debugShowCheckedModeBanner: false,
      theme: AppStyling.theme,
      home: const AppShellScreen(),
    );
  }
}
