import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vnotes/screens/login_screen.dart'; // We will create this
import 'package:vnotes/main.dart';
import 'package:vnotes/screens/notes_screen.dart';// We need to import your home page

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Listen to the authentication state
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. User is not logged in
          if (!snapshot.hasData) {
            return const LoginScreen(); // We'll build this next
          }

          // 2. User is logged in
          // You can replace this with your actual app's home screen
          return const NotesScreen();
        },
      ),
    );
  }
}