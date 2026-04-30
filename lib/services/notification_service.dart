import 'dart:async';

class NotificationService {
  /// A dummy function simulating a GCP WebSocket connection for push notifications.
  /// Yields status updates regarding the T-shirt printing process.
  Stream<String> listenForPrintStatus() async* {
    // Simulate connecting to the "WebSocket" server
    yield 'Connecting to the print facility server...';
    await Future.delayed(const Duration(seconds: 2));

    yield 'Order received! Preparing your design for printing...';

    // Mimicking the requested 5-second server processing delay
    await Future.delayed(const Duration(seconds: 5));

    // Server push notification simulation complete
    yield 'Your T-shirt is printed!';
  }
}
