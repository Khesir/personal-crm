import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/shell/presentation/state/shell_state.dart';
import '../../di.dart';
import '../../domain/controller/portfolio_content_controller.dart';
import '../section/portfolio_overview_section.dart';
import '../section/portfolio_content_section.dart';
import '../section/portfolio_config_section.dart';
import '../section/portfolio_settings_section.dart';

class PortfolioScreen extends StatefulWidget {
  final AppSection section;

  const PortfolioScreen({super.key, required this.section});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late final PortfolioBlogController _blogsCtrl;
  late final PortfolioProjectController _projectsCtrl;
  late final PortfolioExperienceController _experiencesCtrl;
  late final PortfolioPostController _postsCtrl;
  late final PortfolioHomeConfigController _homeCtrl;
  late final PortfolioAboutConfigController _aboutCtrl;
  late final PortfolioServicesConfigController _servicesCtrl;

  @override
  void initState() {
    super.initState();
    final ctrls = createPortfolioControllers();
    _blogsCtrl = ctrls.blogs;
    _projectsCtrl = ctrls.projects;
    _experiencesCtrl = ctrls.experiences;
    _postsCtrl = ctrls.posts;
    _homeCtrl = ctrls.homeConfig;
    _aboutCtrl = ctrls.aboutConfig;
    _servicesCtrl = ctrls.servicesConfig;
    _loadForSection(widget.section);
  }

  @override
  void didUpdateWidget(PortfolioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      _loadForSection(widget.section);
    }
  }

  void _loadForSection(AppSection section) {
    switch (section) {
      case AppSection.overview:
        _blogsCtrl.load();
        _projectsCtrl.load();
        _experiencesCtrl.load();
        _postsCtrl.load();
      case AppSection.blogs:
        _blogsCtrl.load();
      case AppSection.projects:
        _projectsCtrl.load();
      case AppSection.experiences:
        _experiencesCtrl.load();
      case AppSection.posts:
        _postsCtrl.load();
      case AppSection.home:
        _homeCtrl.load();
      case AppSection.about:
        _aboutCtrl.load();
      case AppSection.services:
        _servicesCtrl.load();
      default:
        break;
    }
  }

  @override
  void dispose() {
    _blogsCtrl.dispose();
    _projectsCtrl.dispose();
    _experiencesCtrl.dispose();
    _postsCtrl.dispose();
    _homeCtrl.dispose();
    _aboutCtrl.dispose();
    _servicesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: switch (widget.section) {
        AppSection.overview => PortfolioOverviewSection(
            blogsCtrl: _blogsCtrl,
            projectsCtrl: _projectsCtrl,
            experiencesCtrl: _experiencesCtrl,
            postsCtrl: _postsCtrl,
          ),
        AppSection.blogs => PortfolioBlogsSection(ctrl: _blogsCtrl),
        AppSection.projects => PortfolioProjectsSection(ctrl: _projectsCtrl),
        AppSection.experiences => PortfolioExperiencesSection(ctrl: _experiencesCtrl),
        AppSection.posts => PortfolioPostsSection(ctrl: _postsCtrl),
        AppSection.home => PortfolioHomeConfigSection(ctrl: _homeCtrl),
        AppSection.about => PortfolioAboutConfigSection(ctrl: _aboutCtrl),
        AppSection.services => PortfolioServicesConfigSection(ctrl: _servicesCtrl),
        AppSection.settings => const PortfolioSettingsSection(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
