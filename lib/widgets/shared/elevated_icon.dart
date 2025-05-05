import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

IconData getBackIcon(BuildContext context) {
  if (kIsWeb) {
    // Always use 'Icons.arrow_back' as a back_button icon in web.
    return Icons.arrow_back;
  }
  switch (Theme.of(context).platform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return Icons.arrow_back;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return Icons.arrow_back_ios;
  }
}

class ElevatedIconButton extends ConsumerWidget {
  final Function() onPressed;
  final IconData icon;
  final Color? color;
  const ElevatedIconButton({required this.onPressed, required this.icon, this.color, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: onPressed,
      style: IconButtonTheme.of(context).style?.copyWith(
            backgroundColor: WidgetStatePropertyAll(color?.withValues(alpha: 0.15)),
          ),
      color: color,
      icon: Icon(icon),
    );
  }
}

class ElevatedIconButtonLabel extends StatelessWidget {
  final Function() onPressed;
  final String label;
  final IconData icon;
  final Color? color;
  const ElevatedIconButtonLabel({
    required this.onPressed,
    required this.label,
    required this.icon,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 65),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedIconButton(onPressed: onPressed, icon: icon),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
