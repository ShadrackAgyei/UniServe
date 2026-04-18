import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/accessibility_service.dart';
import '../../services/haptics_service.dart';
import '../../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _departmentController;
  late TextEditingController _programController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _departmentController = TextEditingController(text: user?.department ?? '');
    _programController = TextEditingController(text: user?.program ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _programController.dispose();
    super.dispose();
  }

  ImageProvider? _profileImage(AuthProvider auth) {
    final localPath = auth.localProfilePhoto;
    if (localPath != null && File(localPath).existsSync()) {
      return FileImage(File(localPath));
    }
    final url = auth.user?.profilePhotoUrl;
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }
    return null;
  }

  Future<void> _pickProfilePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 512, imageQuality: 80);
    if (image == null) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final localFile = File('${appDir.path}/profile_photo_$userId.jpg');
    await File(image.path).copy(localFile.path);
    authProvider.setLocalProfilePhoto(localFile.path);
    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Photo saved!')),
    );
    AccessibilityService.announce(context, 'Profile photo saved');
    await HapticsService.tap(context);

    try {
      await SupabaseService.uploadProfilePhoto(localFile);
      await authProvider.refreshProfile();
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await auth.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      department: _departmentController.text.trim(),
      program: _programController.text.trim(),
    );
    if (mounted) setState(() => _isEditing = false);
    messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
    if (mounted) {
      AccessibilityService.announce(context, 'Profile updated');
      await HapticsService.confirm(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE', style: TextStyle(letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await HapticsService.tap(context);
              if (context.mounted) context.push('/settings');
            },
          ),
          if (!_isEditing)
            IconButton(
              tooltip: 'Edit profile',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return Center(child: Text('Not logged in', style: TextStyle(color: cs.secondary)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Center(
                  child: Semantics(
                    button: true,
                    label: 'Profile photo',
                    hint: 'Double tap to change profile photo',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await HapticsService.tap(context);
                          if (context.mounted) {
                            await _pickProfilePhoto();
                          }
                        },
                        customBorder: const CircleBorder(),
                        child: Stack(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: cs.outline, width: 1),
                              ),
                              child: (() {
                                final profileImg = _profileImage(auth);
                                return CircleAvatar(
                                  radius: 43,
                                  backgroundColor: cs.surface,
                                  backgroundImage: profileImg,
                                  child: profileImg == null
                                      ? Text(
                                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w200,
                                            color: cs.onSurface,
                                          ),
                                        )
                                      : null,
                                );
                              })(),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: ExcludeSemantics(
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: cs.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: cs.outline),
                                  ),
                                  child: Icon(Icons.camera_alt_outlined, size: 14, color: cs.secondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_isEditing) ...[
                  Center(
                    child: Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: cs.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      user.studentId,
                      style: TextStyle(fontSize: 13, color: cs.secondary, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _InfoTile(icon: Icons.email_outlined, label: 'EMAIL', value: user.email),
                  _InfoTile(icon: Icons.phone_outlined, label: 'PHONE', value: user.phone ?? '—'),
                  _InfoTile(icon: Icons.business_outlined, label: 'DEPARTMENT', value: user.department ?? '—'),
                  _InfoTile(icon: Icons.school_outlined, label: 'PROGRAM', value: user.program ?? '—'),
                  const SizedBox(height: 32),
                  _SectionLabel(label: 'APPEARANCE'),
                  const SizedBox(height: 12),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outline),
                        ),
                        child: Row(
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                themeProvider.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                                size: 18,
                                color: cs.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              themeProvider.isDark ? 'Dark' : 'Light',
                              style: TextStyle(fontSize: 14, color: cs.onSurface),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: cs.outline),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ThemeToggleButton(
                                    label: 'Light theme',
                                    icon: Icons.light_mode_outlined,
                                    isSelected: !themeProvider.isDark,
                                    activeBg: cs.onSurface,
                                    activeColor: cs.onPrimary,
                                    inactiveColor: cs.secondary,
                                    onTap: themeProvider.isDark
                                        ? () async {
                                            await HapticsService.selection(context);
                                            await themeProvider.toggleTheme();
                                            if (!context.mounted) return;
                                            AccessibilityService.announce(context, 'Light theme enabled');
                                            await HapticsService.confirm(context);
                                          }
                                        : null,
                                  ),
                                  _ThemeToggleButton(
                                    label: 'Dark theme',
                                    icon: Icons.dark_mode_outlined,
                                    isSelected: themeProvider.isDark,
                                    activeBg: cs.onSurface,
                                    activeColor: cs.onPrimary,
                                    inactiveColor: cs.secondary,
                                    onTap: !themeProvider.isDark
                                        ? () async {
                                            await HapticsService.selection(context);
                                            await themeProvider.toggleTheme();
                                            if (!context.mounted) return;
                                            AccessibilityService.announce(context, 'Dark theme enabled');
                                            await HapticsService.confirm(context);
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _SectionLabel(label: 'ACCOUNT'),
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    label: 'Logout',
                    hint: 'Sign out of your account',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final auth = context.read<AuthProvider>();
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text('Are you sure you want to log out?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Logout', style: TextStyle(color: AppTheme.danger)),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true || !context.mounted) return;
                          await HapticsService.warning(context);
                          await auth.logout();
                          if (!context.mounted) return;
                          AccessibilityService.announce(context, 'Logged out');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              ExcludeSemantics(
                                child: Icon(Icons.logout, size: 18, color: AppTheme.danger),
                              ),
                              const SizedBox(width: 12),
                              Text('Logout', style: TextStyle(color: AppTheme.danger, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Edit form
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'EDIT PROFILE'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _departmentController,
                    decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _programController,
                    decoration: const InputDecoration(labelText: 'Program', prefixIcon: Icon(Icons.school_outlined)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isEditing = false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _saveProfile,
                          child: auth.isLoading
                              ? SizedBox(height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10, color: cs.secondary, letterSpacing: 1, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: Theme.of(context).colorScheme.secondary,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final Color activeBg;
  final Color activeColor;
  final Color inactiveColor;

  const _ThemeOption({
    required this.icon,
    required this.isSelected,
    required this.activeBg,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 16, color: isSelected ? activeColor : inactiveColor),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeBg;
  final Color activeColor;
  final Color inactiveColor;
  final Future<void> Function()? onTap;

  const _ThemeToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeBg,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: _ThemeOption(
            icon: icon,
            isSelected: isSelected,
            activeBg: activeBg,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          ),
        ),
      ),
    );
  }
}
