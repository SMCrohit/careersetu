import 'package:flutter/material.dart';

class CustomToast {
  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, Colors.green.shade600, Icons.check_circle);
  }

  static void showError(BuildContext context, String message) {
    _showToast(context, message, Colors.red.shade600, Icons.error);
  }

  static void _showToast(BuildContext context, String message, Color color, IconData icon) {
    final overlay = ScaffoldMessenger.of(context);
    overlay.hideCurrentSnackBar();
    overlay.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
