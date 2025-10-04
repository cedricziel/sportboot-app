import 'package:flutter/material.dart';
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
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
        icon = Icons.check_circle;
      } else if (isSelected) {
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red;
        icon = Icons.cancel;
      }
    } else if (isSelected) {
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue;
    }

    // iOS HIG recommends 44pt minimum tap target
    final minHeight = PlatformHelper.useIOSStyle ? 44.0 : 48.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: onTap != null
            ? () {
                // Provide haptic feedback on tap (iOS style)
                if (PlatformHelper.useIOSStyle) {
                  HapticFeedback.selectionClick();
                }
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor ?? Colors.grey.shade300,
              width: borderColor != null ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor ?? Colors.grey.shade400,
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
