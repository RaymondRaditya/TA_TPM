import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  bool _looksLikeEmail(String value) {
    return value.contains('@');
  }

  Future<bool> register(String email, String password) async {
    try {
      final normalizedEmail = email.trim();
      if (!_looksLikeEmail(normalizedEmail)) {
        return false;
      }
      final hashedPassword = _hashPassword(password);
      await DatabaseHelper.instance.insertUser({
        DatabaseHelper.columnUsername: normalizedEmail,
        DatabaseHelper.columnEmail: normalizedEmail,
        DatabaseHelper.columnPasswordHash: hashedPassword,
      });
      return true;
    } catch (e) {
      return false; // Return false if user registration fails (e.g., UNIQUE constraint failed)
    }
  }

  Future<bool> login(String email, String password) async {
    final user = await DatabaseHelper.instance.getUserByIdentifier(
      email.trim(),
    );
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

  /// Authenticates via biometrics and establishes a secure session for the linked user
  Future<bool> loginWithBiometrics(String email) async {
    final success = await _promptBiometrics('Login to your T-Shirt account');
    if (success) {
      final user = await DatabaseHelper.instance.getUserByIdentifier(
        email.trim(),
      );
      if (user != null && user[DatabaseHelper.columnBiometricRegistered] == 1) {
        // Establish the authenticated session securely
        await _secureStorage.write(
          key: 'session_token',
          value: user[DatabaseHelper.columnUserId].toString(),
        );
        return true;
      }
    }
    return false;
  }

  /// Strictly checks if the device has biometric hardware, is supported, and has biometrics enrolled.
  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      final List<BiometricType> availableBiometrics = await _auth
          .getAvailableBiometrics();

      return canCheckBiometrics &&
          isDeviceSupported &&
          availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Internal method to prompt the OS biometric dialog
  Future<bool> _promptBiometrics(String reason) async {
    try {
      final bool isAvailable = await isBiometricsAvailable();
      if (!isAvailable) {
        return false;
      }

      // Prompt the user for biometric authentication
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allows PIN/Password fallback
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      debugPrint('AUTH EXCEPTION: $e | TYPE: ${e.runtimeType}');
      return false;
    }
  }
}
