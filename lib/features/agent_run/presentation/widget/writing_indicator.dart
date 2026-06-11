import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';

class WritingIndicator extends StatefulWidget {
  const WritingIndicator({super.key});

  @override
  State<WritingIndicator> createState() => _WritingIndicatorState();
}

class _WritingIndicatorState extends State<WritingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceXs),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CircularProgressIndicator(
                  strokeWidth: 2,
                  value: null,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accentLight),
                  backgroundColor: AppColors.surfaceRaised,
                );
              },
            ),
          ),
          const SizedBox(width: AppStyling.spaceSm),
          Text('writing…', style: AppStyling.bodySm),
        ],
      ),
    );
  }
}
