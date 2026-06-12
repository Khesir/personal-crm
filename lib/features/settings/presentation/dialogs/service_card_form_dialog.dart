import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/home/data/datasource/anthropic_datasource.dart';
import 'package:crm/features/home/data/datasource/ollama_datasource.dart';
import 'package:crm/features/home/data/datasource/openai_compatible_datasource.dart';
import 'package:crm/features/home/data/repository/anthropic_repository_impl.dart';
import 'package:crm/features/home/data/repository/ollama_repository_impl.dart';
import 'package:crm/features/home/data/repository/openai_compatible_repository_impl.dart';
import 'package:crm/features/home/domain/repository/chat_model_repository.dart';
import '../../domain/controller/service_cards_controller.dart';
import '../../domain/model/service_card.dart';
import '../../domain/model/service_type_metadata.dart';

const _kDialogWidth = 480.0;

/// Builds the [ChatModelRepository] matching [card]'s type, pointed at its
/// configured base URL. Mirrors `home/di.dart`'s `_repositoryFor`.
ChatModelRepository _repositoryForCard(ServiceCard card) {
  final baseDio = Dio(BaseOptions(
    baseUrl: card.fields['baseUrl'] ?? '',
    connectTimeout: const Duration(seconds: 10),
    contentType: 'application/json',
  ));
  return switch (card.type) {
    ServiceType.ollama => OllamaRepositoryImpl(OllamaDatasource(baseDio)),
    ServiceType.customLocal => OpenAiCompatibleRepositoryImpl(OpenAiCompatibleDatasource(baseDio)),
    ServiceType.customApi ||
    ServiceType.groq ||
    ServiceType.gemini ||
    ServiceType.openRouter ||
    ServiceType.openai ||
    ServiceType.deepSeek ||
    ServiceType.mistral ||
    ServiceType.nvidia ||
    ServiceType.openCodeZen =>
      OpenAiCompatibleRepositoryImpl(OpenAiCompatibleDatasource(Dio(BaseOptions(
        baseUrl: card.fields['baseUrl'] ?? '',
        connectTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
        headers: {'Authorization': 'Bearer ${card.fields['apiKey'] ?? ''}'},
      )))),
    ServiceType.claudeAnthropic => AnthropicRepositoryImpl(AnthropicDatasource(Dio(BaseOptions(
        baseUrl: 'https://api.anthropic.com',
        connectTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
        headers: {
          'x-api-key': card.fields['apiKey'] ?? '',
          'anthropic-version': '2023-06-01',
        },
      )))),
    _ => throw ArgumentError('${card.type} is not a chat-capable type'),
  };
}

class ServiceCardFormDialog extends StatefulWidget {
  final ServiceCardsController controller;
  final ServiceCategory category;
  final ServiceType type;
  final ServiceCard? card;

  const ServiceCardFormDialog({
    super.key,
    required this.controller,
    required this.category,
    required this.type,
    this.card,
  });

  @override
  State<ServiceCardFormDialog> createState() => _ServiceCardFormDialogState();
}

