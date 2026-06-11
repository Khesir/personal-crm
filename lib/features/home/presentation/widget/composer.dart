import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

class Composer extends StatefulWidget {
  final String? activeModel;
  final bool isStreaming;
  final ValueChanged<String> onSend;

  const Composer({
    super.key,
    required this.activeModel,
    required this.isStreaming,
    required this.onSend,
  });

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text;
    if (text.trim().isEmpty || widget.isStreaming) return;
    widget.onSend(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyling.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textController,
            style: AppStyling.bodyLg,
            maxLines: 4,
            minLines: 1,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Message the local assistant…',
              hintStyle: AppStyling.bodySm,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppStyling.spaceSm),
          Row(
            children: [
              if (widget.activeModel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyling.spaceSm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(widget.activeModel!, style: AppStyling.monoSm),
                ),
              const Spacer(),
              IconButton(
                onPressed: widget.isStreaming ? null : _submit,
                icon: const Icon(Icons.send_rounded),
                color: AppColors.accentLight,
                disabledColor: AppColors.textFaint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
