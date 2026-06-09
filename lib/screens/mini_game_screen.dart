import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class FallingItem {
  final String id;
  final double x;
  double y;

  FallingItem({required this.id, required this.x, required this.y});
}

class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({super.key});

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  final List<FallingItem> _items = [];
  int _score = 0;
  int _timeLeft = 30;
  Timer? _gameLoop;
  Timer? _spawnLoop;
  Timer? _countdown;
  final Random _random = Random();

  late StreamSubscription<AccelerometerEvent> _accelSubscription;
  DateTime? _lastShakeTime;
  static const int _shakeThreshold = 30;
  static const int _shakeCooldown = 1000; // milliseconds
  final List<String> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _startGame();
    _initializeShakeDetection();
  }

  void _initializeShakeDetection() {
    _accelSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      _detectShake(event);
    });
  }

  void _detectShake(AccelerometerEvent event) {
    final now = DateTime.now();
    if (_lastShakeTime != null &&
        now.difference(_lastShakeTime!).inMilliseconds < _shakeCooldown) {
      return;
    }

    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (magnitude > _shakeThreshold && _timeLeft > 0) {
      _lastShakeTime = now;
      _onShakeDetected();
    }
  }

  void _onShakeDetected() {
    final voucherTypes = [
      'DISCOUNT_10',
      'DISCOUNT_15',
      'DISCOUNT_20',
      'FREE_SHIRT',
    ];
    final randomVoucher = voucherTypes[_random.nextInt(voucherTypes.length)];
    final voucherText = _getVoucherText(randomVoucher);

    setState(() {
      _vouchers.add(randomVoucher);
      _score += 5;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shake detected! Got voucher: $voucherText 🎉'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getVoucherText(String voucherCode) {
    switch (voucherCode) {
      case 'DISCOUNT_10':
        return '10% Discount';
      case 'DISCOUNT_15':
        return '15% Discount';
      case 'DISCOUNT_20':
        return '20% Discount';
      case 'FREE_SHIRT':
        return 'Free Shirt';
      default:
        return 'Mystery Voucher';
    }
  }

  void _startGame() {
    // 1) 30-Second Countdown
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        _endGame();
      }
    });

    // 2) Spawn new T-shirts periodically
    _spawnLoop = Timer.periodic(const Duration(milliseconds: 600), (_) {
      setState(() {
        _items.add(
          FallingItem(
            id:
                DateTime.now().millisecondsSinceEpoch.toString() +
                _random.nextInt(1000).toString(),
            x:
                _random.nextDouble() * 2 -
                1, // Random horizontal alignment (-1.0 to 1.0)
            y: -1.2, // Start slightly above the top of the screen
          ),
        );
      });
    });

    // 3) Physics/Animation loop to move items downwards
    _gameLoop = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        for (var item in _items) {
          item.y += 0.05; // Fall speed
        }
        // Remove items that fell off the bottom of the screen
        _items.removeWhere((item) => item.y > 1.2);
      });
    });
  }

  void _endGame() {
    _countdown?.cancel();
    _spawnLoop?.cancel();
    _gameLoop?.cancel();
    _accelSubscription.cancel();

    final voucherList = _vouchers.map(_getVoucherText).join(', ');
    final won = _score > 10;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Time is up!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                won
                    ? 'You scored $_score! You won a 10% discount!'
                    : 'You scored $_score. Try again next time!',
              ),
              if (_vouchers.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Vouchers from shake:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(voucherList),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, won ? 'DISCOUNT_10' : null);
              },
              child: const Text('Collect'),
            ),
          ],
        );
      },
    );
  }

  void _catchItem(FallingItem item) {
    setState(() {
      _score++;
      _items.remove(item);
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _spawnLoop?.cancel();
    _gameLoop?.cancel();
    _accelSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catch the Shirts!')),
      body: Stack(
        children: [
          // Background
          Container(color: Colors.blueGrey.shade50),

          // Falling Items mapped to alignment
          ..._items.map((item) {
            return Align(
              key: ValueKey(item.id),
              alignment: Alignment(item.x, item.y),
              child: GestureDetector(
                onTap: () => _catchItem(item),
                child: const Icon(
                  Icons.checkroom,
                  size: 60,
                  color: Colors.deepPurple,
                ),
              ),
            );
          }),

          // HUD Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: $_score',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Time: $_timeLeft',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Shake hint
          if (_vouchers.isEmpty)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.vibration, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Shake your phone to get bonus vouchers!',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
