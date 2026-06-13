import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/health_status.dart';
import '../../domain/model/service_card.dart';
import '../widget/engine_filter_chips.dart';
import 'local_llm_models_section.dart';

/// Composes [EngineFilterChips] (when [engines] is non-empty) with
/// [LocalLlmModelsSection], owning which engine's downloads "Models" is
/// filtered to.
class LocalLlmModelsArea extends StatefulWidget {
  final List<ServiceCard> engines;
  final Map<String, HealthStatus> healthStatuses;
  final Stream<Map<String, HealthStatus>> healthStream;

  const LocalLlmModelsArea({
    super.key,
    required this.engines,
    required this.healthStatuses,
    required this.healthStream,
  });

  @override
  State<LocalLlmModelsArea> createState() => _LocalLlmModelsAreaState();
}

class _LocalLlmModelsAreaState extends State<LocalLlmModelsArea> {
  String? _selectedEngineCardId;

  @override
  Widget build(BuildContext context) {
    if (widget.engines.isEmpty) {
      return const LocalLlmModelsSection();
    }

    final selected = _selectedEngineCardId;
    if (selected != null && !widget.engines.any((card) => card.id == selected)) {
      _selectedEngineCardId = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<Map<String, HealthStatus>>(
          stream: widget.healthStream,
          initialData: widget.healthStatuses,
          builder: (context, snapshot) {
            return EngineFilterChips(
              engines: widget.engines,
              healthStatuses: snapshot.data ?? const {},
              selectedId: _selectedEngineCardId,
              onSelect: (id) => setState(() => _selectedEngineCardId = id),
            );
          },
        ),
        const SizedBox(height: AppStyling.spaceLg),
        LocalLlmModelsSection(filterServiceCardId: _selectedEngineCardId),
      ],
    );
  }
}
