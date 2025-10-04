import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_helper.dart';

/// Platform-adaptive primary button
class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final bool isDestructive;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.useIOSStyle) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        disabledColor: CupertinoColors.quaternarySystemFill,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? Colors.red : color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: child,
    );
  }
}

/// Platform-adaptive text button
class AdaptiveTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;

  const AdaptiveTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.useIOSStyle) {
      return CupertinoButton(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DefaultTextStyle(
          style: TextStyle(
            color: color ?? CupertinoColors.activeBlue,
            fontSize: 17,
          ),
          child: child,
        ),
      );
    }

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color),
      child: child,
    );
  }
}
