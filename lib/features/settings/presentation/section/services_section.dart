import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/settings_controller.dart';

const _kServiceFields = [
  _EnvField('N8N_BASE_URL', 'n8n Base URL', 'http://localhost:5678', false),
  _EnvField('OLLAMA_BASE_URL', 'Ollama Base URL', 'http://localhost:11434', false),
  _EnvField('DEVCENTER_BACKEND_URL', 'DevCenter Backend URL', 'http://localhost:3000', false),
  _EnvField('CRM_SECRET', 'CRM Secret', 'your-crm-secret', true),
  _EnvField('CLAUDE_API_KEY', 'Claude API Key (optional)', 'sk-ant-...', true),
];

class _EnvField {
  final String key;
  final String label;
  final String hint;
  final bool secret;
  const _EnvField(this.key, this.label, this.hint, this.secret);
}

class ServicesSection extends StatefulWidget {
  final SettingsController controller;

  const ServicesSection({super.key, required this.controller});

  @override
  State<ServicesSection> createState() => _ServicesSectionState();
}

class _ServicesSectionState extends State<ServicesSection> {
  late final Map<String, TextEditingController> _ctrls;
  final Map<String, bool> _obscured = {};
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final f in _kServiceFields)
        f.key: TextEditingController(text: widget.controller.getValue(f.key)),
    };
    for (final f in _kServiceFields) {
      _obscured[f.key] = f.secret;
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    for (final f in _kServiceFields) {
      final value = _ctrls[f.key]!.text.trim();
      await widget.controller.setValue(f.key, value);
    }
    setState(() => _saved = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Services', style: AppStyling.pageTitle),
          const SizedBox(height: AppStyling.spaceXs),
          Text('URLs and secrets used to connect to external services.', style: AppStyling.pageSub),
          const SizedBox(height: AppStyling.spaceXxl),
          ...(_kServiceFields.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: AppStyling.spaceLg),
            child: _EnvFieldWidget(
              field: f,
              controller: _ctrls[f.key]!,
              obscured: _obscured[f.key]!,
              onToggleObscure: () => setState(() => _obscured[f.key] = !_obscured[f.key]!),
            ),
          ))),
          const SizedBox(height: AppStyling.spaceMd),
          Row(
            children: [
              GestureDetector(
                onTap: _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyling.spaceLg,
                    vertical: AppStyling.spaceSm,
                  ),
                  decoration: BoxDecoration(
                    color: _saved ? AppColors.success : AppColors.accent,
                    borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                  ),
                  child: Text(
                    _saved ? 'Saved' : 'Save',
                    style: AppStyling.bodySm.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppStyling.spaceLg),
              Text(
                'Restart the app to apply URL or secret changes.',
                style: AppStyling.bodySm.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnvFieldWidget extends StatelessWidget {
  final _EnvField field;
  final TextEditingController controller;
  final bool obscured;
  final VoidCallback onToggleObscure;

  const _EnvFieldWidget({
    required this.field,
    required this.controller,
    required this.obscured,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(field.label, style: AppStyling.label),
            const SizedBox(width: AppStyling.spaceSm),
            Text(
              field.key,
              style: AppStyling.monoSm.copyWith(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: AppStyling.spaceSm),
        TextField(
          controller: controller,
          obscureText: obscured,
          style: AppStyling.mono,
          decoration: InputDecoration(
            hintText: field.hint,
            hintStyle: AppStyling.bodySm.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppStyling.spaceMd,
              vertical: AppStyling.spaceMd,
            ),
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
            suffixIcon: field.secret
                ? IconButton(
                    icon: Icon(
                      obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
