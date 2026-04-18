import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings_provider.dart';

class HapticsService {
  const HapticsService._();

  static Future<void> selection(BuildContext context) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> tap(BuildContext context) async {
    if (!_isEnabled(context)) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> confirm(BuildContext context) async {
    await confirmFor(
      enabled: _isEnabled(context),
      platform: Theme.of(context).platform,
    );
  }

  static Future<void> confirmFor({
    required bool enabled,
    required TargetPlatform platform,
  }) async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
    if (platform == TargetPlatform.android) {
      await HapticFeedback.vibrate();
    }
  }

  static Future<void> warning(BuildContext context) async {
    await warningFor(
      enabled: _isEnabled(context),
      platform: Theme.of(context).platform,
    );
  }

  static Future<void> warningFor({
    required bool enabled,
    required TargetPlatform platform,
  }) async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
    if (platform == TargetPlatform.android) {
      await HapticFeedback.vibrate();
    }
  }

  static bool _isEnabled(BuildContext context) {
    return context.read<AppSettingsProvider>().hapticsEnabled;
  }
}
