import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:vnotes/services/firestore_service.dart';
import 'package:vnotes/screens/note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search notes...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
            color: Colors.grey.shade700,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No notes yet',
                    style: TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first note',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final allNotes = snapshot.data!.docs;
          final filteredNotes = allNotes.where((note) {
            final data = note.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            final content = (data['content'] ?? '').toString().toLowerCase();
            return title.contains(_searchQuery) || content.contains(_searchQuery);
          }).toList();

          if (filteredNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No notes found',
                    style: TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return MasonryGridView.count(
            padding: const EdgeInsets.all(12),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              final data = note.data() as Map<String, dynamic>;
              final String title = data['title'] ?? '';
              final String content = data['content'] ?? '';
              final int colorIdx = data['color_id'] ?? 0;
              final String imageBase64 = data['image_url'] ?? '';
              final String noteId = note.id;

              return Dismissible(
                key: Key(noteId),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  _firestoreService.deleteNote(noteId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Note deleted'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {},
                      ),
                    ),
                  );
                },
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                ),
                child: _NoteCard(
                  noteId: noteId,
                  title: title,
                  content: content,
                  colorIdx: colorIdx,
                  imageBase64: imageBase64,
                  noteColors: noteColors,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoteEditorScreen(isNewNote: true)),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String noteId;
  final String title;
  final String content;
  final int colorIdx;
  final String imageBase64;
  final List<Color> noteColors;

  const _NoteCard({
    required this.noteId,
    required this.title,
    required this.content,
    required this.colorIdx,
    required this.imageBase64,
    required this.noteColors,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageBase64.isNotEmpty;
    final bool hasTitle = title.isNotEmpty;
    final bool hasContent = content.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(
              noteId: noteId,
              title: title,
              content: content,
              colorId: colorIdx,
              imageUrl: imageBase64,
              isNewNote: false,
            ),
          ),
        );
      },
      child: Hero(
        tag: 'note_$noteId',
        child: Card(
          color: noteColors.length > colorIdx ? noteColors[colorIdx] : Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image section - only show if image exists
                if (hasImage)
                  Image.memory(
                    base64Decode(imageBase64),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),

                // Text content
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      if (hasTitle)
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),

                      if (hasTitle && hasContent)
                        const SizedBox(height: 8),

                      // Content
                      if (hasContent)
                        Text(
                          content,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),

                      // Show placeholder if completely empty
                      if (!hasTitle && !hasContent && !hasImage)
                        Text(
                          'Empty note',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}