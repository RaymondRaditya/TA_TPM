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
  // GlobalKey for Form to ensure state stability
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // FocusNodes for explicit focus management
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    // Manual focus request after first frame to ensure the field is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emailFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Pengecekan 2 Kali: 1) Cek Email di Controller, 2) Cek User di Database
  Future<void> _checkBiometrics() async {
    final identifier = _emailController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis email terlebih dahulu untuk cek biometrik')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Double check logic
    try {
      final user = await DatabaseHelper.instance.getUserByIdentifier(identifier);
      if (user != null && user[DatabaseHelper.columnBiometricRegistered] == 1) {
        setState(() {
          _showBiometricButton = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _showBiometricButton = false;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometrik tidak terdaftar untuk akun ini')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuthAction() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        final success = await _authService.login(email, password);
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (success) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email atau Password salah')),
          );
        }
      } else {
        final success = await _authService.register(email, password);
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (success) {
          setState(() {
            _isLoginMode = true;
            _passwordController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi Berhasil! Silakan Login.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi Gagal. Email mungkin sudah terdaftar.')),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Login' : 'Daftar Akun'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.checkroom, size: 80, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  const Text(
                    'T-Shirt Studio',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  
                  // FIELD EMAIL (Double Checked for Focus)
                  TextFormField(
                    key: const ValueKey('email_field_v2'),
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    enabled: true,
                    keyboardType: TextInputType.text, // Menggunakan text agar lebih kompatibel
                    decoration: const InputDecoration(
                      labelText: 'Email / Username',
                      hintText: 'Masukkan email Anda',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email tidak boleh kosong';
                      return null;
                    },
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // FIELD PASSWORD
                  TextFormField(
                    key: const ValueKey('password_field_v2'),
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: true,
                    enabled: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password Anda',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                      if (value.length < 6) return 'Password minimal 6 karakter';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else ...[
                    ElevatedButton(
                      onPressed: _handleAuthAction,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isLoginMode ? 'LOGIN' : 'DAFTAR SEKARANG'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                      child: Text(_isLoginMode 
                        ? 'Belum punya akun? Daftar di sini' 
                        : 'Sudah punya akun? Login di sini'),
                    ),
                    
                    if (_isLoginMode) ...[
                      const Divider(height: 32),
                      OutlinedButton.icon(
                        onPressed: _checkBiometrics,
                        icon: const Icon(Icons.search),
                        label: const Text('Cek Status Biometrik'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                    ],
                    
                    if (_showBiometricButton && _isLoginMode) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final success = await _authService.loginWithBiometrics(_emailController.text);
                          if (success && mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const MainScreen()),
                            );
                          }
                        },
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Login dengan Sidik Jari'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
