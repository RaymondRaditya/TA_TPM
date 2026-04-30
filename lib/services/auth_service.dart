import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks for biometric availability and attempts to authenticate the user.
  /// Returns [true] if authentication is successful, [false] otherwise.
  Future<bool> authenticateUser() async {
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
        localizedReason:
            'Scan your fingerprint/face to login to your T-shirt design workspace',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
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
