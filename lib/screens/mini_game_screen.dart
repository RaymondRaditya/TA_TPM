import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tpm_ta/services/notification_service.dart';

class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({super.key});

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  // Game State
  Alignment _logoAlignment = Alignment.center;
  late Alignment _targetAlignment;
  late String _targetName;
  int _score = 0;
  int _timeLeft = 30;
  bool _isGameOver = false;
  Timer? _timer;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  final Map<String, Alignment> _targetSpots = {
    'Dada Kiri': const Alignment(-0.35, -0.35),
    'Dada Kanan': const Alignment(0.35, -0.35),
    'Lengan Kiri': const Alignment(-0.75, -0.1),
    'Lengan Kanan': const Alignment(0.75, -0.1),
  };

  @override
  void initState() {
    super.initState();
    _pickNewTarget();
    _startTimer();
    _listenToAccelerometer();
  }

  void _pickNewTarget() {
    final random = Random();
    final keys = _targetSpots.keys.toList();
    _targetName = keys[random.nextInt(keys.length)];
    _targetAlignment = _targetSpots[_targetName]!;
    _logoAlignment = Alignment.center; // Reset logo to center
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _endGame();
      }
    });
  }

  void _listenToAccelerometer() {
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (_isGameOver) return;

      setState(() {
        // Update logo alignment based on tilt
        // x: -10 to 10 usually, map to Alignment -1 to 1
        // y: -10 to 10 usually, map to Alignment -1 to 1
        // We invert x because tilting left (positive x) should move left (negative alignment)
        double newX = _logoAlignment.x - (event.x * 0.05);
        double newY = _logoAlignment.y + (event.y * 0.05);

        // Constrain to shirt area (roughly -0.9 to 0.9)
        newX = newX.clamp(-0.9, 0.9);
        newY = newY.clamp(-0.9, 0.9);

        _logoAlignment = Alignment(newX, newY);

        // Check if close to target
        if ((_logoAlignment.x - _targetAlignment.x).abs() < 0.15 &&
            (_logoAlignment.y - _targetAlignment.y).abs() < 0.15) {
          _onTargetReached();
        }
      });
    });
  }

  void _onTargetReached() {
    setState(() {
      _score++;
      if (_score >= 5) {
        _endGame(won: true);
      } else {
        _pickNewTarget();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mantap! Target tercapai. Cari yang berikutnya!'),
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  void _endGame({bool won = false}) async {
    if (_isGameOver) return;
    setState(() {
      _isGameOver = true;
    });
    _timer?.cancel();
    _accelSubscription?.cancel();

    final isWin = won || _score >= 3;

    // Show notification
    await NotificationService().showNotification(
      2,
      isWin ? 'Game Selesai: Anda Menang! 🎉' : 'Game Selesai: Coba Lagi 🎮',
      isWin 
          ? 'Selamat! Anda berhasil menempatkan $_score desain dan mendapat diskon 10%.' 
          : 'Waktu habis! Anda menempatkan $_score desain. Main lagi yuk!',
    );

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(isWin ? 'Selamat!' : 'Waktu Habis'),
          content: Text(
            isWin
                ? 'Anda berhasil menempatkan $_score desain! Anda mendapatkan diskon 10%.'
                : 'Anda hanya menempatkan $_score desain. Coba lagi untuk dapat diskon!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, isWin ? 'DISCOUNT_10' : null);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desain Kaos Accelerometer'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target: $_targetName', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    Text('Score: $_score / 5', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text('$_timeLeft', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 2),
                ),
                child: AspectRatio(
                  aspectRatio: 0.8,
                  child: Stack(
                    children: [
                      // Kaos Template (Background)
                      const Center(
                        child: Icon(
                          Icons.checkroom,
                          size: 300,
                          color: Colors.white,
                        ),
                      ),
                      
                      // Target Spot (Hint)
                      Align(
                        alignment: _targetAlignment,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: const Center(
                            child: Icon(Icons.location_on, color: Colors.green),
                          ),
                        ),
                      ),
                      
                      // Moving Logo
                      Align(
                        alignment: _logoAlignment,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.brush, color: Colors.white, size: 30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Miringkan HP Anda untuk mengarahkan desain (kotak ungu) ke target (lingkaran hijau)!',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
