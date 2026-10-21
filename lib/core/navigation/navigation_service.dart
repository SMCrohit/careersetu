import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
  static bool _isRedirecting = false;

  static void handleSessionExpired() {
    if (_isRedirecting) return;
    _isRedirecting = true;
    Future.delayed(const Duration(seconds: 4), () => _isRedirecting = false);

    messengerKey.currentState?.hideCurrentSnackBar();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: Colors.amberAccent, size: 26),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Session expired. Please log in again to continue.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );

    // Reset navigation stack directly to login screen
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
