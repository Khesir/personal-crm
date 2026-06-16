import 'dart:io';

import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/home/api.dart';

class ChatPane extends StatefulWidget {
  const ChatPane({super.key});

  @override
  State<ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<ChatPane> {
  ChatController? _controller;

  @override
  void initState() {
    super.initState();
    createChatController().then((controller) {
      if (mounted) setState(() => _controller = controller);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const _ChatSkeleton();
    return HomeChatSection(controller: controller, compact: true);
  }
}

/// Instant shell shown while the controller loads — same visual structure as
/// the compact layout so there is no layout shift when the controller arrives.
class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceElevated,
      child: Column(
        children: [
          Container(
            height: 32,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Fetching models…',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.all(AppStyling.spaceSm),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool isPtyChatSupported() {
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}
