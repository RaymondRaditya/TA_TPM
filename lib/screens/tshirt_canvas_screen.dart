import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:tpm_ta/screens/parallax_preview_screen.dart';

class TShirtCanvasScreen extends StatefulWidget {
  const TShirtCanvasScreen({super.key});

  @override
  State<TShirtCanvasScreen> createState() => _TShirtCanvasScreenState();
}

class _TShirtCanvasScreenState extends State<TShirtCanvasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _allTemplates = [
    {'name': 'Classic Crewneck', 'imageRes': null, 'icon': Icons.checkroom},
    {'name': 'V-Neck Vintage', 'imageRes': null, 'icon': Icons.checkroom},
    {'name': 'Polo Shirt', 'imageRes': null, 'icon': Icons.checkroom},
    {'name': 'Long Sleeve Basic', 'imageRes': null, 'icon': Icons.checkroom},
    {'name': 'Slim Fit Tee', 'imageRes': null, 'icon': Icons.checkroom},
    {'name': 'Heavyweight Cotton', 'imageRes': null, 'icon': Icons.checkroom},
    {'name': 'Ringer Tee', 'imageRes': null, 'icon': Icons.checkroom},
    {'name': 'Sleeveless Tank', 'imageRes': null, 'icon': Icons.checkroom},
  ];
  List<Map<String, dynamic>> _filteredTemplates = [];

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  DateTime _lastShakeTime = DateTime.now();
  Color _tshirtColor = Colors.grey.shade200;
  IconData _selectedTemplateIcon = Icons.checkroom;
  final Random _random = Random();

  double _tiltX = 0.0;
  double _tiltY = 0.0;

  String _aiSlogan = '';
  bool _isGeneratingSlogan = false;

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

    // Subscribe to gyroscope for subtle 3D tilt effect
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      setState(() {
        _tiltX += event.y * 0.05;
        _tiltY += event.x * 0.05;
        _tiltX = _tiltX.clamp(-0.3, 0.3); // Restrict tilt angles
        _tiltY = _tiltY.clamp(-0.3, 0.3);
      });
    });
  }

  // Initial coordinates for the sticker
  double _stickerX = 100.0;
  double _stickerY = 150.0;

  // Canvas and sticker sizes for bounding logic
  final double _stickerSize = 80.0;
  final double _canvasWidth = 320.0;
  final double _canvasHeight = 200.0; // ISSUE 3 Fix: Canvas height set to 200dp

  void _filterTemplates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTemplates = _allTemplates
          .where((template) => template['name'].toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _searchController.removeListener(_filterTemplates);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _generateAISlogan() async {
    setState(() => _isGeneratingSlogan = true);
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: 'AIzaSyBMMKKnnkRY3bA4Kl1LhVGNV4HGvTiZyKg',
      );
      final content = [
        Content.text(
          'Generate a short, catchy 2 or 3-word slogan for a custom T-shirt. Only output the slogan text, no quotes or intro.',
        ),
      ];
      final response = await model.generateContent(content);

      if (mounted) {
        setState(() {
          _aiSlogan = response.text?.trim() ?? 'Awesome Shirt';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI generation failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingSlogan = false);
      }
    }
  }

  void _saveDesign() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Design saved! Coordinates processed.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
            height: 150,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredTemplates.length,
              itemBuilder: (context, index) {
                final template = _filteredTemplates[index];
                return ListTile(
                  // ISSUE 1 & 2 Fix: Bind image placeholder and fix click listener
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: template['imageRes'] != null
                        ? Image.asset(
                            template['imageRes'],
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Text(
                              '👕',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                  ),
                  title: Text(template['name']),
                  dense: true,
                  onTap: () {
                    // ISSUE 2 Fix: On click, load selected template (simulated by updating color)
                    setState(() {
                      _tshirtColor = Colors.primaries[index % Colors.primaries.length];
                      _selectedTemplateIcon = template['icon'];
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected: ${template['name']}')),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          // 3) T-Shirt Canvas
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspective
                            ..rotateX(_tiltX)
                            ..rotateY(_tiltY),
                          alignment: FractionalOffset.center,
                          child: Icon(
                            _selectedTemplateIcon,
                            size: _canvasWidth * 0.8,
                            color: _tshirtColor,
                          ),
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
                      // AI Slogan Layer
                      if (_aiSlogan.isNotEmpty)
                        Positioned(
                          left: _stickerX - 20,
                          top: _stickerY + _stickerSize + 10,
                          child: Text(
                            _aiSlogan,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _saveDesign,
              icon: const Icon(Icons.save, size: 24),
              label: const Text('Save Design'),
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
              label: const Text('3D Parallax Preview'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // 6) AI Slogan Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isGeneratingSlogan ? null : _generateAISlogan,
              icon: _isGeneratingSlogan
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 24),
              label: const Text('Generate AI Slogan'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.purple.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
