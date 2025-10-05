import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// Platform-adaptive list section that uses CupertinoListSection on iOS
/// and Column with material styling on other platforms
class AdaptiveListSection extends StatelessWidget {
  final Widget? header;
  final Widget? footer;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const AdaptiveListSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.margin,
  });

  /// Creates an inset-grouped section (iOS style with rounded corners and margins)
  const AdaptiveListSection.insetGrouped({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (isCupertino(context)) {
      return CupertinoListSection.insetGrouped(
        header: header,
        footer: footer,
        margin: margin,
        children: children,
      );
    }

    // Material version: simple column with optional header/footer
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: header!,
              ),
            ),
          ...children,
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                child: footer!,
              ),
            ),
        ],
      ),
    );
  }
}
