import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/study_rooms_provider.dart';
import '../../../models/study_room.dart';

class StudyRoomsScreen extends StatefulWidget {
  const StudyRoomsScreen({super.key});

  @override
  State<StudyRoomsScreen> createState() => _StudyRoomsScreenState();
}

class _StudyRoomsScreenState extends State<StudyRoomsScreen> {
  String? _filterBuilding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyRoomsProvider>().fetchRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Rooms')),
      body: Consumer<StudyRoomsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final buildings = provider.rooms
              .map((r) => r.building)
              .toSet()
              .toList()
            ..sort();
          final filtered = _filterBuilding == null
              ? provider.rooms
              : provider.rooms
                  .where((r) => r.building == _filterBuilding)
                  .toList();

          return Column(
            children: [
              if (buildings.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterBuilding == null,
                        onSelected: (_) =>
                            setState(() => _filterBuilding = null),
                      ),
                      const SizedBox(width: 8),
                      ...buildings.map((b) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(b),
                              selected: _filterBuilding == b,
                              onSelected: (_) =>
                                  setState(() => _filterBuilding = b),
                            ),
                          )),
                    ],
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No rooms available'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) =>
                            _RoomCard(room: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final StudyRoom room;

  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          child: Text(room.capacity.toString()),
        ),
        title: Text(room.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${room.building} · Floor ${room.floor}'),
            if (room.facilities.isNotEmpty)
              Wrap(
                spacing: 4,
                children: room.facilities
                    .map((f) => Chip(
                          label: Text(f,
                              style: const TextStyle(fontSize: 11)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            context.push('/campus/study-rooms/${room.id}', extra: room),
      ),
    );
  }
}
