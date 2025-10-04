import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/platform_helper.dart';

/// Platform-adaptive loading indicator
class AdaptiveLoadingIndicator extends StatelessWidget {
  final double? radius;
  final Color? color;

  const AdaptiveLoadingIndicator({super.key, this.radius, this.color});

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.useIOSStyle) {
      return CupertinoActivityIndicator(radius: radius ?? 10.0, color: color);
    }

    return CircularProgressIndicator(color: color);
  }
}

/// Shows a platform-adaptive loading dialog
void showAdaptiveLoadingDialog(BuildContext context) {
  if (PlatformHelper.useIOSStyle) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CupertinoPopupSurface(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CupertinoActivityIndicator(radius: 14),
          ),
        ),
      ),
    );
  } else {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
