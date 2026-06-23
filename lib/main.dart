import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'core/config/data_namespace.dart';
import 'core/di/service_locator.dart';
import 'core/theme/theme.dart';
import 'core/window/single_instance_service.dart';
import 'features/agent/api.dart';
import 'features/settings/di.dart';
import 'features/shell/presentation/screen/app_shell_screen.dart';

Future<void> _initTray() async {
  await trayManager.setIcon('assets/icon.png');
  await trayManager.setToolTip('Avyn');
}

Future<void> _updateTrayMenu(AgentStatus status) async {
  final isRunning = status == AgentStatus.running;
  final items = <MenuItem>[
    MenuItem(key: 'open', label: 'Open Avyn'),
    MenuItem.separator(),
    MenuItem(
      label: isRunning ? 'Agent: Running' : 'Agent: Idle',
      disabled: true,
    ),
    if (isRunning) MenuItem(key: 'stop', label: 'Stop agent'),
    MenuItem.separator(),
    MenuItem(key: 'quit', label: 'Quit'),
  ];
  await trayManager.setContextMenu(Menu(items: items));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await initServiceCardsCache(prefs);
  registerAgentDependencies();

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

  final serverManager = locator.get<AgentServerManager>();
  final agentController = locator.get<AgentController>();
  agentController.setServerStatus(AgentServerStatus.starting);
  serverManager.initialize().then((_) {
    if (serverManager.isReady) {
      agentController.setServerStatus(AgentServerStatus.ready);
    } else {
      agentController.setServerStatus(AgentServerStatus.failed);
    }
  });

  await _initTray();
  await _updateTrayMenu(AgentStatus.idle);

  runApp(const CrmApp());
}

class CrmApp extends StatefulWidget {
  const CrmApp({super.key});

  @override
  State<CrmApp> createState() => _CrmAppState();
}

class _CrmAppState extends State<CrmApp>
    with WidgetsBindingObserver, TrayListener {
  bool _hasShownTrayHint = false;
  StreamSubscription<AgentStateData>? _agentSub;
  AgentStatus _lastStatus = AgentStatus.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    trayManager.addListener(this);

    final agentController = locator.get<AgentController>();
    _agentSub = agentController.stream.listen((state) {
      if (state.status != _lastStatus) {
        _lastStatus = state.status;
        _updateTrayMenu(state.status);
      }
    });
  }

  @override
  void dispose() {
    _agentSub?.cancel();
    trayManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    final agentController = locator.get<AgentController>();
    if (agentController.state.status != AgentStatus.running) {
      await locator.get<AgentServerManager>().shutdown();
      return AppExitResponse.exit;
    }
    await windowManager.hide();
    if (!_hasShownTrayHint) {
      _hasShownTrayHint = true;
      await trayManager.setToolTip('Avyn is still running in the background');
    }
    return AppExitResponse.cancel;
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'open':
        windowManager.show();
        windowManager.focus();
      case 'stop':
        locator.get<AgentController>().stop();
      case 'quit':
        locator.get<AgentServerManager>().shutdown().then((_) {
          windowManager.destroy();
        });
    }
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

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
