import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../models/class_entry.dart';
import '../../../services/supabase_service.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _lecturerCtrl = TextEditingController();

  int _selectedDay = 0;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String _selectedColor = '#4A90E2';
  bool _saving = false;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _colorOptions = [
    '#4A90E2',
    '#E24A4A',
    '#4AE27A',
    '#E2B54A',
    '#9B4AE2',
    '#4AE2D8',
    '#E2724A',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _roomCtrl.dispose();
    _lecturerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      final entry = ClassEntry(
        id: '',
        userId: userId,
        courseName: _nameCtrl.text.trim(),
        courseCode: _codeCtrl.text.trim(),
        room: _roomCtrl.text.trim(),
        dayOfWeek: _selectedDay,
        startTime: _startTime,
        endTime: _endTime,
        lecturer: _lecturerCtrl.text.trim().isEmpty
            ? null
            : _lecturerCtrl.text.trim(),
        colorHex: _selectedColor,
      );
      await context.read<ScheduleProvider>().addEntry(entry);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save class: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Class'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Course Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Course Code *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roomCtrl,
              decoration: const InputDecoration(labelText: 'Room *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lecturerCtrl,
              decoration:
                  const InputDecoration(labelText: 'Lecturer (optional)'),
            ),
            const SizedBox(height: 20),
            Text('Day', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(_days.length, (i) {
                return ChoiceChip(
                  label: Text(_days[i]),
                  selected: _selectedDay == i,
                  onSelected: (_) => setState(() => _selectedDay = i),
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text('Start: ${_startTime.format(context)}'),
                  onPressed: () => _pickTime(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text('End: ${_endTime.format(context)}'),
                  onPressed: () => _pickTime(isStart: false),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _colorOptions.map((hex) {
                final color = Color(
                    int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == hex
                          ? Border.all(
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                              width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
