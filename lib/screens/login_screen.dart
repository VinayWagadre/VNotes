import 'package:firebase_auth/firebase_auth.dart'; // 1. Added Firebase import
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // We'll use this to toggle between Login and Register
  bool _isLogin = true;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // 2. Controllers are defined here, at the class level
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // 3. And disposed of here
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 4. This is the complete function to handle auth
  Future<void> _submitAuthForm() async {
    // Check if the form is valid
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get the values from the controllers
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Check if we are in Login or Register mode
      if (_isLogin) {
        // Login mode
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // Register mode
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      // AuthGate stream will handle navigation

    } on FirebaseAuthException catch (error) {
      // Handle errors
      String message = 'An error occurred. Please check your credentials.';
      if (error.message != null) {
        message = error.message!;
      }

      // Show a snackbar with the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email Text Field
              TextFormField(
                controller: _emailController, // Use the class controller
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Text Field
              TextFormField(
                controller: _passwordController, // Use the class controller
                obscureText: true, // Hides password
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Login/Register Button
              ElevatedButton(
                onPressed: _submitAuthForm, // 5. Call the submit function
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // Full width
                ),
                child: Text(_isLogin ? 'Login' : 'Register'),
              ),

              // Toggle Button
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin; // Flip between login and register
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Don\'t have an account? Register'
                      : 'Already have an account? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}