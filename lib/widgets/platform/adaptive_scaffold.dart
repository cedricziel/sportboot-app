import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_helper.dart';

/// Platform-adaptive scaffold that uses CupertinoPageScaffold on iOS
/// and Material Scaffold on other platforms
class AdaptiveScaffold extends StatelessWidget {
  final Widget? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;

  const AdaptiveScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.leading,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.useIOSStyle) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor ?? CupertinoColors.systemBackground,
        navigationBar: title != null
            ? CupertinoNavigationBar(
                middle: title,
                trailing: actions != null && actions!.isNotEmpty
                    ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                    : null,
                leading: leading,
              )
            : null,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: title != null
          ? AppBar(
              title: title,
              actions: actions,
              leading: leading,
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            )
          : null,
      body: body,
    );
  }
}
