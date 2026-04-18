import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/emergency_contacts_data.dart';
import '../../config/theme.dart';
import '../../models/emergency_contact.dart';
import '../../services/accessibility_service.dart';
import '../../services/haptics_service.dart';
import '../../services/supabase_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      _contacts = await SupabaseService.getEmergencyContacts();
    } catch (_) {
      _contacts = campusEmergencyContacts;
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'security':
        return Icons.shield_outlined;
      case 'medical':
        return Icons.local_hospital_outlined;
      case 'fire':
        return Icons.local_fire_department_outlined;
      case 'maintenance':
        return Icons.build_outlined;
      case 'admin':
        return Icons.people_outlined;
      case 'it':
        return Icons.computer_outlined;
      case 'counseling':
        return Icons.psychology_outlined;
      case 'emergency':
        return Icons.emergency_outlined;
      default:
        return Icons.phone_outlined;
    }
  }

  bool _isEmergency(String iconName) =>
      iconName == 'emergency' || iconName == 'fire' || iconName == 'medical' || iconName == 'security';

  Future<void> _makeCall(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      if (!context.mounted) return;
      await HapticsService.warning(context);
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call')),
        );
        AccessibilityService.announce(context, 'Could not make phone call');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: cs.secondary,
                strokeWidth: 2,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isEmergency(contact.icon)
                              ? AppTheme.danger.withValues(alpha: 0.12)
                              : cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isEmergency(contact.icon)
                                ? AppTheme.danger.withValues(alpha: 0.3)
                                : cs.outline,
                          ),
                        ),
                        child: Icon(
                          _getIcon(contact.icon),
                          color: _isEmergency(contact.icon) ? AppTheme.danger : cs.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.name,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface)),
                            Text(contact.department,
                                style: TextStyle(fontSize: 12, color: cs.secondary)),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Call ${contact.name}',
                        child: IconButton(
                          onPressed: () => _makeCall(context, contact.phone),
                          icon: const Icon(Icons.phone_outlined),
                          color: cs.onSurface,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            side: BorderSide(color: cs.outline),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
