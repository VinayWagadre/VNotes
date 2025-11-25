import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  // Get instance of Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Get instance of Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // GET NOTES STREAM
  // This will be a stream of all notes for the logged-in user
  Stream<QuerySnapshot> getNotesStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Get all notes from the 'notes' collection
    // where the 'userId' field matches the logged-in user's ID
    // and order them by timestamp
    return _db
        .collection('notes')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ADD A NEW NOTE
  Future<void> addNote(String noteContent) {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Add a new document to the 'notes' collection
    return _db.collection('notes').add({
      'content': noteContent,
      'timestamp': Timestamp.now(),
      'userId': user.uid, // Store the user's ID
    });
  }

  Future<void> deleteNote(String noteId) {
    // Get the note document by its ID and delete it
    return _db.collection('notes').doc(noteId).delete();
  }

  Future<void> updateNote(String noteId, String newContent) {
    // Get the note document by its ID and update the 'content' field
    return _db.collection('notes').doc(noteId).update({
      'content': newContent,
      'timestamp': Timestamp.now(), // Update the timestamp as well
    });
  }

// We will add updateNote and deleteNote functions here later...
}