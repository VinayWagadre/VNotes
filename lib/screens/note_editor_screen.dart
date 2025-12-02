import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vnotes/services/firestore_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final String noteId;
  final String title;
  final String content;
  final int colorId;
  final String imageUrl;
  final bool isNewNote;

  const NoteEditorScreen({
    super.key,
    this.noteId = '',
    this.title = '',
    this.content = '',
    this.colorId = 0,
    this.imageUrl = '',
    this.isNewNote = true,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late int _selectedColor;

  File? _selectedImageFile;
  String _currentImageBase64 = '';
  bool _isSaving = false;

  final List<Color> noteColors = [
    Colors.white,
    Colors.red.shade100,
    Colors.orange.shade100,
    Colors.yellow.shade100,
    Colors.green.shade100,
    Colors.blue.shade100,
    Colors.purple.shade100,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content);
    _selectedColor = widget.colorId;
    _currentImageBase64 = widget.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 10,
    );

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final String base64String = base64Encode(bytes);

      setState(() {
        _selectedImageFile = File(image.path);
        _currentImageBase64 = base64String;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _currentImageBase64 = '';
    });
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty && _currentImageBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot save an empty note'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isNewNote) {
        await _firestoreService.addNote(title, content, _selectedColor, _currentImageBase64);
      } else {
        await _firestoreService.updateNote(
            widget.noteId, title, content, _selectedColor, _currentImageBase64);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: noteColors[_selectedColor],
      appBar: AppBar(
        backgroundColor: noteColors[_selectedColor],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Image attachment button
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Colors.black87),
            onPressed: _pickImage,
            tooltip: 'Add image',
          ),

          // Color palette button
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: Colors.black87),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose color',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(
                          noteColors.length,
                              (index) => GestureDetector(
                            onTap: () {
                              setState(() => _selectedColor = index);
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: noteColors[index],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: _selectedColor == index
                                  ? const Icon(Icons.check, color: Colors.black87)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
            tooltip: 'Change color',
          ),

          // Save button
          IconButton(
            icon: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
            )
                : const Icon(Icons.check_rounded, color: Colors.black87),
            onPressed: _isSaving ? null : _saveNote,
            tooltip: 'Save',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with remove button
            if (_selectedImageFile != null || _currentImageBase64.isNotEmpty)
              Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: DecorationImage(
                        image: _selectedImageFile != null
                            ? FileImage(_selectedImageFile!)
                            : MemoryImage(base64Decode(_currentImageBase64)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: _removeImage,
                        tooltip: 'Remove image',
                      ),
                    ),
                  ),
                ],
              ),

            // Title field
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),

            // Content field
            TextField(
              controller: _contentController,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Start typing...',
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              minLines: 10,
            ),
          ],
        ),
      ),
    );
  }
}