import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/answer_option.dart';
import '../utils/platform_helper.dart';

class AnswerOptionWidget extends StatelessWidget {
  final AnswerOption option;
  final int index;
  final bool isSelected;
  final bool showResult;
  final VoidCallback? onTap;

  const AnswerOptionWidget({
    super.key,
    required this.option,
    required this.index,
    required this.isSelected,
    required this.showResult,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(97 + index); // a, b, c, d

    Color? backgroundColor;
    Color? borderColor;
    IconData? icon;

    if (showResult) {
      if (option.isCorrect) {
        backgroundColor = PlatformHelper.useIOSStyle
            ? CupertinoColors.systemGreen.withOpacity(0.1)
            : Colors.green.shade50;
        borderColor = PlatformHelper.useIOSStyle
            ? CupertinoColors.systemGreen
            : Colors.green;
        icon = PlatformHelper.useIOSStyle
            ? CupertinoIcons.check_mark_circled_solid
            : Icons.check_circle;
      } else if (isSelected) {
        backgroundColor = PlatformHelper.useIOSStyle
            ? CupertinoColors.systemRed.withOpacity(0.1)
            : Colors.red.shade50;
        borderColor = PlatformHelper.useIOSStyle
            ? CupertinoColors.systemRed
            : Colors.red;
        icon = PlatformHelper.useIOSStyle
            ? CupertinoIcons.xmark_circle_fill
            : Icons.cancel;
      }
    } else if (isSelected) {
      backgroundColor = PlatformHelper.useIOSStyle
          ? CupertinoColors.systemBlue.withOpacity(0.1)
          : Colors.blue.shade50;
      borderColor = PlatformHelper.useIOSStyle
          ? CupertinoColors.systemBlue
          : Colors.blue;
    }

    // iOS HIG recommends 44pt minimum tap target
    final minHeight = PlatformHelper.useIOSStyle ? 44.0 : 48.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GestureDetector(
        onTap: onTap != null
            ? () {
                // Provide haptic feedback on tap (iOS style)
                if (PlatformHelper.useIOSStyle) {
                  HapticFeedback.selectionClick();
                }
                onTap!();
              }
            : null,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                (PlatformHelper.useIOSStyle
                    ? CupertinoColors.systemBackground.resolveFrom(context)
                    : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  borderColor ??
                  (PlatformHelper.useIOSStyle
                      ? CupertinoColors.separator.resolveFrom(context)
                      : Colors.grey.shade300),
              width: borderColor != null ? 2 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      borderColor ??
                      (PlatformHelper.useIOSStyle
                          ? CupertinoColors.systemGrey
                          : Colors.grey.shade400),
                ),
                child: Center(
                  child: Text(
                    letter.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: (showResult && option.isCorrect)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: borderColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
