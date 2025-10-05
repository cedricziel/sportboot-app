import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// Platform-adaptive loading indicator
/// Uses CupertinoActivityIndicator on iOS and CircularProgressIndicator on Android
/// Note: CupertinoActivityIndicator doesn't support determinate progress (value parameter)
class AdaptiveLoadingIndicator extends StatelessWidget {
  final double? value;
  final Color? color;

  const AdaptiveLoadingIndicator({super.key, this.value, this.color});

  @override
  Widget build(BuildContext context) {
    if (isCupertino(context)) {
      // CupertinoActivityIndicator is always indeterminate
      return CupertinoActivityIndicator(color: color);
    }

    return CircularProgressIndicator(value: value, color: color);
  }
}
