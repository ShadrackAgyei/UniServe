import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityService {
  const AccessibilityService._();

  static void announce(BuildContext context, String message) {
    announceFor(
      view: View.of(context),
      textDirection: Directionality.of(context),
      message: message,
    );
  }

  static void announceFor({
    required FlutterView view,
    required TextDirection textDirection,
    required String message,
  }) {
    SemanticsService.sendAnnouncement(view, message, textDirection);
  }
}
