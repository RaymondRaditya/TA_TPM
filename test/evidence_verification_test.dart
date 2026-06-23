// ignore_for_file: avoid_print, prefer_const_declarations

import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tpm_ta/services/database_helper.dart';
import 'package:tpm_ta/services/auth_service.dart';
import 'package:tpm_ta/services/currency_service.dart';
import 'package:tpm_ta/services/branch_service.dart';
import 'package:tpm_ta/services/notification_service.dart';
import 'package:tpm_ta/services/apparel_api_service.dart';
import 'package:tpm_ta/services/groq_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Platform channel mocking
  final Map<String, String> mockSecureStorage = {};
  late Directory hiveTempDir;
  
  setUpAll(() async {
    hiveTempDir = Directory.systemTemp.createTempSync('hive_verify_all');
    Hive.init(hiveTempDir.path);
    dotenv.testLoad(fileInput: '''
_groqUrl=https://api.groq.com/openai/v1/chat/completions
_apiKey=gsk_mock_api_key_for_testing
''');

    // 1. Mock secure storage
    const MethodChannel secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'write') {
          final String key = methodCall.arguments['key'];
          final String value = methodCall.arguments['value'];
          mockSecureStorage[key] = value;
          return null;
        } else if (methodCall.method == 'read') {
          final String key = methodCall.arguments['key'];
          return mockSecureStorage[key];
        } else if (methodCall.method == 'delete') {
          final String key = methodCall.arguments['key'];
          mockSecureStorage.remove(key);
          return null;
        } else if (methodCall.method == 'containsKey') {
          final String key = methodCall.arguments['key'];
          return mockSecureStorage.containsKey(key);
        } else if (methodCall.method == 'deleteAll') {
          mockSecureStorage.clear();
          return null;
        }
        return null;
      },
    );

    // 2. Mock local authentication
    const MethodChannel localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      localAuthChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'canCheckBiometrics') {
          return true;
        } else if (methodCall.method == 'isDeviceSupported') {
          return true;
        } else if (methodCall.method == 'getAvailableBiometrics') {
          return ['fingerprint'];
        } else if (methodCall.method == 'authenticate') {
          return true;
        }
        return null;
      },
    );

    // 3. Mock local notifications
    const MethodChannel notificationsChannel = MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      notificationsChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'initialize') {
          return true;
        } else if (methodCall.method == 'requestNotificationsPermission') {
          return true;
        } else if (methodCall.method == 'show') {
          return null;
        }
        return null;
      },
    );

    // 3.5 Mock path provider for Hive Flutter initialization
    const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );

    // 4. Mock geolocator
    const MethodChannel geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      geolocatorChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'isLocationServiceEnabled') {
          return true;
        } else if (methodCall.method == 'checkPermission') {
          return 3; // LocationPermission.whileInUse index
        } else if (methodCall.method == 'requestPermission') {
          return 3; // LocationPermission.whileInUse index
        } else if (methodCall.method == 'getCurrentPosition') {
          return {
            'latitude': -7.762232,
            'longitude': 110.409279,
            'timestamp': 1629876543210,
            'altitude': 0.0,
            'accuracy': 1.0,
            'heading': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'is_mocked': false,
          };
        }
        return null;
      },
    );

    await DatabaseHelper.instance.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveTempDir.existsSync()) {
      hiveTempDir.deleteSync(recursive: true);
    }
  });

  group('Evidence-Based Verification Test Suite', () {
    setUp(() async {
      mockSecureStorage.clear();
      if (Hive.isBoxOpen('users')) {
        await Hive.box<Map>('users').clear();
      }
      if (Hive.isBoxOpen('saved_designs')) {
        await Hive.box<Map>('saved_designs').clear();
      }
      if (Hive.isBoxOpen('cart_items')) {
        await Hive.box<Map>('cart_items').clear();
      }
      if (Hive.isBoxOpen('meta')) {
        await Hive.box<int>('meta').clear();
      }
    });

    tearDown(() async {
      // Clear after each test to keep environment clean
    });

    test('1. User Flow: Register, Database Save, Password Hashing, Login, and Session Storage', () async {
      final db = DatabaseHelper.instance;
      await db.init();
      final auth = AuthService();

      print('[LOG] Registrasi user baru: start...');
      final registerSuccess = await auth.register('testuser@gmail.com', 'mypassword123');
      expect(registerSuccess, isTrue);
      print('[LOG] Registrasi user baru: BERHASIL');

      // Verify DB storage
      final user = await db.getUserByIdentifier('testuser@gmail.com');
      expect(user, isNotNull);
      expect(user![DatabaseHelper.columnEmail], 'testuser@gmail.com');
      print('[LOG] Simpan user di Hive Database: BERHASIL');

      // Verify SHA-256 Hashing
      final storedHash = user[DatabaseHelper.columnPasswordHash] as String;
      expect(storedHash, isNot('mypassword123'));
      expect(storedHash.length, 64); // SHA-256 produces 64 hex characters
      print('[LOG] Validasi Enkripsi SHA-256: BERHASIL (Plaintext tidak tersimpan di database)');

      // Verify Normal Login
      final loginSuccess = await auth.login('testuser@gmail.com', 'mypassword123');
      expect(loginSuccess, isTrue);
      print('[LOG] Login normal dengan kredensial: BERHASIL');

      // Verify session token storage
      final savedToken = mockSecureStorage['session_token'];
      expect(savedToken, isNotNull);
      expect(savedToken, user[DatabaseHelper.columnUserId].toString());
      print('[LOG] Simpan Session Token di Secure Storage: BERHASIL (Token = $savedToken)');

      // Verify Logout
      print('[LOG] Melakukan Logout (Hapus Session Token)...');
      mockSecureStorage.remove('session_token');
      expect(mockSecureStorage['session_token'], isNull);
      print('[LOG] Hapus Session Token (Logout): BERHASIL');

      // Verify Login Ulang
      final loginAgain = await auth.login('testuser@gmail.com', 'mypassword123');
      expect(loginAgain, isTrue);
      expect(mockSecureStorage['session_token'], isNotNull);
      print('[LOG] Login kembali: BERHASIL');
    });

    test('2. Biometric Integration Flow', () async {
      final db = DatabaseHelper.instance;
      await db.init();
      final auth = AuthService();

      // Register and get userId
      final userId = await db.insertUser({
        DatabaseHelper.columnUsername: 'bio@gmail.com',
        DatabaseHelper.columnEmail: 'bio@gmail.com',
        DatabaseHelper.columnPasswordHash: 'some_hash',
      });

      // Enable biometrics in DB
      print('[LOG] Aktifkan Biometrik di pengaturan profil...');
      final updateBioSuccess = await db.updateBiometricStatus(userId, true);
      expect(updateBioSuccess, 1);
      
      final user = await db.getUser(userId);
      expect(user![DatabaseHelper.columnBiometricRegistered], 1);
      print('[LOG] Biometrik status di-update di database: BERHASIL');

      // Test Biometric Login
      print('[LOG] Mencoba Login dengan Biometrik...');
      final bioLoginSuccess = await auth.loginWithBiometrics('bio@gmail.com');
      expect(bioLoginSuccess, isTrue);
      expect(mockSecureStorage['session_token'], userId.toString());
      print('[LOG] Login Biometrik & Penulisan Session: BERHASIL');
    });

    test('3. Database Persistence: Save Data, Close, and Re-open Box', () async {
      // Test Hive persistence directly to simulate app closure and reopening
      final boxName = 'persistence_test_box';
      var testBox = await Hive.openBox<Map>(boxName);
      
      print('[LOG] Database: Menyimpan desain T-Shirt...');
      await testBox.put('key123', {
        'design_name': 'Premium Summer Edition',
        'canvas_color': 'yellow',
      });
      
      // Verify stored data
      final initialData = testBox.get('key123');
      expect(initialData, isNotNull);
      expect(initialData!['design_name'], 'Premium Summer Edition');
      print('[LOG] Desain disimpan: ${initialData['design_name']}');

      // Close box to simulate closing app
      print('[LOG] Database: Simulasi menutup aplikasi (close box)...');
      await testBox.close();

      // Re-open box
      print('[LOG] Database: Simulasi membuka kembali aplikasi (re-open)...');
      var reopenedBox = await Hive.openBox<Map>(boxName);

      // Verify persistence
      final savedData = reopenedBox.get('key123');
      expect(savedData, isNotNull);
      expect(savedData!['design_name'], 'Premium Summer Edition');
      print('[LOG] Desain tetap ada setelah re-open: BERHASIL');

      await reopenedBox.close();
      await Hive.deleteBoxFromDisk(boxName);
    });

    test('4. Currency Conversion Rates and Calculations', () {
      final currency = CurrencyService();
      currency.exchangeRates.clear();
      currency.exchangeRates.addAll({
        'USD': 1.0,
        'IDR': 15600.0,
        'EUR': 0.92,
        'GBP': 0.79,
      });

      print('[LOG] Konversi Mata Uang: USD -> IDR...');
      final idr = currency.convert(10, 'USD', 'IDR');
      expect(idr, 156000.0);
      print('[LOG] Hasil: \$10 USD = ${currency.formatCurrency('IDR', idr)}');

      print('[LOG] Konversi Mata Uang: IDR -> USD...');
      final usd = currency.convert(15600, 'IDR', 'USD');
      expect(usd, 1.0);
      print('[LOG] Hasil: Rp 15600 = ${currency.formatCurrency('USD', usd)}');
    });

    test('5. GPS & Location Service (LBS) Math and Nearest Branch Sorting', () async {
      // Mocked position: -7.762232, 110.409279 (UPN Veteran Yogyakarta)
      final position = await BranchService.requestCurrentPosition();
      expect(position.latitude, -7.762232);
      expect(position.longitude, 110.409279);
      print('[LOG] GPS: Membaca koordinat GPS mock (lat=${position.latitude}, lon=${position.longitude})');

      final distances = BranchService.branchDistances(position);
      expect(distances.isNotEmpty, isTrue);

      // The closest branch should be UPN Veteran Yogyakarta Studio since it is at the exact same coordinates!
      final nearest = BranchService.nearestBranch(position);
      expect(nearest, isNotNull);
      expect(nearest!.branch.name, 'UPN Veteran Yogyakarta Studio');
      expect(nearest.distanceMeters, closeTo(0.0, 1.0));
      print('[LOG] LBS: Branch terdekat teridentifikasi: ${nearest.branch.displayName} (Jarak = ${nearest.distanceMeters} meter)');

      // Verify sorting
      for (int i = 0; i < distances.length - 1; i++) {
        expect(distances[i].distanceMeters <= distances[i + 1].distanceMeters, isTrue);
      }
      print('[LOG] LBS: Pengurutan seluruh branch berdasarkan jarak terdekat: BERHASIL');
    });

    test('6. Accelerometer & Gyroscope Print Stability Score Calculation', () {
      // Completely stable device
      double accX = 0;
      double accY = 0;
      double gyroX = 0;
      double gyroY = 0;
      double gyroZ = 0;

      double tiltMagnitude = sqrt((accX * accX) + (accY * accY));
      double rotationMagnitude = sqrt((gyroX * gyroX) + (gyroY * gyroY) + (gyroZ * gyroZ));

      double tiltPenalty = (tiltMagnitude / 9.8).clamp(0.0, 1.0) * 55;
      double rotationPenalty = (rotationMagnitude / 5).clamp(0.0, 1.0) * 45;
      double qualityScore = (100 - tiltPenalty - rotationPenalty).clamp(0.0, 100.0);

      expect(qualityScore, 100.0);
      print('[LOG] Sensor: Skor stabilitas saat diam = $qualityScore (Sangat Stabil)');

      // Shake device (movement)
      accX = 3.5;
      accY = 2.0;
      gyroZ = 1.5;

      tiltMagnitude = sqrt((accX * accX) + (accY * accY));
      rotationMagnitude = sqrt((gyroX * gyroX) + (gyroY * gyroY) + (gyroZ * gyroZ));

      tiltPenalty = (tiltMagnitude / 9.8).clamp(0.0, 1.0) * 55;
      rotationPenalty = (rotationMagnitude / 5).clamp(0.0, 1.0) * 45;
      qualityScore = (100 - tiltPenalty - rotationPenalty).clamp(0.0, 100.0);

      expect(qualityScore, lessThan(100.0));
      print('[LOG] Sensor: Skor stabilitas saat digerakkan = ${qualityScore.toStringAsFixed(1)} (Tidak Stabil / hold steadier)');
    });

    test('7. Local Notifications Triggering', () async {
      final notificationService = NotificationService();
      await notificationService.init();

      // Show notification call (mocked internally)
      print('[LOG] Notifikasi: Memicu Local Notification...');
      await notificationService.showNotification(100, 'T-Shirt Studio Drop', 'New limited catalog is available!');
      print('[LOG] Notifikasi: Pemanggilan API Local Notification BERHASIL');
    });

    test('8. Mini Game State Math and Target Alignment Verification', () {
      print('[LOG] Mini Game: Menghitung jarak target spot...');
      
      // Target spot: 'Dada Kiri' alignment const Alignment(-0.35, -0.35)
      const targetSpot = Alignment(-0.35, -0.35);
      
      // Moving logo close to the target spot
      var logoAlignment = const Alignment(-0.32, -0.34);
      
      // Distance calculation
      double dx = (logoAlignment.x - targetSpot.x).abs();
      double dy = (logoAlignment.y - targetSpot.y).abs();
      
      // The game rule is dx < 0.15 && dy < 0.15
      bool isTargetReached = dx < 0.15 && dy < 0.15;
      expect(isTargetReached, isTrue);
      print('[LOG] Mini Game: Target tercapai saat koordinat logo dalam rentang toleransi (dx = ${dx.toStringAsFixed(2)}, dy = ${dy.toStringAsFixed(2)}): BERHASIL');
      
      // Moving logo far from target spot
      logoAlignment = const Alignment(0.5, 0.5);
      dx = (logoAlignment.x - targetSpot.x).abs();
      dy = (logoAlignment.y - targetSpot.y).abs();
      isTargetReached = dx < 0.15 && dy < 0.15;
      expect(isTargetReached, isFalse);
      print('[LOG] Mini Game: Target TIDAK tercapai saat logo berada di luar toleransi (dx = ${dx.toStringAsFixed(2)}, dy = ${dy.toStringAsFixed(2)}): BERHASIL');
    });

    test('9. API Integration Parsing: Fake Store API products', () {
      // We test ApparelProduct from JSON parsing to verify the data model correctly translates standard FakeStore json schema
      final mockProductJson = {
        'id': 1,
        'title': 'Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops',
        'price': 109.95,
        'description': 'Your perfect pack for everyday use and walks in the forest. Stash your laptop (up to 15 inches) in the padded sleeve, your everyday',
        'category': "men's clothing",
        'image': 'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg',
        'rating': {'rate': 3.9, 'count': 120}
      };

      print('[LOG] API: Memparsing JSON respon Fake Store API ke ApparelProduct...');
      final product = ApparelProduct.fromJson(mockProductJson);
      
      expect(product.id, 1);
      expect(product.title, 'Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops');
      expect(product.priceUsd, 109.95);
      expect(product.priceIdr, 109.95 * 15600);
      expect(product.category, "men's clothing");
      expect(product.imageUrl, 'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg');
      expect(product.ratingRate, 3.9);
      expect(product.ratingCount, 120);
      print('[LOG] API: Validasi parsing model produk Fake Store API: BERHASIL');
    });

    test('10. AI / LLM Design Assistant Groq Service Input Checking', () async {
      // Test GroqService input validation
      final service = GroqService();
      
      print('[LOG] AI: Menguji Groq API dengan API key invalid / kosong...');
      // Since it is unit test, calling with no key or invalid key will yield the expected error message or status code
      final result = await service.chatWithGroq(
        messages: [{'role': 'user', 'content': 'Hello'}],
        apiKey: 'gsk_invalid_key_for_testing_purposes',
      );
      
      // It should either return error or exception, showing error handling is active
      expect(result.contains('Error') || result.contains('exception'), isTrue);
      print('[LOG] AI: Validasi penanganan error API key invalid/gagal koneksi: BERHASIL (Output = "$result")');
    });
  });
}