class _ServiceCardFormDialogState extends State<ServiceCardFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _secretCtrl;
  late final TextEditingController _apiKeyCtrl;
  bool _secretObscured = true;
  bool _apiKeyObscured = true;
  bool _saving = false;

  bool _modelsLoading = false;
  List<String>? _models;
  bool _modelsError = false;

  bool get _isEditing => widget.card != null;

  bool get _showSecretField => widget.type == ServiceType.customUrl;

  bool get _showBaseUrlField => widget.type != ServiceType.claudeAnthropic;

  bool get _showApiKeyField =>
      widget.type == ServiceType.claudeAnthropic ||
      widget.type == ServiceType.customApi ||
      widget.type == ServiceType.groq ||
      widget.type == ServiceType.gemini ||
      widget.type == ServiceType.openRouter ||
      widget.type == ServiceType.openai ||
      widget.type == ServiceType.deepSeek ||
      widget.type == ServiceType.mistral ||
      widget.type == ServiceType.nvidia ||
      widget.type == ServiceType.openCodeZen;

  bool get _isLocalLlmType =>
      widget.type == ServiceType.ollama || widget.type == ServiceType.customLocal;

  bool get _isApiLlmType =>
      widget.type == ServiceType.claudeAnthropic ||
      widget.type == ServiceType.customApi ||
      widget.type == ServiceType.groq ||
      widget.type == ServiceType.gemini ||
      widget.type == ServiceType.openRouter ||
      widget.type == ServiceType.openai ||
      widget.type == ServiceType.deepSeek ||
      widget.type == ServiceType.mistral ||
      widget.type == ServiceType.nvidia ||
      widget.type == ServiceType.openCodeZen;

  bool get _showModelChecklist => _isEditing && (_isLocalLlmType || _isApiLlmType);

  String get _typeLabel => kServiceTypeLabels[widget.type]!;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _nameCtrl = TextEditingController(text: card?.name ?? _typeLabel);
    final defaultBaseUrl =
        card == null && _showBaseUrlField ? kServiceTypeDefaultBaseUrls[widget.type] : null;
    _baseUrlCtrl = TextEditingController(text: card?.fields['baseUrl'] ?? defaultBaseUrl ?? '');
    _secretCtrl = TextEditingController(text: card?.fields['secret'] ?? '');
    _apiKeyCtrl = TextEditingController(text: card?.fields['apiKey'] ?? '');

    if (_showModelChecklist) _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _modelsLoading = true;
      _modelsError = false;
      _models = null;
    });

    try {
      final models = await _repositoryForCard(widget.card!).listModels();
      if (!mounted) return;
      setState(() {
        _models = models;
        _modelsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _modelsError = true;
        _modelsLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _baseUrlCtrl.dispose();
    _secretCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final baseUrl = _baseUrlCtrl.text.trim();
    final apiKey = _apiKeyCtrl.text.trim();
    if (name.isEmpty) return;
    if (_showBaseUrlField && baseUrl.isEmpty) return;
    if (_showApiKeyField && apiKey.isEmpty) return;

    final secret = _secretCtrl.text.trim();
    final fields = <String, String>{
      if (_showBaseUrlField) 'baseUrl': baseUrl,
      if (_showApiKeyField && apiKey.isNotEmpty) 'apiKey': apiKey,
      if (_showSecretField && secret.isNotEmpty) 'secret': secret,
    };

    setState(() => _saving = true);

    ServiceCard saved;
    if (_isEditing) {
      saved = widget.card!.copyWith(name: name, fields: fields);
      await widget.controller.updateCard(saved);
    } else {
      saved = ServiceCard(
        id: '${widget.type.value}-${DateTime.now().microsecondsSinceEpoch}',
        category: widget.category,
        type: widget.type,
        name: name,
        fields: fields,
      );
      await widget.controller.addCard(saved);
    }

    // Health check this card only.
    final current = widget.controller.data ?? [];
    for (final c in current) {
      if (c.id == saved.id) {
        unawaited(widget.controller.checkHealth(c));
        break;
      }
    }

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
              Text(
                _isEditing ? 'Edit $_typeLabel' : 'Add $_typeLabel',
                style: AppStyling.headingMd,
              ),
              const SizedBox(height: AppStyling.spaceXl),
              _NameField(controller: _nameCtrl),
              if (_showBaseUrlField) ...[
                const SizedBox(height: AppStyling.spaceLg),
                _BaseUrlField(controller: _baseUrlCtrl),
              ],
              if (_showSecretField) ...[
                const SizedBox(height: AppStyling.spaceLg),
                _SecretField(
                  controller: _secretCtrl,
                  obscured: _secretObscured,
                  label: 'Secret (optional)',
                  hintText: 'your-crm-secret',
                  onToggleObscure: () => setState(() => _secretObscured = !_secretObscured),
                ),
              ],
              if (_showApiKeyField) ...[
                const SizedBox(height: AppStyling.spaceLg),
                _SecretField(
                  controller: _apiKeyCtrl,
                  obscured: _apiKeyObscured,
                  label: 'API Key',
                  hintText: widget.type == ServiceType.claudeAnthropic ? 'sk-ant-...' : 'sk-...',
                  onToggleObscure: () => setState(() => _apiKeyObscured = !_apiKeyObscured),
                ),
              ],
              if (_showModelChecklist) ...[
                const SizedBox(height: AppStyling.spaceXl),
                _ModelChecklist(
                  loading: _modelsLoading,
                  models: _models,
                  error: _modelsError,
                  card: widget.card!,
                  controller: widget.controller,
                ),
              ],
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

class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name', style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        TextField(
          controller: controller,
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
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }
}

class _BaseUrlField extends StatelessWidget {
  final TextEditingController controller;

  const _BaseUrlField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Base URL', style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        TextField(
          controller: controller,
          style: AppStyling.mono,
          decoration: InputDecoration(
            hintText: 'http://localhost:5678',
            hintStyle: AppStyling.bodySm.copyWith(color: AppColors.textMuted),
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

class _SecretField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscured;
  final String label;
  final String hintText;
  final VoidCallback onToggleObscure;

  const _SecretField({
    required this.controller,
    required this.obscured,
    required this.label,
    required this.hintText,
    required this.onToggleObscure,
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
          obscureText: obscured,
          style: AppStyling.mono,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppStyling.bodySm.copyWith(color: AppColors.textMuted),
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
            suffixIcon: IconButton(
              icon: Icon(
                obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ],
    );
  }
}

/// Per-model enable/disable checklist for a Local LLM or API LLM card, shown
/// when editing an existing Ollama, Custom Local, Claude Anthropic, or
/// Custom API card. Populated via [ChatModelRepository.listModels]; toggling
/// a checkbox persists through [ServiceCardsController.toggleModelEnabled].
class _ModelChecklist extends StatelessWidget {
  final bool loading;
  final List<String>? models;
  final bool error;
  final ServiceCard card;
  final ServiceCardsController controller;

  const _ModelChecklist({
    required this.loading,
    required this.models,
    required this.error,
    required this.card,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Models', style: AppStyling.label),
        const SizedBox(height: AppStyling.spaceSm),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppStyling.spaceSm),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (error || models == null)
          Text('Unable to load models', style: AppStyling.bodySm.copyWith(color: AppColors.textMuted))
        else if (models!.isEmpty)
          Text('No models found', style: AppStyling.bodySm.copyWith(color: AppColors.textMuted))
        else
          StreamStateBuilder<AsyncState<List<ServiceCard>>>(
            state: controller,
            builder: (context, asyncState) {
              final cards = asyncState is AsyncData<List<ServiceCard>> ? asyncState.data : <ServiceCard>[];
              final current = cards.firstWhere(
                (c) => c.id == card.id,
                orElse: () => card,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final model in models!)
                    _ModelCheckboxRow(
                      model: model,
                      enabled: !current.disabledModels.contains(model),
                      onChanged: (_) => controller.toggleModelEnabled(card.id, model),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ModelCheckboxRow extends StatelessWidget {
  final String model;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  const _ModelCheckboxRow({
    required this.model,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!enabled),
      borderRadius: BorderRadius.circular(AppStyling.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: enabled,
              onChanged: onChanged,
              activeColor: AppColors.accent,
            ),
            Expanded(
              child: Text(model, style: AppStyling.mono),
            ),
          ],
        ),
      ),
    );
  }
}
