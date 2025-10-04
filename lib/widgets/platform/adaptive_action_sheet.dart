import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_helper.dart';

/// Shows a platform-adaptive action sheet / bottom sheet
Future<T?> showAdaptiveActionSheet<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<AdaptiveActionSheetAction> actions,
  AdaptiveActionSheetAction? cancelAction,
}) {
  if (PlatformHelper.useIOSStyle) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        message: message != null ? Text(message) : null,
        actions: actions.map((action) {
          return CupertinoActionSheetAction(
            onPressed: action.onPressed,
            isDestructiveAction: action.isDestructive,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.icon != null) ...[
                  Icon(action.icon, size: 20),
                  const SizedBox(width: 8),
                ],
                action.child,
              ],
            ),
          );
        }).toList(),
        cancelButton: cancelAction != null
            ? CupertinoActionSheetAction(
                onPressed: cancelAction.onPressed,
                isDefaultAction: true,
                child: cancelAction.child,
              )
            : null,
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 14)),
          ],
          const SizedBox(height: 24),
          ...actions.map((action) {
            return ListTile(
              leading: action.icon != null ? Icon(action.icon) : null,
              title: DefaultTextStyle(
                style: TextStyle(
                  color: action.isDestructive ? Colors.red : null,
                ),
                child: action.child,
              ),
              onTap: action.onPressed,
            );
          }),
        ],
      ),
    ),
  );
}

/// Action for adaptive action sheets
class AdaptiveActionSheetAction {
  final VoidCallback onPressed;
  final Widget child;
  final IconData? icon;
  final bool isDestructive;

  const AdaptiveActionSheetAction({
    required this.onPressed,
    required this.child,
    this.icon,
    this.isDestructive = false,
  });
}
