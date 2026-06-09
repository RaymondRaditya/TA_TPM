import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tpm_ta/screens/login_screen.dart';
import 'package:tpm_ta/screens/main_screen.dart';
import 'package:tpm_ta/services/database_helper.dart';
import 'package:tpm_ta/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load environment variables
  await NotificationService().init(); // Initialize the notification service
  await DatabaseHelper.instance.init();
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: initialSessionToken != null
          ? const MainScreen()
          : const LoginScreen(),
    );
  }
}
