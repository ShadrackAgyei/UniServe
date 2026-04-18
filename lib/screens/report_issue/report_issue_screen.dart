import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/campus_issue.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issues_provider.dart';
import '../../services/accessibility_service.dart';
import '../../services/haptics_service.dart';
import '../../widgets/app_bar_action_button.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  Future<void> _deleteIssue(IssuesProvider provider, int id) async {
    final messenger = ScaffoldMessenger.of(context);
    final hapticsEnabled = context.read<AppSettingsProvider>().hapticsEnabled;
    final platform = Theme.of(context).platform;
    final view = View.of(context);
    final direction = Directionality.of(context);
    try {
      await provider.deleteIssue(id);
      if (!mounted) return;
      await HapticsService.warningFor(
        enabled: hapticsEnabled,
        platform: platform,
      );
      AccessibilityService.announceFor(
        view: view,
        textDirection: direction,
        message: 'Issue deleted',
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Issue deleted')),
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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IssuesProvider>().loadIssues();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':      return AppTheme.lost;
      case 'In Progress':  return AppTheme.resolved;
      case 'Resolved':     return AppTheme.found;
      default:             return const Color(0xFF666666);
    }
  }

  void _markAsFixed(IssuesProvider provider, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Fixed'),
        content: const Text('Has this issue been resolved?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.updateStatus(id, 'Resolved');
              if (!context.mounted) return;
              AccessibilityService.announce(context, 'Issue marked as fixed');
              await HapticsService.confirm(context);
            },
            child: const Text('Yes, it\'s fixed'),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(
    CampusIssue issue,
    IssuesProvider provider, {
    required String? currentUserId,
    bool showFixButton = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(issue.status);
    final isOwner = issue.userId != null && issue.userId == currentUserId;
    return Dismissible(
      key: Key('issue_${issue.id}'),
      direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: AppTheme.danger),
      ),
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
        if (issue.id != null) {
          _deleteIssue(provider, issue.id!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(issue.title,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: cs.onSurface)),
                ),
                if (isOwner && issue.id != null)
                  IconButton(
                    tooltip: 'Delete issue',
                    onPressed: () async {
                      await _deleteIssue(provider, issue.id!);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    issue.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(issue.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.secondary, fontSize: 13)),
            const SizedBox(height: 10),
            Text(
              'Reported by ${issue.reporterName ?? 'Unknown'}',
              style: TextStyle(
                color: cs.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(issue.category,
                    style: TextStyle(color: cs.secondary, fontSize: 11, letterSpacing: 0.5)),
                const Spacer(),
                Text(
                  DateFormat('MMM d, y').format(issue.createdAt),
                  style: TextStyle(color: cs.secondary, fontSize: 11),
                ),
              ],
            ),
            if (showFixButton &&
                isOwner &&
                issue.status != 'Resolved' &&
                issue.id != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _markAsFixed(provider, issue.id!),
                  child: const Text('Mark as Fixed'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveList(IssuesProvider provider, String? currentUserId) {
    final cs = Theme.of(context).colorScheme;
    final active = provider.activeIssues;
    if (active.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: cs.outline),
            const SizedBox(height: 16),
            Text('No active issues',
                style: TextStyle(fontSize: 18, color: cs.secondary)),
            const SizedBox(height: 8),
            Text('Tap + to report a new issue',
                style: TextStyle(color: cs.secondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: active.length,
      itemBuilder: (context, index) =>
          _buildIssueCard(active[index], provider, currentUserId: currentUserId),
    );
  }

  Widget _buildHistoryList(IssuesProvider provider, String? currentUserId) {
    final cs = Theme.of(context).colorScheme;
    final resolved = provider.resolvedIssues;
    if (resolved.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: cs.outline),
            const SizedBox(height: 16),
            Text('No resolved issues yet',
                style: TextStyle(fontSize: 18, color: cs.secondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: resolved.length,
      itemBuilder: (context, index) =>
          _buildIssueCard(
            resolved[index],
            provider,
            currentUserId: currentUserId,
            showFixButton: false,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentUserId = context.select<AuthProvider, String?>(
      (auth) => auth.user?.id,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('ISSUES', style: TextStyle(letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.w500)),
        actions: [
          AppBarActionButton(
            label: 'Report',
            icon: Icons.add,
            tooltip: 'Report issue',
            onPressed: () async {
              final provider = context.read<IssuesProvider>();
              await HapticsService.tap(context);
              if (!context.mounted) return;
              await context.push('/report-issues/create');
              provider.loadIssues();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SegmentedControl(
              options: const ['Active', 'History'],
              selected: _tabController.index,
              onTap: (i) async {
                await HapticsService.selection(context);
                _tabController.animateTo(i);
              },
            ),
          ),
        ),
      ),
      body: Consumer<IssuesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.secondary),
              ),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildActiveList(provider, currentUserId),
              _buildHistoryList(provider, currentUserId),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onTap;

  const _SegmentedControl({
    required this.options,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: Semantics(
              button: true,
              selected: isSelected,
              label: options[i],
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? cs.onSurface : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      options[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? cs.onPrimary : cs.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
