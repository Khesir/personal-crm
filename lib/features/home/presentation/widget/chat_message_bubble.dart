import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'markdown_message_body.dart';

class UserMsg extends StatelessWidget {
  final String content;

  const UserMsg({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        margin: const EdgeInsets.symmetric(vertical: AppStyling.spaceSm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceLg,
          vertical: AppStyling.spaceMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentBg,
          borderRadius: BorderRadius.circular(AppStyling.radiusLg),
          border: Border.all(color: AppColors.accentLine),
        ),
        child: Text(content, style: AppStyling.bodyLg),
      ),
    );
  }
}

class BotMsg extends StatelessWidget {
  final String content;
  final bool streaming;

  const BotMsg({super.key, required this.content, this.streaming = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        margin: const EdgeInsets.symmetric(vertical: AppStyling.spaceSm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceLg,
          vertical: AppStyling.spaceMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppStyling.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (content.isEmpty && streaming)
              const _GeneratingIndicator()
            else ...[
              MarkdownMessageBody(content: content),
              if (streaming) ...[
                const SizedBox(height: AppStyling.spaceXs),
                const _GeneratingIndicator(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _GeneratingIndicator extends StatelessWidget {
  const _GeneratingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentLight,
          ),
        ),
        const SizedBox(width: AppStyling.spaceSm),
        Text('generating…', style: AppStyling.label),
      ],
    );
  }
}
