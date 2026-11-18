import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FeedbackUtils {
  static void tap() => HapticFeedback.lightImpact();

  static void success() => HapticFeedback.mediumImpact();

  static void snack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        duration: const Duration(seconds: 2),
      ));
  }

  static Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
