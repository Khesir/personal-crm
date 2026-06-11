import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/core/state/state.dart';
import '../../domain/controller/announcements_controller.dart';
import '../../domain/model/announcement.dart';

class AnnouncementsSection extends StatelessWidget {
  final AnnouncementsController controller;

  const AnnouncementsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(controller: controller),
        Expanded(
          child: AsyncStreamBuilder<List<Announcement>>(
            state: controller,
            loadingBuilder: (_) => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            errorBuilder: (_, __) => Center(
              child: Text(
                'Could not load announcements.',
                style: AppStyling.bodySm,
              ),
            ),
            builder: (context, list) => _AnnouncementList(
              announcements: list,
              controller: controller,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final AnnouncementsController controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyling.spaceXl,
        vertical: AppStyling.spaceLg,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Announcements', style: AppStyling.headingLg),
              Text('Publish updates for this project',
                  style: AppStyling.bodySm),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) =>
                  _CreateAnnouncementDialog(controller: controller),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyling.spaceLg,
                vertical: AppStyling.spaceSm,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              ),
              child: Text(
                'New Announcement',
                style: AppStyling.bodySm.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateAnnouncementDialog extends StatefulWidget {
  final AnnouncementsController controller;

  const _CreateAnnouncementDialog({required this.controller});

  @override
  State<_CreateAnnouncementDialog> createState() =>
      _CreateAnnouncementDialogState();
}

class _CreateAnnouncementDialogState extends State<_CreateAnnouncementDialog>
    with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _ctaLabelCtrl = TextEditingController();
  final _ctaUrlCtrl = TextEditingController();
  AnnouncementType _type = AnnouncementType.info;
  bool _loading = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bodyCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _ctaLabelCtrl.dispose();
    _ctaUrlCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool published}) async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await widget.controller.create(
      _titleCtrl.text.trim(),
      _bodyCtrl.text.trim(),
      _type,
      published: published,
      ctaLabel: _ctaLabelCtrl.text.trim(),
      ctaUrl: _ctaUrlCtrl.text.trim(),
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
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Announcement', style: AppStyling.headingMd),
              const SizedBox(height: AppStyling.spaceXl),
              _TextField(label: 'Title', controller: _titleCtrl, maxLines: 1),
              const SizedBox(height: AppStyling.spaceLg),
              _MarkdownBodyField(
                bodyCtrl: _bodyCtrl,
                tabController: _tabController,
              ),
              const SizedBox(height: AppStyling.spaceLg),
              _TypeDropdown(
                value: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: AppStyling.spaceLg),
              _TextField(label: 'CTA Label (optional)', controller: _ctaLabelCtrl, maxLines: 1),
              const SizedBox(height: AppStyling.spaceSm),
              _TextField(label: 'CTA URL (optional)', controller: _ctaUrlCtrl, maxLines: 1),
              const SizedBox(height: AppStyling.spaceXl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: AppStyling.bodySm),
                  ),
                  const SizedBox(width: AppStyling.spaceLg),
                  GestureDetector(
                    onTap: _loading ? null : () => _submit(published: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyling.spaceLg,
                        vertical: AppStyling.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                      ),
                      child: Text(
                        'Save Draft',
                        style: AppStyling.bodySm.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppStyling.spaceSm),
                  GestureDetector(
                    onTap: _loading ? null : () => _submit(published: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyling.spaceLg,
                        vertical: AppStyling.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'Publish',
                              style: AppStyling.bodySm.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
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

class _MarkdownBodyField extends StatefulWidget {
  final TextEditingController bodyCtrl;
  final TabController tabController;

  const _MarkdownBodyField({
    required this.bodyCtrl,
    required this.tabController,
  });

  @override
  State<_MarkdownBodyField> createState() => _MarkdownBodyFieldState();
}

class _MarkdownBodyFieldState extends State<_MarkdownBodyField> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (widget.tabController.indexIsChanging) return;
    setState(() => _tab = widget.tabController.index);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _wrap(String before, String after) {
    final ctrl = widget.bodyCtrl;
    final sel = ctrl.selection;
    if (!sel.isValid) return;
    final text = ctrl.text;
    final selected = sel.textInside(text);
    final replacement = '$before$selected$after';
    final newText = text.replaceRange(sel.start, sel.end, replacement);
    ctrl.value = ctrl.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + replacement.length),
    );
  }

  void _insertLine(String prefix) {
    final ctrl = widget.bodyCtrl;
    final sel = ctrl.selection;
    if (!sel.isValid) return;
    final text = ctrl.text;
    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    ctrl.value = ctrl.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + prefix.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Body', style: AppStyling.label),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: widget.tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorColor: AppColors.accent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: AppStyling.bodySm.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppStyling.bodySm,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textMuted,
                tabs: const [
                  Tab(text: 'Write'),
                  Tab(text: 'Preview'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppStyling.spaceSm),
        if (_tab == 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppStyling.radiusMd),
                topRight: Radius.circular(AppStyling.radiusMd),
              ),
            ),
            child: Row(
              children: [
                _ToolbarBtn(icon: Icons.format_bold, tooltip: 'Bold', onTap: () => _wrap('**', '**')),
                _ToolbarBtn(icon: Icons.format_italic, tooltip: 'Italic', onTap: () => _wrap('*', '*')),
                _ToolbarBtn(icon: Icons.strikethrough_s, tooltip: 'Strikethrough', onTap: () => _wrap('~~', '~~')),
                const _ToolbarDivider(),
                _ToolbarBtn(icon: Icons.code, tooltip: 'Inline code', onTap: () => _wrap('`', '`')),
                _ToolbarBtn(icon: Icons.data_object, tooltip: 'Code block', onTap: () => _wrap('```\n', '\n```')),
                const _ToolbarDivider(),
                _ToolbarBtn(icon: Icons.format_list_bulleted, tooltip: 'Bullet list', onTap: () => _insertLine('- ')),
                _ToolbarBtn(icon: Icons.format_list_numbered, tooltip: 'Numbered list', onTap: () => _insertLine('1. ')),
                _ToolbarBtn(icon: Icons.format_quote, tooltip: 'Blockquote', onTap: () => _insertLine('> ')),
                const _ToolbarDivider(),
                _ToolbarBtn(icon: Icons.link, tooltip: 'Link', onTap: () => _wrap('[', '](url)')),
              ],
            ),
          ),
        SizedBox(
          height: 200,
          child: IndexedStack(
            index: _tab,
            children: [
              TextField(
                controller: widget.bodyCtrl,
                maxLines: null,
                expands: true,
                style: AppStyling.bodyLg.copyWith(fontFamily: 'monospace'),
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  hintText: 'Supports markdown...',
                  hintStyle: AppStyling.bodySm.copyWith(color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.all(AppStyling.spaceMd),
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppStyling.radiusMd),
                      bottomRight: Radius.circular(AppStyling.radiusMd),
                    ),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppStyling.radiusMd),
                      bottomRight: Radius.circular(AppStyling.radiusMd),
                    ),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppStyling.radiusMd),
                      bottomRight: Radius.circular(AppStyling.radiusMd),
                    ),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(AppStyling.spaceMd),
                child: widget.bodyCtrl.text.trim().isEmpty
                    ? Center(
                        child: Text(
                          'Nothing to preview',
                          style: AppStyling.bodySm.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    : Markdown(
                        data: widget.bodyCtrl.text,
                        shrinkWrap: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: AppStyling.bodySm,
                          code: AppStyling.bodySm.copyWith(fontFamily: 'monospace', backgroundColor: AppColors.border),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  final AnnouncementType value;
  final ValueChanged<AnnouncementType> onChanged;

  const _TypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type', style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyling.spaceMd,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyling.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<AnnouncementType>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.surfaceElevated,
            style: AppStyling.bodyLg,
            onChanged: (v) => onChanged(v!),
            items: AnnouncementType.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _TextField({
    required this.label,
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
                  const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnnouncementList extends StatelessWidget {
  final List<Announcement> announcements;
  final AnnouncementsController controller;

  const _AnnouncementList({
    required this.announcements,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return Center(
        child: Text('No announcements yet', style: AppStyling.bodySm),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      itemCount: announcements.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppStyling.spaceMd),
      itemBuilder: (context, i) => _AnnouncementCard(
        announcement: announcements[i],
        controller: controller,
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final AnnouncementsController controller;

  const _AnnouncementCard({
    required this.announcement,
    required this.controller,
  });

  Color _typeColor(AnnouncementType type) => switch (type) {
        AnnouncementType.info => AppColors.info,
        AnnouncementType.warning => AppColors.warning,
        AnnouncementType.release => AppColors.accent,
        AnnouncementType.update => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _typeColor(announcement.type);

    return Container(
      padding: const EdgeInsets.all(AppStyling.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyling.spaceSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                ),
                child: Text(
                  announcement.type.label.toUpperCase(),
                  style: AppStyling.monoSm.copyWith(color: accent),
                ),
              ),
              if (!announcement.published) ...[
                const SizedBox(width: AppStyling.spaceSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyling.spaceSm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppStyling.radiusSm),
                  ),
                  child: Text(
                    'DRAFT',
                    style:
                        AppStyling.monoSm.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => _EditAnnouncementDialog(
                    announcement: announcement,
                    controller: controller,
                  ),
                ),
                child: Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
              ),
              const SizedBox(width: AppStyling.spaceSm),
              GestureDetector(
                onTap: () => controller.delete(announcement.id),
                child: Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppStyling.spaceMd),
          Text(announcement.title, style: AppStyling.headingMd),
          const SizedBox(height: AppStyling.spaceSm),
          Text(announcement.body, style: AppStyling.bodySm),
          const SizedBox(height: AppStyling.spaceMd),
          Text(
            _formatDate(announcement.publishedAt ?? announcement.createdAt),
            style: AppStyling.monoSm,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _EditAnnouncementDialog extends StatefulWidget {
  final Announcement announcement;
  final AnnouncementsController controller;

  const _EditAnnouncementDialog({required this.announcement, required this.controller});

  @override
  State<_EditAnnouncementDialog> createState() => _EditAnnouncementDialogState();
}

class _EditAnnouncementDialogState extends State<_EditAnnouncementDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _ctaLabelCtrl;
  late final TextEditingController _ctaUrlCtrl;
  late AnnouncementType _type;
  late bool _published;
  bool _loading = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final a = widget.announcement;
    _titleCtrl = TextEditingController(text: a.title);
    _bodyCtrl = TextEditingController(text: a.body);
    _ctaLabelCtrl = TextEditingController(text: a.ctaLabel ?? '');
    _ctaUrlCtrl = TextEditingController(text: a.ctaUrl ?? '');
    _type = a.type;
    _published = a.published;
    _tabController = TabController(length: 2, vsync: this);
    _bodyCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _ctaLabelCtrl.dispose();
    _ctaUrlCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await widget.controller.edit(
      widget.announcement.id,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      type: _type,
      published: _published,
      ctaLabel: _ctaLabelCtrl.text.trim(),
      ctaUrl: _ctaUrlCtrl.text.trim(),
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
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Announcement', style: AppStyling.headingMd),
              const SizedBox(height: AppStyling.spaceXl),
              _TextField(label: 'Title', controller: _titleCtrl, maxLines: 1),
              const SizedBox(height: AppStyling.spaceLg),
              _MarkdownBodyField(bodyCtrl: _bodyCtrl, tabController: _tabController),
              const SizedBox(height: AppStyling.spaceLg),
              _TypeDropdown(value: _type, onChanged: (v) => setState(() => _type = v)),
              const SizedBox(height: AppStyling.spaceLg),
              _TextField(label: 'CTA Label (optional)', controller: _ctaLabelCtrl, maxLines: 1),
              const SizedBox(height: AppStyling.spaceSm),
              _TextField(label: 'CTA URL (optional)', controller: _ctaUrlCtrl, maxLines: 1),
              const SizedBox(height: AppStyling.spaceLg),
              Row(
                children: [
                  Switch(
                    value: _published,
                    onChanged: (v) => setState(() => _published = v),
                    activeColor: AppColors.accent,
                  ),
                  const SizedBox(width: AppStyling.spaceSm),
                  Text(_published ? 'Published' : 'Draft', style: AppStyling.bodySm),
                ],
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
                  GestureDetector(
                    onTap: _loading ? null : _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyling.spaceLg,
                        vertical: AppStyling.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              'Save',
                              style: AppStyling.bodySm.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
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

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.border,
    );
  }
}
