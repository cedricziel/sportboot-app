import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_helper.dart';

/// Shows a platform-adaptive alert dialog
Future<T?> showAdaptiveDialog<T>({
  required BuildContext context,
  required String title,
  String? content,
  Widget? contentWidget,
  required List<AdaptiveDialogAction> actions,
  bool barrierDismissible = true,
}) {
  if (PlatformHelper.useIOSStyle) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: contentWidget ?? (content != null ? Text(content) : null),
        actions: actions.map((action) {
          return CupertinoDialogAction(
            onPressed: action.onPressed,
            isDefaultAction: action.isDefault,
            isDestructiveAction: action.isDestructive,
            child: action.child,
          );
        }).toList(),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: contentWidget ?? (content != null ? Text(content) : null),
      actions: actions.map((action) {
        return TextButton(
          onPressed: action.onPressed,
          style: action.isDestructive
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          child: action.child,
        );
      }).toList(),
    ),
  );
}

/// Action for adaptive dialogs
class AdaptiveDialogAction {
  final VoidCallback onPressed;
  final Widget child;
  final bool isDefault;
  final bool isDestructive;

  const AdaptiveDialogAction({
    required this.onPressed,
    required this.child,
    this.isDefault = false,
    this.isDestructive = false,
  });
}
