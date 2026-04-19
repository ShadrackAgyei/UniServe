import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/lost_found_provider.dart';
import '../../services/accessibility_service.dart';
import '../../services/haptics_service.dart';
import '../../widgets/app_bar_action_button.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  final _searchController = TextEditingController();

  Future<void> _deleteItem(LostFoundProvider provider, int id) async {
    final messenger = ScaffoldMessenger.of(context);
    final hapticsEnabled = context.read<AppSettingsProvider>().hapticsEnabled;
    final platform = Theme.of(context).platform;
    final view = View.of(context);
    final direction = Directionality.of(context);
    try {
      await provider.deleteItem(id);
      if (!mounted) return;
      await HapticsService.warningFor(
        enabled: hapticsEnabled,
        platform: platform,
      );
      AccessibilityService.announceFor(
        view: view,
        textDirection: direction,
        message: 'Item deleted',
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Item deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LostFoundProvider>().loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = context.select<AuthProvider, String?>(
      (auth) => auth.user?.id,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        actions: [
          AppBarActionButton(
            label: 'Add Item',
            icon: Icons.add,
            tooltip: 'Add item',
            onPressed: () async {
              final provider = context.read<LostFoundProvider>();
              await HapticsService.tap(context);
              if (!context.mounted) return;
              await context.push('/lost-found/create');
              provider.loadItems();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<LostFoundProvider>().setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                context.read<LostFoundProvider>().setSearchQuery(v);
              },
            ),
          ),
          Consumer<LostFoundProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: provider.filter == 'all',
                      onTap: () async {
                        await HapticsService.selection(context);
                        provider.setFilter('all');
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Lost',
                      selected: provider.filter == 'lost',
                      onTap: () async {
                        await HapticsService.selection(context);
                        provider.setFilter('lost');
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Found',
                      selected: provider.filter == 'found',
                      onTap: () async {
                        await HapticsService.selection(context);
                        provider.setFilter('found');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<LostFoundProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.secondary,
                      strokeWidth: 2,
                    ),
                  );
                }
                if (provider.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 80, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('No items found',
                            style: TextStyle(
                                fontSize: 18,
                                color: theme.colorScheme.secondary)),
                        const SizedBox(height: 8),
                        Text('Tap + to report a lost or found item',
                            style:
                                TextStyle(color: theme.colorScheme.secondary)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    final cs = Theme.of(context).colorScheme;
                    final item = provider.items[index];
                    final isLost = item.type == 'lost';
                    final isOwner =
                        item.userId != null && item.userId == currentUserId;
                    return Dismissible(
                      key: Key('lf_${item.id}'),
                      direction: isOwner
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      background: const SizedBox.shrink(),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.delete_outline, color: AppTheme.danger),
                      ),
                      onDismissed: (_) {
                        if (item.id != null) {
                          _deleteItem(provider, item.id!);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outline),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.imageUrl != null)
                              Image.network(
                                item.imageUrl!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 150,
                                  color: cs.surface,
                                  child: Icon(Icons.broken_image_outlined, size: 32, color: cs.secondary),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isLost
                                              ? AppTheme.lost.withValues(alpha: 0.12)
                                              : AppTheme.found.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isLost
                                                ? AppTheme.lost
                                                : AppTheme.found,
                                          ),
                                        ),
                                        child: Text(
                                          isLost ? 'LOST' : 'FOUND',
                                          style: TextStyle(
                                            color: isLost
                                                ? AppTheme.lost
                                                : AppTheme.found,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isOwner && item.id != null)
                                        IconButton(
                                          tooltip: 'Delete item',
                                          onPressed: () async {
                                            await _deleteItem(provider, item.id!);
                                          },
                                          icon: const Icon(Icons.delete_outline),
                                        ),
                                      if (isOwner && item.id != null)
                                        item.isResolved
                                            ? FilledButton.tonalIcon(
                                                onPressed: null,
                                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                                label: const Text('Resolved'),
                                                style: FilledButton.styleFrom(
                                                  disabledBackgroundColor:
                                                      AppTheme.resolved.withValues(alpha: 0.14),
                                                  disabledForegroundColor: AppTheme.resolved,
                                                  visualDensity: VisualDensity.compact,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                              )
                                            : TextButton.icon(
                                                onPressed: () async {
                                                  await provider.resolveItem(item.id!);
                                                  if (context.mounted) {
                                                    AccessibilityService.announce(context, 'Item marked resolved');
                                                    await HapticsService.confirm(context);
                                                  }
                                                },
                                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                                label: const Text('Mark Resolved'),
                                              ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(item.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(item.description,
                                      style: TextStyle(
                                          color: theme.colorScheme.secondary)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Reported by ${item.reporterName ?? 'Unknown'}',
                                    style: TextStyle(
                                      color: theme.colorScheme.secondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          size: 14,
                                          color: theme.colorScheme.secondary),
                                      const SizedBox(width: 4),
                                      Text(item.location,
                                          style: TextStyle(
                                              color:
                                                  theme.colorScheme.secondary,
                                              fontSize: 12)),
                                      const Spacer(),
                                      Text(
                                        DateFormat('MMM d, y')
                                            .format(item.createdAt),
                                        style: TextStyle(
                                            color: theme.colorScheme.secondary,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label filter',
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.transparent,
        selectedColor: const Color(0xFFB0311E),
        labelStyle: TextStyle(
          color: selected ? Colors.white : cs.secondary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        side: BorderSide(color: selected ? const Color(0xFFB0311E) : cs.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }
}
