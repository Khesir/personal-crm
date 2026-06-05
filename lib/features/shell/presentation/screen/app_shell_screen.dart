import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/core/ui/desktop_title_bar.dart';
import 'package:crm/features/keep_track/di.dart' show createSupportController;
import 'package:crm/features/portfolio/presentation/screen/portfolio_screen.dart';
import 'package:crm/features/keep_track/domain/controller/support_controller.dart';
import 'package:crm/features/keep_track/presentation/screen/keep_track_screen.dart';
import 'package:crm/features/keep_track/presentation/section/settings_section.dart';
import 'package:crm/features/time_tracker/presentation/screen/time_tracker_screen.dart';
import 'package:crm/features/ari_connect/presentation/screen/ari_connect_screen.dart';
import 'package:crm/features/minecraft/presentation/screen/minecraft_screen.dart';
import '../../domain/controller/shell_controller.dart';
import '../state/shell_state.dart';
import '../widget/app_tab_bar.dart';
import '../widget/app_sidebar.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late final ShellController _controller;
  SupportController? _supportCtrl;

  @override
  void initState() {
    super.initState();
    _controller = ShellController();
    _initSupport();
  }

  Future<void> _initSupport() async {
    final ctrl = await createSupportController();
    if (mounted) setState(() => _supportCtrl = ctrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    _supportCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const DesktopTitleBar(),
          Container(height: 1, color: AppColors.border),
          AppTabBar(controller: _controller),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: Row(
              children: [
                AppSidebar(controller: _controller, supportCtrl: _supportCtrl),
                Container(width: 1, color: AppColors.border),
                Expanded(
                  child: StreamBuilder<ShellStateData>(
                    stream: _controller.stream,
                    initialData: _controller.state,
                    builder: (context, snapshot) {
                      final shellState = snapshot.data!;
                      return _ContentArea(shellState: shellState, supportCtrl: _supportCtrl);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentArea extends StatelessWidget {
  final ShellStateData shellState;
  final SupportController? supportCtrl;

  const _ContentArea({required this.shellState, this.supportCtrl});

  @override
  Widget build(BuildContext context) {
    if (shellState.selectedSection == AppSection.settings) {
      return switch (shellState.selectedTab) {
        AppTab.portfolio => const PortfolioScreen(section: AppSection.settings),
        AppTab.keepTrack => const KeepTrackSettingsSection(),
        _ => const _PlaceholderSettings(),
      };
    }
    return switch (shellState.selectedTab) {
      AppTab.portfolio => PortfolioScreen(section: shellState.selectedSection),
      AppTab.keepTrack => KeepTrackScreen(section: shellState.selectedSection, supportCtrl: supportCtrl),
      AppTab.timeTracker => const TimeTrackerScreen(),
      AppTab.ariConnect => AriConnectScreen(section: shellState.selectedSection),
      AppTab.minecraft => const MinecraftScreen(),
    };
  }
}

class _PlaceholderSettings extends StatelessWidget {
  const _PlaceholderSettings();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppStyling.headingLg),
          const SizedBox(height: AppStyling.spaceXs),
          Text('No environment variables configured for this tab yet.', style: AppStyling.bodySm),
        ],
      ),
    );
  }
}
