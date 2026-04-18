import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../config/theme.dart';
import '../../providers/lost_found_provider.dart';
import '../../services/accessibility_service.dart';
import '../../services/haptics_service.dart';

class CreateLostFoundScreen extends StatefulWidget {
  const CreateLostFoundScreen({super.key});

  @override
  State<CreateLostFoundScreen> createState() => _CreateLostFoundScreenState();
}

class _CreateLostFoundScreenState extends State<CreateLostFoundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  String _type = 'lost';
  String? _imagePath;
  bool _isSubmitting = false;

  // Speech-to-text
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _textBeforeListening = '';

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
      await context.read<LostFoundProvider>().addItem(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            type: _type,
            location: _locationController.text.trim(),
            contactInfo: _contactController.text.trim(),
            imagePath: _imagePath,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_type == 'lost'
                ? 'Lost item reported successfully!'
                : 'Found item reported successfully!'),
          ),
        );
        AccessibilityService.announce(
          context,
          _type == 'lost'
              ? 'Lost item reported successfully'
              : 'Found item reported successfully',
        );
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
    _locationController.dispose();
    _contactController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Item'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type selector
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: _type == 'lost',
                        label: 'Lost item',
                        child: InkWell(
                          onTap: () async {
                            setState(() => _type = 'lost');
                            await HapticsService.selection(context);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _type == 'lost'
                                  ? AppTheme.lost.withValues(alpha: 0.12)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: _type == 'lost'
                                  ? Border.all(color: AppTheme.lost)
                                  : Border.all(
                                      color: theme.colorScheme.outline),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search,
                                    size: 20,
                                    color: _type == 'lost'
                                        ? AppTheme.lost
                                        : theme.colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text('Lost Item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _type == 'lost'
                                          ? AppTheme.lost
                                          : theme.colorScheme.secondary,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: _type == 'found',
                        label: 'Found item',
                        child: InkWell(
                          onTap: () async {
                            setState(() => _type = 'found');
                            await HapticsService.selection(context);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _type == 'found'
                                  ? AppTheme.found.withValues(alpha: 0.12)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: _type == 'found'
                                  ? Border.all(color: AppTheme.found)
                                  : Border.all(
                                      color: theme.colorScheme.outline),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory,
                                    size: 20,
                                    color: _type == 'found'
                                        ? AppTheme.found
                                        : theme.colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text('Found Item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _type == 'found'
                                          ? AppTheme.found
                                          : theme.colorScheme.secondary,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g. Blue backpack, iPhone 15',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Item name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the item in detail',
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
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Where was it lost/found?',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Location is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Info',
                  hintText: 'Phone number or email',
                  prefixIcon: Icon(Icons.contact_phone_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Contact info is required'
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
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        await HapticsService.tap(context);
                        await _submit();
                      },
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
