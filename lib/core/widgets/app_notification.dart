import 'dart:async';

import 'package:flutter/material.dart';

enum AppNotificationType { success, error, info }

abstract final class AppNotification {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    _dismissCurrent();

    final overlay = Overlay.of(context, rootOverlay: true);
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final style = _styleFor(type);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: topInset + 12,
        left: 16,
        right: 16,
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Semantics(
                liveRegion: true,
                label: message,
                child: Material(
                  color: style.backgroundColor,
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      children: [
                        Icon(style.icon, color: style.foregroundColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: style.foregroundColor,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Dismiss notification',
                          onPressed: _dismissCurrent,
                          color: style.foregroundColor,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, _dismissCurrent);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: AppNotificationType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: AppNotificationType.error);
  }

  static void _dismissCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static _NotificationStyle _styleFor(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.success => const _NotificationStyle(
          backgroundColor: Color(0xFF047857),
          foregroundColor: Colors.white,
          icon: Icons.check_circle_rounded,
        ),
      AppNotificationType.error => const _NotificationStyle(
          backgroundColor: Color(0xFFB91C1C),
          foregroundColor: Colors.white,
          icon: Icons.error_rounded,
        ),
      AppNotificationType.info => const _NotificationStyle(
          backgroundColor: Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
          icon: Icons.info_rounded,
        ),
    };
  }
}

class _NotificationStyle {
  const _NotificationStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
}
