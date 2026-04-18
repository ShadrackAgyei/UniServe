import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_settings_provider.dart';
import '../../services/haptics_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            'FEEDBACK',
            style: TextStyle(
              fontSize: 10,
              color: cs.secondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<AppSettingsProvider>(
            builder: (context, settings, _) {
              return Semantics(
                label: 'Haptics',
                hint: 'Turn tactile feedback on or off for taps and confirmations',
                toggled: settings.hapticsEnabled,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outline),
                  ),
                  child: SwitchListTile(
                    value: settings.hapticsEnabled,
                    onChanged: (value) async {
                      await settings.setHapticsEnabled(value);
                      if (context.mounted && value) {
                        await HapticsService.selection(context);
                      }
                    },
                    title: const Text('Haptics'),
                    subtitle: const Text('Vibrate lightly for taps, selections, and important actions'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
