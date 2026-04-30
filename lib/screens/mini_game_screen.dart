import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    // 1) 30-Second Countdown
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        _endGame();
      }
    });

    // 2) Spawn new T-shirts periodically
    _spawnLoop = Timer.periodic(const Duration(milliseconds: 600), (timer) {
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
    _gameLoop = Timer.periodic(const Duration(milliseconds: 50), (timer) {
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final won = _score > 10;
        return AlertDialog(
          title: const Text('Time is up!'),
          content: Text(
            won
                ? 'You scored $_score! You won a 10% discount!'
                : 'You scored $_score. Try again next time!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close the dialog
                Navigator.pop(
                  context,
                  won ? 'DISCOUNT_10' : null,
                ); // Return to checkout
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
        ],
      ),
    );
  }
}
