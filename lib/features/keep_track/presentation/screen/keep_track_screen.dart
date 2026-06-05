import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/shell/presentation/state/shell_state.dart';
import '../../di.dart';
import '../../domain/controller/keep_track_controller.dart';
import '../../domain/controller/analytics_controller.dart';
import '../../domain/controller/support_controller.dart';
import '../section/overview_section.dart';
import '../section/announcements_section.dart';
import '../section/releases_section.dart';
import '../section/analytics_section.dart';
import '../section/support_section.dart';
import '../section/settings_section.dart';

class KeepTrackScreen extends StatefulWidget {
  final AppSection section;
  final SupportController? supportCtrl;

  const KeepTrackScreen({super.key, required this.section, this.supportCtrl});

  @override
  State<KeepTrackScreen> createState() => _KeepTrackScreenState();
}

class _KeepTrackScreenState extends State<KeepTrackScreen> {
  late final AnnouncementsController _announcementsCtrl;
  late final ReleasesController _releasesCtrl;
  late final AnalyticsController _analyticsCtrl;

  @override
  void initState() {
    super.initState();
    final controllers = createKeepTrackControllers();
    _announcementsCtrl = controllers.announcements;
    _releasesCtrl = controllers.releases;
    _analyticsCtrl = controllers.analytics;
    _loadForSection(widget.section);
  }

  @override
  void didUpdateWidget(KeepTrackScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      _loadForSection(widget.section);
    }
  }

  void _loadForSection(AppSection section) {
    switch (section) {
      case AppSection.overview:
        _releasesCtrl.load();
        _announcementsCtrl.load();
      case AppSection.announcements:
        _announcementsCtrl.load();
      case AppSection.releases:
        _releasesCtrl.load();
      case AppSection.analytics:
        _analyticsCtrl.load();
      case AppSection.support:
        widget.supportCtrl?.load();
      case AppSection.settings:
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _announcementsCtrl.dispose();
    _releasesCtrl.dispose();
    _analyticsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: switch (widget.section) {
        AppSection.overview => KeepTrackOverviewSection(
            releasesCtrl: _releasesCtrl,
            announcementsCtrl: _announcementsCtrl,
          ),
        AppSection.announcements =>
          AnnouncementsSection(controller: _announcementsCtrl),
        AppSection.releases => ReleasesSection(controller: _releasesCtrl),
        AppSection.analytics => AnalyticsSection(controller: _analyticsCtrl),
        AppSection.support => widget.supportCtrl != null
            ? SupportSection(controller: widget.supportCtrl!)
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        AppSection.settings => const KeepTrackSettingsSection(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
