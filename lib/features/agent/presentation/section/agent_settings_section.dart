import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/agent_controller.dart';

const _kDefaultPort = 8765;
const _kProviderValues = ['ollama', 'openai', 'anthropic'];
const _kProviderLabels = ['Ollama (local)', 'OpenAI', 'Anthropic'];

class AgentSettingsSection extends StatefulWidget {
  final AgentController controller;

  const AgentSettingsSection({super.key, required this.controller});

  @override
  State<AgentSettingsSection> createState() => _AgentSettingsSectionState();
}

class _AgentSettingsSectionState extends State<AgentSettingsSection> {
  final _modelController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _portController = TextEditingController(text: '$_kDefaultPort');

  String _provider = _kProviderValues.first;
  bool _isLoading = true;
  bool _serverNotRunning = false;
  bool _portChanged = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _portController.addListener(_onPortChanged);
    _loadConfig();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _apiKeyController.dispose();
    _portController.removeListener(_onPortChanged);
    _portController.dispose();
    super.dispose();
  }

  void _onPortChanged() {
    final port = int.tryParse(_portController.text) ?? _kDefaultPort;
    final changed = port != _kDefaultPort;
    if (changed != _portChanged) {
      setState(() => _portChanged = changed);
    }
  }

  Future<void> _loadConfig() async {
    try {
      final config = await widget.controller.getConfig();
      if (!mounted) return;
      setState(() {
        _provider = config['provider'] as String? ?? _kProviderValues.first;
        _modelController.text = config['model'] as String? ?? '';
        _apiKeyController.text = config['api_key'] as String? ?? '';
        _isLoading = false;
        _serverNotRunning = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _serverNotRunning = true;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final port = int.tryParse(_portController.text) ?? _kDefaultPort;
      await widget.controller.setConfig({
        'provider': _provider,
        'model': _modelController.text.trim(),
        'api_key': _apiKeyController.text.trim(),
        'port': port,
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _showApiKey =>
      _provider == 'openai' || _provider == 'anthropic';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agent', style: AppStyling.pageTitle),
          const SizedBox(height: AppStyling.spaceXs),
          Text(
            'Configure the LLM provider and model used by the agent server.',
            style: AppStyling.pageSub,
          ),
          const SizedBox(height: AppStyling.spaceXxl),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2,
              ),
            )
          else if (_serverNotRunning)
            Text(
              'Agent server not running — start it to configure LLM settings.',
              style: AppStyling.bodySm,
            )
          else
            _Form(
              provider: _provider,
              modelController: _modelController,
              apiKeyController: _apiKeyController,
              portController: _portController,
              showApiKey: _showApiKey,
              portChanged: _portChanged,
              saving: _saving,
              onProviderChanged: (v) => setState(() => _provider = v),
              onSave: _save,
            ),
        ],
      ),
    );
  }
}

class _Form extends StatelessWidget {
  final String provider;
  final TextEditingController modelController;
  final TextEditingController apiKeyController;
  final TextEditingController portController;
  final bool showApiKey;
  final bool portChanged;
  final bool saving;
  final ValueChanged<String> onProviderChanged;
  final VoidCallback onSave;

  const _Form({
    required this.provider,
    required this.modelController,
    required this.apiKeyController,
    required this.portController,
    required this.showApiKey,
    required this.portChanged,
    required this.saving,
    required this.onProviderChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Provider'),
        const SizedBox(height: AppStyling.spaceSm),
        _ProviderDropdown(
          value: provider,
          onChanged: onProviderChanged,
        ),
        const SizedBox(height: AppStyling.spaceLg),
        _FieldLabel('Model'),
        const SizedBox(height: AppStyling.spaceSm),
        _TextField(controller: modelController, hint: 'e.g. llama3, gpt-4o'),
        if (showApiKey) ...[
          const SizedBox(height: AppStyling.spaceLg),
          _FieldLabel('API Key'),
          const SizedBox(height: AppStyling.spaceSm),
          _TextField(
            controller: apiKeyController,
            hint: 'sk-...',
            obscureText: true,
          ),
        ],
        const SizedBox(height: AppStyling.spaceLg),
        _FieldLabel('Agent server port'),
        const SizedBox(height: AppStyling.spaceSm),
        _TextField(
          controller: portController,
          hint: '8765',
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        if (portChanged) ...[
          const SizedBox(height: AppStyling.spaceXs),
          Text(
            'Port change takes effect on next server restart.',
            style: AppStyling.bodySm,
          ),
        ],
        const SizedBox(height: AppStyling.spaceXxl),
        _SaveButton(saving: saving, onSave: onSave),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppStyling.label.copyWith(
      color: AppColors.textSecondary,
    ));
  }
}

class _ProviderDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ProviderDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceMd),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceRaised,
          style: AppStyling.bodyLg,
          iconEnabledColor: AppColors.textSecondary,
          items: [
            for (var i = 0; i < _kProviderValues.length; i++)
              DropdownMenuItem(
                value: _kProviderValues[i],
                child: Text(_kProviderLabels[i], style: AppStyling.bodyLg),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;

  const _TextField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      style: AppStyling.bodyLg,
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppStyling.bodySm,
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceMd,
          vertical: AppStyling.spaceSm,
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
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;

  const _SaveButton({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onSave,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceLg,
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          color: saving ? AppColors.surfaceElevated : AppColors.accent,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        ),
        child: saving
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: AppColors.textSecondary,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Save',
                style: AppStyling.bodySm.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
