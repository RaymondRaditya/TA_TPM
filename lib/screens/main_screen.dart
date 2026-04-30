import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:tpm_ta/services/database_helper.dart';
import 'package:tpm_ta/services/auth_service.dart';
import 'package:tpm_ta/screens/store_locator_screen.dart';

import 'package:tpm_ta/screens/home_tab.dart';
import 'package:tpm_ta/screens/mini_game_screen.dart';
import 'package:tpm_ta/screens/checkout_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Define the content for each tab
  final List<Widget> _widgetOptions = <Widget>[
    // 1) Home Tab
    const HomeTab(),
    // 2) Stores Tab (Restored)
    const StoreLocatorScreen(),
    // 3) Minigame Tab
    const MiniGameScreen(),
    // 4) Checkout Tab
    const CheckoutScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('T-Shirt Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              setState(() => _selectedIndex = 3); // Switch to Checkout tab
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Stores'),
          BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: 'Minigame'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Checkout'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: const ProfileTab(),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final AuthService _authService = AuthService();

  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _username = 'Loading...';
  String _email = '';
  bool _isBiometricRegistered = false;
  bool _isDeviceSupported = false;
  int? _userId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkDeviceSupport();
  }

  Future<void> _checkDeviceSupport() async {
    final isSupported = await _authService.isBiometricsAvailable();
    if (mounted) {
      setState(() => _isDeviceSupported = isSupported);
    }
  }

  Future<void> _loadUserData() async {
    final sessionToken = await _secureStorage.read(key: 'session_token');
    if (sessionToken != null) {
      _userId = int.tryParse(sessionToken);
      if (_userId != null) {
        final user = await DatabaseHelper.instance.getUser(_userId!);
        if (user != null && mounted) {
          setState(() {
            _username = user[DatabaseHelper.columnUsername] ?? 'User';
            _email = user[DatabaseHelper.columnEmail] ?? '';
            _phoneController.text = user[DatabaseHelper.columnPhone] ?? '';
            _addressController.text = user[DatabaseHelper.columnAddress] ?? '';
            _isBiometricRegistered =
                user[DatabaseHelper.columnBiometricRegistered] == 1;
          });
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_userId == null) return;
    
    final updatedData = {
      DatabaseHelper.columnUserId: _userId,
      DatabaseHelper.columnPhone: _phoneController.text.trim(),
      DatabaseHelper.columnAddress: _addressController.text.trim(),
    };

    await DatabaseHelper.instance.updateUser(updatedData);
    setState(() => _isEditing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  Future<void> _registerBiometric() async {
    if (_userId == null) return;

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Scan your biometric to register it for this account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        await DatabaseHelper.instance.updateBiometricStatus(_userId!, true);
        setState(() => _isBiometricRegistered = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric registered successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://picsum.photos/200'),
          ),
          const SizedBox(height: 16),
          Text(
            _username,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            _email,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          TextField(
            controller: _phoneController,
            enabled: _isEditing,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _addressController,
            enabled: _isEditing,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Delivery Address',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            label: Text(_isEditing ? 'Save Profile' : 'Edit Profile'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          
          const SizedBox(height: 16),
          if (_isDeviceSupported)
            OutlinedButton.icon(
              onPressed: _isBiometricRegistered ? null : _registerBiometric,
              icon: Icon(
                _isBiometricRegistered ? Icons.check_circle : Icons.fingerprint,
              ),
              label: Text(
                _isBiometricRegistered ? 'Biometric Registered' : 'Register Biometric',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: _isBiometricRegistered ? Colors.grey : Colors.green,
              ),
            ),
        ],
      ),
    );
  }
}
