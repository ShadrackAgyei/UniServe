import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/events_provider.dart';
import '../../../models/campus_event.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String? _filterCategory;

  static const _categories = ['Academic', 'Sports', 'Social', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Events')),
      body: Consumer<EventsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final filtered = _filterCategory == null
              ? provider.events
              : provider.events
                  .where((e) => e.category == _filterCategory)
                  .toList();
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterCategory == null,
                      onSelected: (_) =>
                          setState(() => _filterCategory = null),
                    ),
                    const SizedBox(width: 8),
                    ..._categories.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(c),
                            selected: _filterCategory == c,
                            onSelected: (_) =>
                                setState(() => _filterCategory = c),
                          ),
                        )),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No events found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) =>
                            _EventCard(event: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CampusEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(event.eventDate);
    final timeStr = event.startTime.format(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push('/campus/events/${event.id}', extra: event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM')
                          .format(event.eventDate)
                          .toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      event.eventDate.day.toString(),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('$dateStr · $timeStr',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(event.location,
                        style: Theme.of(context).textTheme.bodySmall),
                    Chip(
                      label: Text(event.category,
                          style: const TextStyle(fontSize: 10)),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
