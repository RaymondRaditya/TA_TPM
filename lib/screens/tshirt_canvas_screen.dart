import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tpm_ta/screens/parallax_preview_screen.dart';

class TShirtCanvasScreen extends StatefulWidget {
  const TShirtCanvasScreen({super.key});

  @override
  State<TShirtCanvasScreen> createState() => _TShirtCanvasScreenState();
}

class _TShirtCanvasScreenState extends State<TShirtCanvasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _allTemplates = [
    'Classic Crewneck',
    'V-Neck Vintage',
    'Polo Shirt',
    'Long Sleeve Basic',
    'Slim Fit Tee',
    'Heavyweight Cotton',
    'Ringer Tee',
    'Sleeveless Tank',
  ];
  List<String> _filteredTemplates = [];

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  DateTime _lastShakeTime = DateTime.now();
  Color _tshirtColor = Colors.grey.shade200;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _filteredTemplates = _allTemplates;
    _searchController.addListener(_filterTemplates);

    // Subscribe to accelerometer events to detect shakes
    _accelSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      final double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude > 15.0) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inMilliseconds >= 1000) {
          _lastShakeTime = now;
          setState(() {
            _tshirtColor =
                Colors.primaries[_random.nextInt(Colors.primaries.length)];
          });
        }
      }
    });
  }

  // Initial coordinates for the sticker
  double _stickerX = 100.0;
  double _stickerY = 150.0;

  // Canvas and sticker sizes for bounding logic
  final double _stickerSize = 80.0;
  final double _canvasWidth = 320.0;
  final double _canvasHeight = 450.0;

  void _filterTemplates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTemplates = _allTemplates
          .where((template) => template.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _searchController.removeListener(_filterTemplates);
    _searchController.dispose();
    super.dispose();
  }

  void _saveDesign() {
    // Print coordinates to the console
    print('=== DESIGN SAVED ===');
    print(
      'Sticker Coordinates - X: ${_stickerX.toStringAsFixed(2)}, Y: ${_stickerY.toStringAsFixed(2)}',
    );
    print('====================');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Design saved! Check console for coordinates.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1) Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search T-Shirt Templates',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // 2) Filtered List
        SizedBox(
          height: 120, // Give a fixed height to the list view
          child: ListView.builder(
            itemCount: _filteredTemplates.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.style_outlined),
                title: Text(_filteredTemplates[index]),
                dense: true,
              );
            },
          ),
        ),
        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
        // 3) T-Shirt Canvas
        Expanded(
          child: Center(
            child: Container(
              width: _canvasWidth,
              height: _canvasHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // Bottom Layer: Static plain T-shirt representation
                    Positioned.fill(
                      child: Icon(
                        Icons.checkroom,
                        size:
                            _canvasWidth *
                            1.2, // Scale up icon to look like a shirt
                        color: _tshirtColor,
                      ),
                    ),
                    // Top Layer: Draggable sticker/logo
                    Positioned(
                      left: _stickerX,
                      top: _stickerY,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _stickerX += details.delta.dx;
                            _stickerY += details.delta.dy;

                            // Keep the sticker strictly within the canvas bounds
                            _stickerX = _stickerX.clamp(
                              0.0,
                              _canvasWidth - _stickerSize,
                            );
                            _stickerY = _stickerY.clamp(
                              0.0,
                              _canvasHeight - _stickerSize,
                            );
                          });
                        },
                        // Using a placeholder FlutterLogo as the sticker
                        child: FlutterLogo(size: _stickerSize),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 4) Save Button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: ElevatedButton.icon(
            onPressed: _saveDesign,
            icon: const Icon(Icons.save, size: 24),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Save Design', style: TextStyle(fontSize: 18)),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // 5) Parallax Preview Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParallaxPreviewScreen(),
                ),
              );
            },
            icon: const Icon(Icons.threed_rotation, size: 24),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                '3D Parallax Preview',
                style: TextStyle(fontSize: 18),
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
