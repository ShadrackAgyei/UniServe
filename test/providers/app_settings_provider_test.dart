import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniserve/providers/app_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults haptics to enabled', () async {
    SharedPreferences.setMockInitialValues({});

    final provider = AppSettingsProvider();
    await provider.initialize();

    expect(provider.hapticsEnabled, isTrue);
  });

  test('persists haptics toggle', () async {
    SharedPreferences.setMockInitialValues({});

    final provider = AppSettingsProvider();
    await provider.initialize();
    await provider.setHapticsEnabled(false);

    final reloaded = AppSettingsProvider();
    await reloaded.initialize();

    expect(reloaded.hapticsEnabled, isFalse);
  });
}
