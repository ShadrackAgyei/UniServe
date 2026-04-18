import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../providers/issues_provider.dart';
import '../../services/accessibility_service.dart';
import '../../services/haptics_service.dart';

class CreateIssueScreen extends StatefulWidget {
  const CreateIssueScreen({super.key});

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'Broken Equipment';
  String? _imagePath;
  bool _isSubmitting = false;

  // Speech-to-text
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _textBeforeListening = '';

  final List<String> _categories = [
    'Broken Equipment',
    'Water Leak',
    'Electrical Issue',
    'Broken Lights',
    'Damaged Furniture',
    'Plumbing Issue',
    'Security Concern',
    'Cleaning Required',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    _textBeforeListening = _descriptionController.text;
    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        if (words.isEmpty) return;
        final appended = _textBeforeListening.isEmpty
            ? words
            : '$_textBeforeListening $words';
        setState(() {
          _descriptionController.text = appended;
          _descriptionController.selection = TextSelection.fromPosition(
            TextPosition(offset: appended.length),
          );
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 80);
    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  void _showImagePicker() {
    HapticsService.tap(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await context.read<IssuesProvider>().addIssue(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            imagePath: _imagePath,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported successfully!')),
        );
        AccessibilityService.announce(context, 'Issue reported successfully');
        await HapticsService.confirm(context);
        if (!mounted) return;
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPORT ISSUE',
            style: TextStyle(
                letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Brief description of the issue',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                dropdownColor: theme.colorScheme.surface,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue in detail',
                  prefixIcon: const Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                  suffixIcon: _speechAvailable
                      ? IconButton(
                          tooltip: _isListening
                              ? 'Stop recording'
                              : 'Dictate description',
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : null,
                          ),
                          onPressed: _toggleListening,
                        )
                      : null,
                ),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _showImagePicker,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_imagePath == null ? 'Add Photo' : 'Change Photo'),
              ),
              if (_imagePath != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.file(
                        File(_imagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          tooltip: 'Remove photo',
                          onPressed: () => setState(() => _imagePath = null),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.6),
                          ),
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ))
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
