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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    _checkBiometricStatusForIdentifier(); // Fire and forget the async check
  }

  Future<void> _checkBiometricStatusForIdentifier() async {
    final identifier = _emailController.text.trim();
    if (identifier.isEmpty) {
      if (_showBiometricButton) setState(() => _showBiometricButton = false);
      return;
    }

    final user = await DatabaseHelper.instance.getUserByIdentifier(identifier);
    final bool isEnabled =
        user != null && user[DatabaseHelper.columnBiometricRegistered] == 1;

    if (isEnabled != _showBiometricButton) {
      setState(() {
        _showBiometricButton = isEnabled;
      });
    }
  }

  Future<void> _handlePasswordAction() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    bool success = false;

    if (_isLoginMode) {
      success = await _authService.login(email, password);
      setState(() => _isLoading = false);
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
      }
    } else {
      success = await _authService.register(email, password);
      if (success) {
        setState(() {
          _isLoading = false;
          _isLoginMode = true; // Switch back to login view
          _passwordController.clear(); // Clear the password field for security
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login.'),
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration failed. Email might be in use.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);
    final success = await _authService.loginWithBiometrics(email);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication failed or was canceled.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
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
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _handlePasswordAction,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              _isLoginMode ? 'Login' : 'Register',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoginMode = !_isLoginMode;
                            });
                          },
                          child: Text(
                            _isLoginMode
                                ? "Don't have an account? Register"
                                : "Already have an account? Login",
                          ),
                        ),
                        if (_isLoginMode && _showBiometricButton) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _handleBiometricLogin,
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
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
