import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_helper.dart';

/// Platform-adaptive card that uses iOS-style container on iOS
/// and Material Card on other platforms
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(12);

    if (PlatformHelper.useIOSStyle) {
      // iOS-style card: subtle background with minimal border
      Widget cardContent = Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: defaultBorderRadius,
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
        child: child,
      );

      if (onTap != null) {
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: cardContent,
        );
      }

      return cardContent;
    }

    // Material card with elevation
    Widget cardContent = Card(
      margin: margin,
      color: color,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: defaultBorderRadius,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
