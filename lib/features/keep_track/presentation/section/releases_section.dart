import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/core/state/state.dart';
import '../../domain/controller/keep_track_controller.dart';
import '../state/keep_track_state.dart';

class ReleasesSection extends StatefulWidget {
  final ReleasesController controller;

  const ReleasesSection({super.key, required this.controller});

  @override
  State<ReleasesSection> createState() => _ReleasesSectionState();
}

class _ReleasesSectionState extends State<ReleasesSection> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(controller: widget.controller),
        Expanded(
          child: AsyncStreamBuilder<List<AppRelease>>(
            state: widget.controller,
            loadingBuilder: (_) => const Center(
              child: CircularProgressIndicator(color: AppColors.accentKeepTrack),
            ),
            errorBuilder: (_, msg) => Center(
              child: Text(
                'Could not connect to Keep Track API.\n$msg',
                style: AppStyling.bodySm,
                textAlign: TextAlign.center,
              ),
            ),
            builder: (context, releases) {
              if (releases.isEmpty) return _EmptyState(controller: widget.controller);
              final selected = releases.firstWhere(
                (r) => r.id == _selectedId,
                orElse: () => releases.first,
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VersionList(
                    releases: releases,
                    selectedId: selected.id,
                    onSelect: (id) => setState(() => _selectedId = id),
                  ),
                  Container(width: 1, color: AppColors.border),
                  Expanded(
                    child: _ReleaseContent(
                      release: selected,
                      controller: widget.controller,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Version list ───────────────────────────────────────────────────────────────

class _VersionList extends StatelessWidget {
  final List<AppRelease> releases;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _VersionList({
    required this.releases,
    required this.selectedId,
    required this.onSelect,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceMd),
        itemCount: releases.length,
        itemBuilder: (_, i) {
          final r = releases[i];
          final isSelected = r.id == selectedId;
          final isLatest = i == 0;
          return GestureDetector(
            onTap: () => onSelect(r.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(
                horizontal: AppStyling.spaceSm,
                vertical: 2,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyling.spaceMd,
                vertical: AppStyling.spaceSm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentKeepTrack.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppStyling.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'v${r.version}',
                        style: AppStyling.bodySm.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.accentKeepTrack
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (isLatest) ...[
                        const SizedBox(width: AppStyling.spaceSm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'latest',
                            style: AppStyling.monoSm.copyWith(
                              fontSize: 9,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(r.publishedAt ?? r.createdAt),
                    style: AppStyling.monoSm.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ReleasesController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceXl, vertical: AppStyling.spaceLg),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Releases', style: AppStyling.headingLg),
            Text('Manage builds per platform', style: AppStyling.bodySm),
          ]),
          const Spacer(),
          _PrimaryButton(
            label: 'New Version',
            onTap: () => showDialog(
              context: context,
              builder: (_) => _NewVersionDialog(controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ReleasesController controller;
  const _EmptyState({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('No releases yet', style: AppStyling.headingMd),
        const SizedBox(height: AppStyling.spaceSm),
        Text('Create the first version to get started.', style: AppStyling.bodySm),
        const SizedBox(height: AppStyling.spaceXl),
        _PrimaryButton(
          label: 'Create First Version',
          onTap: () => showDialog(
            context: context,
            builder: (_) => _NewVersionDialog(controller: controller),
          ),
        ),
      ]),
    );
  }
}

// ── Release content ────────────────────────────────────────────────────────────

class _ReleaseContent extends StatelessWidget {
  final AppRelease release;
  final ReleasesController controller;

  const _ReleaseContent({required this.release, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('v${release.version}', style: AppStyling.displayMd),
            const SizedBox(width: AppStyling.spaceMd),
            if (release.published)
              _Badge(label: 'PUBLISHED', color: AppColors.success),
          ]),
          const SizedBox(height: AppStyling.spaceXs),
          Text(release.title, style: AppStyling.bodySm),
          const SizedBox(height: AppStyling.spaceXxl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WindowsCard(config: release.platforms.windows, releaseId: release.id, controller: controller),
              const SizedBox(width: AppStyling.spaceLg),
              _AndroidCard(config: release.platforms.android, releaseId: release.id, controller: controller),
              const SizedBox(width: AppStyling.spaceLg),
              _StoreCard(
                platform: 'macos',
                label: 'macOS',
                icon: Icons.laptop_mac_outlined,
                storeName: 'Mac App Store',
                config: release.platforms.macos,
                controller: controller,
              ),
              const SizedBox(width: AppStyling.spaceLg),
              _StoreCard(
                platform: 'ios',
                label: 'iOS',
                icon: Icons.phone_iphone_outlined,
                storeName: 'App Store',
                config: release.platforms.ios,
                controller: controller,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status dropdown ────────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  final PlatformStatus value;
  final ValueChanged<PlatformStatus> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  Color _color(PlatformStatus s) => switch (s) {
        PlatformStatus.available => AppColors.accentKeepTrack,
        PlatformStatus.comingSoon => AppColors.warning,
        PlatformStatus.notAvailable => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceSm, vertical: 2),
      decoration: BoxDecoration(
        color: _color(value).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        border: Border.all(color: _color(value).withValues(alpha: 0.3)),
      ),
      child: DropdownButton<PlatformStatus>(
        value: value,
        underline: const SizedBox.shrink(),
        isDense: true,
        dropdownColor: AppColors.surfaceElevated,
        style: AppStyling.monoSm.copyWith(color: _color(value)),
        icon: Icon(Icons.expand_more, size: 14, color: _color(value)),
        items: PlatformStatus.values
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.label,
                      style: AppStyling.monoSm.copyWith(color: _color(s))),
                ))
            .toList(),
        onChanged: (s) => onChanged(s!),
      ),
    );
  }
}

// ── Windows card ───────────────────────────────────────────────────────────────

class _WindowsCard extends StatefulWidget {
  final WindowsPlatformConfig config;
  final String releaseId;
  final ReleasesController controller;

  const _WindowsCard({
    required this.config,
    required this.releaseId,
    required this.controller,
  });

  @override
  State<_WindowsCard> createState() => _WindowsCardState();
}

class _WindowsCardState extends State<_WindowsCard> {
  bool _uploading = false;
  bool _hovered = false;

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() => _uploading = true);
    try {
      await widget.controller.uploadPlatformFile(
        platform: 'windows',
        urlField: 'downloadUrl',
        bytes: result.files.single.bytes!,
        fileName: result.files.single.name,
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.config.status == PlatformStatus.available;
    final hasFile = widget.config.downloadUrl != null;

    return Expanded(
      child: _CardShell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.desktop_windows_outlined,
                size: 28,
                color: isAvailable ? AppColors.accentKeepTrack : AppColors.textMuted),
            const SizedBox(height: AppStyling.spaceMd),
            Text('Windows', style: AppStyling.headingMd),
            const SizedBox(height: AppStyling.spaceXs),
            Text('.exe', style: AppStyling.monoSm),
            const SizedBox(height: AppStyling.spaceMd),
            _StatusDropdown(
              value: widget.config.status,
              onChanged: (s) => widget.controller.updatePlatformStatus(
                  platform: 'windows', status: s),
            ),
            if (isAvailable) ...[
              const SizedBox(height: AppStyling.spaceMd),
              MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: GestureDetector(
                  onTap: _uploading ? null : _upload,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppStyling.spaceSm, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasFile
                          ? AppColors.accentKeepTrack.withValues(alpha: 0.12)
                          : _hovered
                              ? AppColors.surfaceElevated
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                      border: Border.all(
                          color: _hovered
                              ? AppColors.accentKeepTrack.withValues(alpha: 0.4)
                              : AppColors.border),
                    ),
                    child: _uploading
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.accentKeepTrack),
                          )
                        : Text(
                            hasFile ? 'Uploaded — replace' : 'Upload .exe',
                            style: AppStyling.monoSm.copyWith(
                              color: hasFile
                                  ? AppColors.accentKeepTrack
                                  : AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Android card ───────────────────────────────────────────────────────────────

class _AndroidCard extends StatefulWidget {
  final AndroidPlatformConfig config;
  final String releaseId;
  final ReleasesController controller;

  const _AndroidCard({
    required this.config,
    required this.releaseId,
    required this.controller,
  });

  @override
  State<_AndroidCard> createState() => _AndroidCardState();
}

class _AndroidCardState extends State<_AndroidCard> {
  bool _uploading = false;
  bool _hovered = false;

  static const _playGreen = Color(0xFF01875F);

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() => _uploading = true);
    try {
      await widget.controller.uploadPlatformFile(
        platform: 'android',
        urlField: 'apkUrl',
        bytes: result.files.single.bytes!,
        fileName: result.files.single.name,
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.config.status == PlatformStatus.available;
    final hasApk = widget.config.apkUrl != null;
    final hasPlayStore = widget.config.playStoreUrl != null;

    return Expanded(
      child: _CardShell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.android_outlined,
                size: 28,
                color: isAvailable ? AppColors.accentKeepTrack : AppColors.textMuted),
            const SizedBox(height: AppStyling.spaceMd),
            Text('Android', style: AppStyling.headingMd),
            const SizedBox(height: AppStyling.spaceXs),
            Text('.apk', style: AppStyling.monoSm),
            const SizedBox(height: AppStyling.spaceMd),
            _StatusDropdown(
              value: widget.config.status,
              onChanged: (s) => widget.controller.updatePlatformStatus(
                  platform: 'android', status: s),
            ),
            if (isAvailable) ...[
              const SizedBox(height: AppStyling.spaceMd),
              MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: GestureDetector(
                  onTap: _uploading ? null : _upload,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppStyling.spaceSm, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasApk
                          ? AppColors.accentKeepTrack.withValues(alpha: 0.12)
                          : _hovered
                              ? AppColors.surfaceElevated
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                      border: Border.all(
                          color: _hovered
                              ? AppColors.accentKeepTrack.withValues(alpha: 0.4)
                              : AppColors.border),
                    ),
                    child: _uploading
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.accentKeepTrack),
                          )
                        : Text(
                            hasApk ? 'Uploaded — replace' : 'Upload .apk',
                            style: AppStyling.monoSm.copyWith(
                              color: hasApk
                                  ? AppColors.accentKeepTrack
                                  : AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppStyling.spaceSm),
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => _StoreUrlDialog(
                    title: 'Play Store Link',
                    hint: 'https://play.google.com/store/apps/details?id=...',
                    currentUrl: widget.config.playStoreUrl,
                    onSave: (url) =>
                        widget.controller.updatePlayStoreUrl(url),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppStyling.spaceSm, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasPlayStore
                        ? _playGreen.withValues(alpha: 0.10)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                    border: Border.all(
                        color: hasPlayStore
                            ? _playGreen.withValues(alpha: 0.3)
                            : AppColors.border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      hasPlayStore
                          ? Icons.check_circle_outline
                          : Icons.storefront_outlined,
                      size: 12,
                      color: hasPlayStore ? _playGreen : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasPlayStore ? 'Play Store set' : 'Set Play Store',
                      style: AppStyling.monoSm.copyWith(
                        color: hasPlayStore ? _playGreen : AppColors.textSecondary,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Store card (macOS / iOS) ───────────────────────────────────────────────────

class _StoreCard extends StatelessWidget {
  final String platform;
  final String label;
  final IconData icon;
  final String storeName;
  final StorePlatformConfig config;
  final ReleasesController controller;

  const _StoreCard({
    required this.platform,
    required this.label,
    required this.icon,
    required this.storeName,
    required this.config,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = config.status == PlatformStatus.available;
    final hasUrl = config.storeUrl != null;

    return Expanded(
      child: _CardShell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 28,
                color: isAvailable ? AppColors.accentKeepTrack : AppColors.textMuted),
            const SizedBox(height: AppStyling.spaceMd),
            Text(label, style: AppStyling.headingMd),
            const SizedBox(height: AppStyling.spaceXs),
            Text(storeName, style: AppStyling.monoSm),
            const SizedBox(height: AppStyling.spaceMd),
            _StatusDropdown(
              value: config.status,
              onChanged: (s) => controller.updatePlatformStatus(
                  platform: platform, status: s),
            ),
            if (isAvailable) ...[
              const SizedBox(height: AppStyling.spaceMd),
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => _StoreUrlDialog(
                    title: '$label Store Link',
                    hint: 'https://apps.apple.com/...',
                    currentUrl: config.storeUrl,
                    onSave: (url) => controller.updatePlatformStoreUrl(
                        platform: platform, url: url),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppStyling.spaceSm, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasUrl
                        ? AppColors.accentKeepTrack.withValues(alpha: 0.12)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                    border: Border.all(
                        color: hasUrl
                            ? AppColors.accentKeepTrack.withValues(alpha: 0.3)
                            : AppColors.border),
                  ),
                  child: Text(
                    hasUrl ? 'Store link set' : 'Set store link',
                    style: AppStyling.monoSm.copyWith(
                      color: hasUrl
                          ? AppColors.accentKeepTrack
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Card shell ─────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyling.spaceLg),
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

// ── Store URL dialog ───────────────────────────────────────────────────────────

class _StoreUrlDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String? currentUrl;
  final Future<void> Function(String url) onSave;

  const _StoreUrlDialog({
    required this.title,
    required this.hint,
    required this.currentUrl,
    required this.onSave,
  });

  @override
  State<_StoreUrlDialog> createState() => _StoreUrlDialogState();
}

class _StoreUrlDialogState extends State<_StoreUrlDialog> {
  late final TextEditingController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentUrl ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await widget.onSave(_ctrl.text.trim());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: AppStyling.headingMd),
              const SizedBox(height: AppStyling.spaceXl),
              TextField(
                controller: _ctrl,
                style: AppStyling.bodyLg,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppStyling.bodySm,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(AppStyling.spaceMd),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                    borderSide:
                        const BorderSide(color: AppColors.accentKeepTrack),
                  ),
                ),
              ),
              const SizedBox(height: AppStyling.spaceXl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: AppStyling.bodySm),
                  ),
                  const SizedBox(width: AppStyling.spaceLg),
                  _PrimaryButton(
                    label: 'Save',
                    loading: _loading,
                    onTap: _loading ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── New version dialog ─────────────────────────────────────────────────────────

class _NewVersionDialog extends StatefulWidget {
  final ReleasesController controller;
  const _NewVersionDialog({required this.controller});

  @override
  State<_NewVersionDialog> createState() => _NewVersionDialogState();
}

class _NewVersionDialogState extends State<_NewVersionDialog> {
  final _versionCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _loading = false;

  final Map<String, PlatformStatus> _statuses = {
    'windows': PlatformStatus.comingSoon,
    'android': PlatformStatus.comingSoon,
    'macos': PlatformStatus.comingSoon,
    'ios': PlatformStatus.comingSoon,
  };

  @override
  void dispose() {
    _versionCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_versionCtrl.text.trim().isEmpty ||
        _titleCtrl.text.trim().isEmpty ||
        _bodyCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _loading = true);

    final platforms = ReleasePlatforms(
      windows: WindowsPlatformConfig(status: _statuses['windows']!),
      android: AndroidPlatformConfig(status: _statuses['android']!),
      macos: StorePlatformConfig(status: _statuses['macos']!),
      ios: StorePlatformConfig(status: _statuses['ios']!),
    );

    await widget.controller.createNewVersion(
      _versionCtrl.text.trim(),
      _titleCtrl.text.trim(),
      _bodyCtrl.text.trim(),
      platforms,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Version', style: AppStyling.headingMd),
              const SizedBox(height: AppStyling.spaceXl),
              _DialogField(label: 'Version', hint: '1.0.0', controller: _versionCtrl, maxLines: 1),
              const SizedBox(height: AppStyling.spaceLg),
              _DialogField(label: 'Title', hint: "What's new", controller: _titleCtrl, maxLines: 1),
              const SizedBox(height: AppStyling.spaceLg),
              _DialogField(label: 'Changelog', hint: 'Describe the changes...', controller: _bodyCtrl, maxLines: 4),
              const SizedBox(height: AppStyling.spaceXl),
              Text('Platform availability', style: AppStyling.label),
              const SizedBox(height: AppStyling.spaceMd),
              ...[
                ('windows', Icons.desktop_windows_outlined, 'Windows'),
                ('android', Icons.android_outlined, 'Android'),
                ('macos', Icons.laptop_mac_outlined, 'macOS'),
                ('ios', Icons.phone_iphone_outlined, 'iOS'),
              ].map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppStyling.spaceSm),
                  child: Row(children: [
                    Icon(p.$2, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppStyling.spaceSm),
                    SizedBox(
                      width: 80,
                      child: Text(p.$3, style: AppStyling.bodySm),
                    ),
                    const Spacer(),
                    _StatusDropdown(
                      value: _statuses[p.$1]!,
                      onChanged: (s) => setState(() => _statuses[p.$1] = s),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: AppStyling.spaceXl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: AppStyling.bodySm),
                  ),
                  const SizedBox(width: AppStyling.spaceLg),
                  _PrimaryButton(
                    label: 'Create',
                    loading: _loading,
                    onTap: _loading ? null : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceSm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
      ),
      child: Text(label, style: AppStyling.monoSm.copyWith(color: color)),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _PrimaryButton({required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppStyling.spaceLg, vertical: AppStyling.spaceSm),
        decoration: BoxDecoration(
          color: AppColors.accentKeepTrack,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        ),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : Text(
                label,
                style: AppStyling.bodySm
                    .copyWith(color: Colors.black, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;

  const _DialogField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppStyling.bodyLg,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyling.bodySm,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(AppStyling.spaceMd),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              borderSide: const BorderSide(color: AppColors.accentKeepTrack),
            ),
          ),
        ),
      ],
    );
  }
}
