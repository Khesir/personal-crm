import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/theme.dart';

class DesktopTitleBar extends StatelessWidget {
  final String title;

  const DesktopTitleBar({super.key, this.title = 'Codex'});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppStyling.titleBarHeight,
      child: DragToMoveArea(
        child: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceLg),
          child: Row(
            children: [
              Image.asset('assets/icon.png', width: 18, height: 18),
              const SizedBox(width: AppStyling.spaceSm),
              Text(title, style: AppStyling.label),
              const Spacer(),
              _WindowButton(
                onTap: () async => await windowManager.minimize(),
                icon: Icons.remove,
              ),
              const SizedBox(width: AppStyling.spaceXs),
              _WindowButton(
                onTap: () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
                icon: Icons.crop_square_rounded,
              ),
              const SizedBox(width: AppStyling.spaceXs),
              _WindowButton(
                onTap: () async => await windowManager.close(),
                icon: Icons.close,
                isClose: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final bool isClose;

  const _WindowButton({
    required this.onTap,
    required this.icon,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.isClose
        ? AppColors.error.withValues(alpha: 0.8)
        : AppColors.surfaceElevated;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovered ? hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyling.radiusSm),
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: _hovered && widget.isClose
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
