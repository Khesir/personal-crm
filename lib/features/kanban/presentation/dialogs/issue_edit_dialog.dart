import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/issues_controller.dart';
import '../../domain/model/issue.dart';

const _kDialogWidth = 560.0;

class IssueEditDialog extends StatefulWidget {
  final IssuesController controller;
  final Issue issue;

  const IssueEditDialog({super.key, required this.controller, required this.issue});

  @override
  State<IssueEditDialog> createState() => _IssueEditDialogState();
}

class _IssueEditDialogState extends State<IssueEditDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _featureCtrl;
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _bodyCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final issue = widget.issue;
    _titleCtrl = TextEditingController(text: issue.title);
    _featureCtrl = TextEditingController(text: issue.feature);
    _tagsCtrl = TextEditingController(text: issue.tags.join(', '));
    _bodyCtrl = TextEditingController(text: issue.body);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _featureCtrl.dispose();
    _tagsCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final tags = _tagsCtrl.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    await widget.controller.updateIssue(
      widget.issue,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text,
      feature: _featureCtrl.text.trim(),
      tags: tags,
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
        width: _kDialogWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Issue', style: AppStyling.headingMd),
              const SizedBox(height: AppStyling.spaceXl),
              _Field(label: 'Title', controller: _titleCtrl),
              const SizedBox(height: AppStyling.spaceLg),
              _Field(label: 'Feature', controller: _featureCtrl),
              const SizedBox(height: AppStyling.spaceLg),
              _Field(label: 'Tags (comma-separated)', controller: _tagsCtrl),
              const SizedBox(height: AppStyling.spaceLg),
              _Field(label: 'Body (markdown)', controller: _bodyCtrl, maxLines: 12, mono: true),
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
                    onTap: _saving ? null : _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyling.spaceLg,
                        vertical: AppStyling.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                      ),
                      child: _saving
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool mono;

  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.mono = false,
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
          style: mono ? AppStyling.mono : AppStyling.bodyLg,
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
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }
}
