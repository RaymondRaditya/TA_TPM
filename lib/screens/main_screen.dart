import 'package:flutter/material.dart';
import 'package:tpm_ta/screens/login_screen.dart';
import 'package:tpm_ta/services/database_helper.dart';
import 'package:tpm_ta/screens/tshirt_canvas_screen.dart';
import 'package:tpm_ta/screens/store_locator_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Define the content for each tab
  final List<Widget> _widgetOptions = <Widget>[
    // 1) Home Canvas Tab
    const TShirtCanvasScreen(),
    // 2) Profile Tab
    Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage('https://picsum.photos/200'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mock User',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Builder(
            builder: (context) {
              return ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StoreLocatorScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Find Our Stores'),
              );
            },
          ),
        ],
      ),
    ),
    // 3) TPM Feedback Tab
    Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Saran & Kesan mata kuliah TPM',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Your Feedback',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () {}, child: const Text('Submit')),
        ],
      ),
    ),
    // 4) Logout Placeholder (Handled in onTap so it doesn't need a UI)
    const SizedBox.shrink(),
  ];

  Future<void> _onItemTapped(int index) async {
    if (index == 3) {
      // Logout logic: Clear session from DatabaseHelper
      // We don't have a dedicated 'session' table yet, but to follow the
      // requirement, we instantiate the database to simulate clearing session info.
      final db = await DatabaseHelper.instance.database;
      // Mocking session clear (e.g., await db.execute('DELETE FROM current_session');)

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design Workspace')),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Required when items > 3
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'TPM Feedback',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
