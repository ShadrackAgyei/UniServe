import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../models/class_entry.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday - 1; // 0=Mon
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: today.clamp(0, 6),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().fetchEntries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _days.map((d) => Tab(text: d)).toList(),
          isScrollable: false,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/campus/schedule/add'),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: List.generate(
              7,
              (day) => _DayView(day: day, provider: provider),
            ),
          );
        },
      ),
    );
  }
}

class _DayView extends StatelessWidget {
  final int day;
  final ScheduleProvider provider;

  const _DayView({required this.day, required this.provider});

  @override
  Widget build(BuildContext context) {
    final entries = provider.entriesForDay(day);
    if (entries.isEmpty) {
      return const Center(
        child: Text('No classes', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (context, i) => _ClassCard(entry: entries[i]),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassEntry entry;

  const _ClassCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(entry.colorHex);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.courseName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(entry.courseCode,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 4),
                      Text(
                          '${entry.startTime.format(context)} – ${entry.endTime.format(context)}'),
                      const SizedBox(width: 12),
                      const Icon(Icons.room, size: 14),
                      const SizedBox(width: 4),
                      Text(entry.room),
                    ]),
                    if (entry.lecturer != null)
                      Text(entry.lecturer!,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove class?'),
        content: Text('Remove ${entry.courseName} from your schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await context.read<ScheduleProvider>().deleteEntry(entry.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not remove class: $e')),
          );
        }
      }
    }
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
