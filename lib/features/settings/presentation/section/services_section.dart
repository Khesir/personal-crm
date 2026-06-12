import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/service_cards_controller.dart';
import '../../domain/model/health_status.dart';
import '../../domain/model/service_card.dart';
import '../dialogs/service_card_form_dialog.dart';

class ServicesSection extends StatefulWidget {
  final ServiceCardsController controller;

  const ServicesSection({super.key, required this.controller});

  @override
  State<ServicesSection> createState() => _ServicesSectionState();
}

class _ServicesSectionState extends State<ServicesSection> {
  @override
  void initState() {
    super.initState();
    // Health checks run for every existing card when Settings > Services mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.checkAllHealth();
    });
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
          Text(
            'Connections used by this app, organized by category.',
            style: AppStyling.pageSub,
          ),
          const SizedBox(height: AppStyling.spaceXxl),
          _CategorySection(
            title: 'Local LLM',
            category: ServiceCategory.localLlm,
            controller: widget.controller,
            availableTypes: const [ServiceType.ollama, ServiceType.customLocal],
          ),
          const SizedBox(height: AppStyling.spaceXxl),
          _CategorySection(
            title: 'API LLM',
            category: ServiceCategory.apiLlm,
            controller: widget.controller,
            availableTypes: const [ServiceType.claudeAnthropic, ServiceType.customApi],
          ),
          const SizedBox(height: AppStyling.spaceXxl),
          _CategorySection(
            title: 'Services',
            category: ServiceCategory.services,
            controller: widget.controller,
            availableTypes: const [ServiceType.n8n, ServiceType.customUrl],
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final ServiceCategory category;
  final ServiceCardsController controller;
  final List<ServiceType> availableTypes;

  const _CategorySection({
    required this.title,
    required this.category,
    required this.controller,
    required this.availableTypes,
  });

  Future<void> _openAddFlow(BuildContext context) async {
    if (availableTypes.isEmpty) return;

    ServiceType? type = availableTypes.length == 1 ? availableTypes.first : null;
    type ??= await showDialog<ServiceType>(
      context: context,
      builder: (_) => _TypePickerDialog(types: availableTypes),
    );
    if (type == null || !context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) => ServiceCardFormDialog(
        controller: controller,
        category: category,
        type: type!,
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, ServiceCard card) async {
    await showDialog(
      context: context,
      builder: (_) => ServiceCardFormDialog(
        controller: controller,
        category: category,
        type: card.type,
        card: card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: AppStyling.headingLg),
            ),
            GestureDetector(
              onTap: () => _openAddFlow(context),
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
                  'Add',
                  style: AppStyling.bodySm.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppStyling.spaceLg),
        AsyncStreamBuilder<List<ServiceCard>>(
          state: controller,
          builder: (context, cards) {
            final categoryCards = cards.where((c) => c.category == category).toList();
            if (categoryCards.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceXl),
                  child: Text('Nothing here yet.', style: AppStyling.bodySm),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categoryCards.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppStyling.spaceMd),
              itemBuilder: (context, index) {
                final card = categoryCards[index];
                final sameTypeCount = categoryCards.where((c) => c.type == card.type).length;
                return StreamBuilder<Map<String, HealthStatus>>(
                  stream: controller.healthStream,
                  initialData: controller.healthStatuses,
                  builder: (context, snapshot) {
                    final status = snapshot.data?[card.id];
                    return _ServiceCard(
                      card: card,
                      status: status,
                      showSetDefault: sameTypeCount > 1 && !card.isDefault,
                      onEdit: () => _openEditDialog(context, card),
                      onDelete: () => controller.removeCard(card.id),
                      onRefresh: () => controller.checkHealth(card),
                      onSetDefault: () => controller.setDefault(card.type, card.id),
                      onToggleEnabled: () => controller.toggleCardEnabled(card.id),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _TypePickerDialog extends StatelessWidget {
  final List<ServiceType> types;

  const _TypePickerDialog({required this.types});

  String _label(ServiceType type) => switch (type) {
        ServiceType.ollama => 'Ollama',
        ServiceType.customLocal => 'Custom Local (OpenAI-compatible)',
        ServiceType.claudeAnthropic => 'Claude (Anthropic)',
        ServiceType.customApi => 'Custom API',
        ServiceType.n8n => 'n8n',
        ServiceType.customUrl => 'Custom URL',
      };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppStyling.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add service', style: AppStyling.headingMd),
            const SizedBox(height: AppStyling.spaceMd),
            for (final type in types)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_label(type), style: AppStyling.bodyLg),
                onTap: () => Navigator.of(context).pop(type),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceCard card;
  final HealthStatus? status;
  final bool showSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  final VoidCallback onSetDefault;
  final VoidCallback onToggleEnabled;

  const _ServiceCard({
    required this.card,
    required this.status,
    required this.showSetDefault,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
    required this.onSetDefault,
    required this.onToggleEnabled,
  });

  String get _typeLabel => switch (card.type) {
        ServiceType.ollama => 'Ollama',
        ServiceType.customLocal => 'Custom Local (OpenAI-compatible)',
        ServiceType.claudeAnthropic => 'Claude (Anthropic)',
        ServiceType.customApi => 'Custom API',
        ServiceType.n8n => 'n8n',
        ServiceType.customUrl => 'Custom URL',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyling.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(card.name, style: AppStyling.headingMd),
                    const SizedBox(width: AppStyling.spaceSm),
                    Text(
                      _typeLabel,
                      style: AppStyling.monoSm.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(width: AppStyling.spaceSm),
                    _StatusBadge(status: status),
                    if (card.isDefault) ...[
                      const SizedBox(width: AppStyling.spaceSm),
                      const _Tag(label: 'Default'),
                    ],
                  ],
                ),
                const SizedBox(height: AppStyling.spaceXs),
                if (card.fields['baseUrl'] != null)
                  Text(
                    card.fields['baseUrl']!,
                    style: AppStyling.monoSm.copyWith(color: AppColors.textSecondary),
                  ),
                if (card.fields['secret'] != null && card.fields['secret']!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppStyling.spaceXs),
                    child: Text(
                      'Secret: ••••••••',
                      style: AppStyling.monoSm.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                if (card.fields['apiKey'] != null && card.fields['apiKey']!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppStyling.spaceXs),
                    child: Text(
                      'API Key: ••••••••',
                      style: AppStyling.monoSm.copyWith(color: AppColors.textMuted),
                    ),
                  ),
              ],
            ),
          ),
          Tooltip(
            message: card.enabled ? 'Disable' : 'Enable',
            child: Switch(
              value: card.enabled,
              onChanged: (_) => onToggleEnabled(),
              activeThumbColor: AppColors.accent,
            ),
          ),
          if (showSetDefault)
            IconButton(
              onPressed: onSetDefault,
              icon: const Icon(Icons.star_outline, size: 18, color: AppColors.textSecondary),
              tooltip: 'Set as Default',
            ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final HealthStatus? status;

  const _StatusBadge({required this.status});

  Color get _color => switch (status) {
        HealthStatus.online => AppColors.success,
        HealthStatus.offline => AppColors.textMuted,
        HealthStatus.error => AppColors.error,
        HealthStatus.checking => AppColors.warning,
        null => AppColors.textMuted,
      };

  String get _label => switch (status) {
        HealthStatus.online => 'Online',
        HealthStatus.offline => 'Offline',
        HealthStatus.error => 'Error',
        HealthStatus.checking => 'Checking',
        null => 'Unknown',
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppStyling.spaceXs),
        Text(_label, style: AppStyling.monoSm.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceSm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentBg,
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
      ),
      child: Text(
        label,
        style: AppStyling.monoSm.copyWith(color: AppColors.accentLight),
      ),
    );
  }
}
