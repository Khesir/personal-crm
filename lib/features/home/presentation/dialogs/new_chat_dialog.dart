import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/settings/domain/model/project.dart';
import '../../domain/model/cookbook_entry.dart';
import 'agent_mode_picker_dialog.dart';

const _kDialogWidth = 420.0;

/// Whether the user wants a plain chat or an agent-mode chat scoped to a
/// project, and (if agent mode) the chosen project + tool-capable model.
class NewChatSelection {
  final bool agentMode;
  final AgentModeSelection? agentModeSelection;

  const NewChatSelection({required this.agentMode, this.agentModeSelection});
}

/// The "New chat" dialog: an Agent mode toggle that, when enabled, opens
/// [AgentModePickerDialog] to choose a project and tool-capable model.
///
/// When Agent mode is off, [show] resolves with `NewChatSelection(agentMode:
/// false)` — the caller should fall back to the existing plain
/// `newConversation()` flow.
class NewChatDialog extends StatefulWidget {
  final List<Project> projects;
  final List<CookbookEntry> agentCapableCookbook;

  const NewChatDialog({
    super.key,
    required this.projects,
    required this.agentCapableCookbook,
  });

  static Future<NewChatSelection?> show(
    BuildContext context, {
    required List<Project> projects,
    required List<CookbookEntry> agentCapableCookbook,
  }) {
    return showDialog<NewChatSelection>(
      context: context,
      builder: (_) => NewChatDialog(projects: projects, agentCapableCookbook: agentCapableCookbook),
    );
  }

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  bool _agentMode = false;

  Future<void> _confirm() async {
    if (!_agentMode) {
      Navigator.of(context).pop(const NewChatSelection(agentMode: false));
      return;
    }

    final selection = await AgentModePickerDialog.show(
      context,
      projects: widget.projects,
      cookbook: widget.agentCapableCookbook,
    );
    if (selection == null) return;
    if (!mounted) return;
    Navigator.of(context).pop(NewChatSelection(agentMode: true, agentModeSelection: selection));
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
        child: Padding(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New chat', style: AppStyling.headingMd),
              const SizedBox(height: AppStyling.spaceLg),
              Row(
                children: [
                  Switch(
                    value: _agentMode,
                    onChanged: (v) => setState(() => _agentMode = v),
                    activeThumbColor: AppColors.accent,
                  ),
                  const SizedBox(width: AppStyling.spaceSm),
                  Text('Agent mode', style: AppStyling.bodySm),
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
                    onTap: _confirm,
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
                        'Continue',
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
