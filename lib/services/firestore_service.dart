import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getNotesStream() {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return _db
        .collection('notes')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // UPDATED: Now accepts 'imageBase64' string instead of URL
  Future<void> addNote(String title, String content, int colorId, String imageBase64) {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _db.collection('notes').add({
      'title': title,
      'content': content,
      'color_id': colorId,
      'image_url': imageBase64, // Saving the huge text string here
      'timestamp': Timestamp.now(),
      'userId': user.uid,
    });
  }

  Future<void> updateNote(String noteId, String title, String content, int colorId, String imageBase64) {
    return _db.collection('notes').doc(noteId).update({
      'title': title,
      'content': content,
      'color_id': colorId,
      'image_url': imageBase64,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> deleteNote(String noteId) {
    return _db.collection('notes').doc(noteId).delete();
  }
}