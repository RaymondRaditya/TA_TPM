import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tpm_ta/screens/login_screen.dart';
import 'package:tpm_ta/screens/main_screen.dart';
import 'package:tpm_ta/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init(); // Initialize the notification service
  const secureStorage = FlutterSecureStorage();
  final sessionToken = await secureStorage.read(key: 'session_token');

  runApp(MyApp(initialSessionToken: sessionToken));
}

class MyApp extends StatelessWidget {
  final String? initialSessionToken;

  const MyApp({super.key, this.initialSessionToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T-Shirt Studio',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: initialSessionToken != null
          ? const MainScreen()
          : const LoginScreen(),
    );
  }
}
