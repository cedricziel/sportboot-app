import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_helper.dart';

/// Platform-adaptive switch widget
class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.useIOSStyle) {
      // CupertinoSwitch doesn't have a simple way to set active color
      // The switch is already styled appropriately by default
      return CupertinoSwitch(value: value, onChanged: onChanged);
    }

    return Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: activeColor,
    );
  }
}

/// Platform-adaptive switch list tile
class AdaptiveSwitchListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AdaptiveSwitchListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.useIOSStyle) {
      return CupertinoListTile(
        title: title,
        subtitle: subtitle,
        trailing: CupertinoSwitch(value: value, onChanged: onChanged),
      );
    }

    return SwitchListTile(
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
    );
  }
}
