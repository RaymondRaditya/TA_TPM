import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tpm_ta/services/database_helper.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<bool> register(String email, String password) async {
    try {
      final hashedPassword = _hashPassword(password);
      await DatabaseHelper.instance.insertUser({
        DatabaseHelper.columnUsername:
            email, // Fallback for existing username references
        DatabaseHelper.columnEmail: email,
        DatabaseHelper.columnPasswordHash: hashedPassword,
      });
      return true;
    } catch (e) {
      return false; // Return false if user registration fails (e.g., UNIQUE constraint failed)
    }
  }

  Future<bool> login(String email, String password) async {
    final user = await DatabaseHelper.instance.getUserByEmail(email);
    if (user != null) {
      final storedHash = user[DatabaseHelper.columnPasswordHash] as String?;
      if (storedHash == _hashPassword(password)) {
        await _secureStorage.write(
          key: 'session_token',
          value: user[DatabaseHelper.columnUserId].toString(),
        );
        return true;
      }
    }
    return false;
  }

  /// Checks for biometric availability and attempts to authenticate the user.
  /// Returns [true] if authentication is successful, [false] otherwise.
  Future<bool> authenticateWithBiometrics() async {
    try {
      // Check if the device has biometric hardware and is supported
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        // Device doesn't support biometrics or it isn't set up
        return false;
      }

      // Prompt the user for biometric authentication
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Login to access your T-Shirt account',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      // Handle specific platform exceptions (e.g., user canceled, not enrolled)
      print(
        'PlatformException during biometric authentication: ${e.code} - ${e.message}',
      );
      return false;
    }
  }
}
