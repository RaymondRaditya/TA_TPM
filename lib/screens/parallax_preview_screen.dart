import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ParallaxPreviewScreen extends StatefulWidget {
  final String apparelType;
  final Color garmentColor;
  final List<Map<String, dynamic>> stickers;
  final String frontImageUrl;
  final String backImageUrl;

  const ParallaxPreviewScreen({
    super.key,
    required this.apparelType,
    required this.garmentColor,
    required this.stickers,
    required this.frontImageUrl,
    required this.backImageUrl,
  });

  @override
  State<ParallaxPreviewScreen> createState() => _ParallaxPreviewScreenState();
}

class _ParallaxPreviewScreenState extends State<ParallaxPreviewScreen> {
  double _tiltX = 0;
  double _tiltY = 0;
  double _rotationZ = 0;
  bool _showFront = true;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // Dimensions of the canvas reference vs preview dimensions
  final double _canvasWidth = 320.0;
  final double _canvasHeight = 240.0;
  final double _previewWidth = 260.0;
  final double _previewHeight = 260.0;

  @override
  void initState() {
    super.initState();

    // Listen to accelerometer for X/Y tilt (translation)
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _tiltX = event.x;
          _tiltY = event.y;
        });
      }
    });

    // Listen to gyroscope for twist (rotation)
    _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          _rotationZ = event.z * 0.1;
        });
      }
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

    // Scale factors for the stickers
    final scaleX = _previewWidth / _canvasWidth;
    final scaleY = _previewHeight / _canvasHeight;

    return Scaffold(
      appBar: AppBar(
        title: Text('3D Parallax: ${widget.apparelType}'),
        elevation: 2,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            const SizedBox(height: 24),
            // The 3D Parallax Container Area
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Card Layer (Moves slightly in the direction of tilt)
                    Transform.translate(
                      offset: Offset(dx * 0.4, dy * 0.4),
                      child: Container(
                        width: 300,
                        height: 420,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade100,
                              Colors.purple.shade300,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Text(
                              'Tilt HP Anda untuk Parallax 3D',
                              style: TextStyle(
                                color: Colors.deepPurple.shade900.withOpacity(0.6),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Foreground Layer: Plain T-Shirt + Stickers Mockup
                    // Moves inverse to tilt, plus rotation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      transform: Matrix4.translationValues(-dx, -dy, 0)..rotateZ(_rotationZ),
                      child: Container(
                        width: _previewWidth,
                        height: _previewHeight,
                        child: Stack(
                          children: [
                            // 1) Base plain apparel template tinted with modulate blend mode
                            Positioned.fill(
                              child: Image.network(
                                _showFront ? widget.frontImageUrl : widget.backImageUrl,
                                headers: const {
                                  'User-Agent':
                                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
                                },
                                color: widget.garmentColor,
                                colorBlendMode: BlendMode.modulate,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.checkroom,
                                    size: _previewWidth * 0.8,
                                    color: widget.garmentColor,
                                  );
                                },
                              ),
                            ),
                            
                            // 2) Draggable Stickers placed on the active side
                              ...widget.stickers.map((sticker) {
                                if (sticker['isFront'] != _showFront) {
                                  return const SizedBox.shrink();
                                }

                                final double posX = sticker['x'] * scaleX;
                                final double posY = sticker['y'] * scaleY;
                                final double currentSize = (sticker['size'] ?? 80.0) * scaleX;

                                return Positioned(
                                  left: posX,
                                  top: posY,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: sticker['imageUrl'].isEmpty
                                        ? FlutterLogo(size: currentSize)
                                        : Image.network(
                                            sticker['imageUrl'],
                                            headers: const {
                                              'User-Agent':
                                                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
                                            },
                                            width: currentSize,
                                            height: currentSize,
                                            fit: BoxFit.contain,
                                            errorBuilder: (c, e, s) => Container(
                                              width: currentSize,
                                              height: currentSize,
                                              color: Colors.grey.shade100,
                                              child: const Icon(Icons.broken_image, size: 20),
                                            ),
                                          ),
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Side Toggle Button & Info
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rotasi Sisi:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('Putar Mockup Kaos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      ToggleButtons(
                        isSelected: [_showFront, !_showFront],
                        onPressed: (index) {
                          setState(() {
                            _showFront = (index == 0);
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
                        children: const [
                          Text('Depan'),
                          Text('Belakang'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
