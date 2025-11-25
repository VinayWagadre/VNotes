import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vnotes/services/firestore_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Dialog for ADDING a note
  void _showAddNoteDialog() {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Note'),
          content: TextField(
            controller: noteController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Your note...'),
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String noteContent = noteController.text.trim();
                if (noteContent.isNotEmpty) {
                  _firestoreService.addNote(noteContent);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- THIS IS THE NEW METHOD FOR UPDATING ---
  void _showUpdateNoteDialog(String noteId, String oldContent) {
    // Pre-fill the controller with the old content
    final TextEditingController noteController =
    TextEditingController(text: oldContent);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Note'),
          content: TextField(
            controller: noteController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Your note...'),
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Get the updated text
                final String updatedContent = noteController.text.trim();

                // Only update if not empty
                if (updatedContent.isNotEmpty) {
                  // Use your service to update the note
                  _firestoreService.updateNote(noteId, updatedContent);
                }

                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
  // --- END OF NEW METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VNotes'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notes yet. Add one!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final notes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final data = note.data() as Map<String, dynamic>;
              final String content = data['content'] ?? 'No content';
              final String noteId = note.id;

              return Dismissible(
                key: Key(noteId),
                onDismissed: (direction) {
                  _firestoreService.deleteNote(noteId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note deleted')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(content),
                    // --- THIS IS THE NEW OnTap PROPERTY ---
                    onTap: () {
                      _showUpdateNoteDialog(noteId, content);
                    },
                    // --- END OF NEW PROPERTY ---
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}