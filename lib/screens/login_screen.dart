import 'package:flutter/material.dart';
import 'package:tpm_ta/services/auth_service.dart';
import 'package:tpm_ta/services/database_helper.dart';
import 'package:tpm_ta/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Trigger biometric authentication via local_auth
    final success = await _authService.authenticateUser();

    if (success) {
      // Check if user exists in the local database
      var user = await DatabaseHelper.instance.getUserByUsername(username);

      // If not, insert a default user session to tie their future designs to
      if (user == null) {
        await DatabaseHelper.instance.insertUser({
          DatabaseHelper.columnUsername: username,
          DatabaseHelper.columnIsBiometricEnabled:
              1, // Track that they use biometrics
        });
      }

      // Navigate to Main Screen upon success
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed or was canceled.'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.checkroom, size: 80, color: Colors.black87),
              const SizedBox(height: 24),
              const Text(
                'T-Shirt Studio',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _handleLogin,
                      icon: const Icon(Icons.fingerprint, size: 32),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Login with Biometrics',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
