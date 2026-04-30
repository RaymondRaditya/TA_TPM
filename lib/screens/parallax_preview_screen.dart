import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ParallaxPreviewScreen extends StatefulWidget {
  const ParallaxPreviewScreen({super.key});

  @override
  State<ParallaxPreviewScreen> createState() => _ParallaxPreviewScreenState();
}

class _ParallaxPreviewScreenState extends State<ParallaxPreviewScreen> {
  double _tiltX = 0;
  double _tiltY = 0;
  double _rotationZ = 0;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  @override
  void initState() {
    super.initState();

    // Listen to accelerometer for X/Y tilt (translation)
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      setState(() {
        _tiltX = event.x;
        _tiltY = event.y;
      });
    });

    // Listen to gyroscope for twist (rotation)
    _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event) {
      setState(() {
        // Gyroscope outputs rad/s. A subtle fraction works well for a reactive twist.
        _rotationZ = event.z * 0.1;
      });
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Amplify the accelerometer values to make the parallax noticeable
    final dx = _tiltX * 15;
    final dy = _tiltY * 15;

    return Scaffold(
      appBar: AppBar(title: const Text('3D Parallax Preview')),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Layer (Moves slightly in the direction of tilt)
            Transform.translate(
              offset: Offset(dx * 0.4, dy * 0.4),
              child: Container(
                width: 320,
                height: 450,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade100,
                      Colors.purple.shade200,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            // Foreground Layer: T-Shirt (Moves drastically inverse to tilt, plus rotation)
            AnimatedContainer(
              duration: const Duration(
                milliseconds: 100,
              ), // Smooths out sensor noise
              transform: Matrix4.translationValues(-dx, -dy, 0)
                ..rotateZ(_rotationZ),
              child: const Icon(
                Icons.checkroom,
                size: 250,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 15,
                    offset: Offset(5, 5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
