import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_helper.dart';

/// Platform-adaptive list tile that uses CupertinoListTile on iOS
/// and Material ListTile on other platforms
class AdaptiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const AdaptiveListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.useIOSStyle) {
      return CupertinoListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing:
            trailing ??
            (onTap != null
                ? const Icon(CupertinoIcons.chevron_forward, size: 20)
                : null),
        onTap: onTap,
        padding: padding,
      );
    }

    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: padding,
    );
  }
}
