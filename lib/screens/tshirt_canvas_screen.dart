import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tpm_ta/screens/parallax_preview_screen.dart';
import 'package:tpm_ta/screens/checkout_screen.dart';

class TShirtCanvasScreen extends StatefulWidget {
  const TShirtCanvasScreen({super.key});

  @override
  State<TShirtCanvasScreen> createState() => _TShirtCanvasScreenState();
}

class _TShirtCanvasScreenState extends State<TShirtCanvasScreen> {
  final TextEditingController _aiStickerController = TextEditingController();
  final TextEditingController _customPngController = TextEditingController();

  // Apparel Type & Sizing State
  String _apparelType = 'T-Shirt'; // T-Shirt, Jacket, Hoodie
  String _selectedSize = 'L'; // S, M, L, XL, XXL
  bool _isFrontView = true; // true = Front, false = Back

  // Available Sizes
  final List<String> _sizes = ['S', 'M', 'L', 'XL', 'XXL'];

  // Colors
  Color _tshirtColor = Colors.deepPurple.shade100;
  final Random _random = Random();

  // Gyroscope tilt logic
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  DateTime _lastShakeTime = DateTime.now();
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // Draggable stickers state
  // Multiple stickers can be placed on Front or Back of the garment
  final List<Map<String, dynamic>> _stickers = [
    {
      'id': 'sticker_1',
      'x': 120.0,
      'y': 60.0,
      'size': 80.0,
      'imageUrl': '', // Empty means FlutterLogo placeholder
      'prompt': '',
      'isFront': true,
    }
  ];
  int _selectedStickerIndex = 0; // Currently selected sticker to customize
  bool _isGeneratingSticker = false;

  // Static templates structure
  final List<Map<String, dynamic>> _apparelTemplates = [
    {
      'type': 'T-Shirt',
      'name': 'Classic Cotton Tee',
      'basePrice': 100000.0,
      'frontImage': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Jersey_white.svg/500px-Jersey_white.svg.png',
      'backImage': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Jersey_white.svg/500px-Jersey_white.svg.png',
      'icon': Icons.checkroom,
    },
    {
      'type': 'Hoodie',
      'name': 'Streetwear Hoodie',
      'basePrice': 160000.0,
      'frontImage': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Jersey_white.svg/500px-Jersey_white.svg.png',
      'backImage': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Jersey_white.svg/500px-Jersey_white.svg.png',
      'icon': Icons.layers,
    },
    {
      'type': 'Jacket',
      'name': 'Custom Windbreaker',
      'basePrice': 180000.0,
      'frontImage': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Jersey_white.svg/500px-Jersey_white.svg.png',
      'backImage': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Jersey_white.svg/500px-Jersey_white.svg.png',
      'icon': Icons.filter_hdr,
    },
  ];

  // Presets of PNG stickers that are free and look good
  final List<Map<String, String>> _presetPngs = [
    {
      'name': 'Astronaut',
      'url': 'https://www.pngmart.com/files/22/Cute-Astronaut-PNG-Photos.png',
    },
    {
      'name': 'Retro Sun',
      'url': 'https://www.pngmart.com/files/16/Retro-Sun-PNG-Clipart.png',
    },
    {
      'name': 'Gaming Skull',
      'url': 'https://www.pngmart.com/files/15/Vector-Skull-PNG-Transparent-Image.png',
    },
    {
      'name': 'Hot Flame',
      'url': 'https://www.pngmart.com/files/7/Flame-PNG-Clipart.png',
    },
  ];

  // Sizes of canvas
  final double _canvasWidth = 320.0;
  final double _canvasHeight = 240.0;

  @override
  void initState() {
    super.initState();

    // Accelerometer shake color change
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      final double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude > 15.0) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inMilliseconds >= 1000) {
          _lastShakeTime = now;
          setState(() {
            _tshirtColor = Colors.primaries[_random.nextInt(Colors.primaries.length)];
          });
        }
      }
    });

    // Gyroscope tilt effect
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      setState(() {
        _tiltX += event.y * 0.05;
        _tiltY += event.x * 0.05;
        _tiltX = _tiltX.clamp(-0.3, 0.3);
        _tiltY = _tiltY.clamp(-0.3, 0.3);
      });
    });
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _aiStickerController.dispose();
    _customPngController.dispose();
    super.dispose();
  }

  // Price Calculation Logic
  double _calculateTotalPrice() {
    // 1) Find base price for selected apparel type
    final basePrice = _apparelTemplates.firstWhere(
      (element) => element['type'] == _apparelType,
      orElse: () => _apparelTemplates[0],
    )['basePrice'] as double;

    // 2) Size surcharge
    double sizePrice = 0.0;
    if (_selectedSize == 'XL') {
      sizePrice = 10000.0;
    } else if (_selectedSize == 'XXL') {
      sizePrice = 15000.0;
    }

    // 3) Print costs (Rp 15.000 per sticker)
    final double printPrice = _stickers.length * 15000.0;

    return basePrice + sizePrice + printPrice;
  }

  void _generateAISticker() {
    final prompt = _aiStickerController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis deskripsi stiker terlebih dahulu!')),
      );
      return;
    }

    if (_stickers.isEmpty || _selectedStickerIndex >= _stickers.length) return;

    setState(() {
      _isGeneratingSticker = true;
      final randomSeed = Random().nextInt(999999);
      final finalUrl =
          'https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}?width=256&height=256&nologo=true&seed=$randomSeed';
      
      _stickers[_selectedStickerIndex]['imageUrl'] = finalUrl;
      _stickers[_selectedStickerIndex]['prompt'] = prompt;
    });
  }

  void _applyCustomPngUrl() {
    final url = _customPngController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan URL Gambar PNG terlebih dahulu!')),
      );
      return;
    }

    if (_stickers.isEmpty || _selectedStickerIndex >= _stickers.length) return;

    setState(() {
      _stickers[_selectedStickerIndex]['imageUrl'] = url;
      _stickers[_selectedStickerIndex]['prompt'] = 'Custom URL';
    });
    
    _customPngController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gambar PNG berhasil diterapkan!')),
    );
  }

  void _applyPresetPng(String url) {
    if (_stickers.isEmpty || _selectedStickerIndex >= _stickers.length) return;

    setState(() {
      _stickers[_selectedStickerIndex]['imageUrl'] = url;
      _stickers[_selectedStickerIndex]['prompt'] = 'Preset PNG';
    });
  }

  void _addNewSticker() {
    setState(() {
      final newSticker = {
        'id': 'sticker_${DateTime.now().millisecondsSinceEpoch}',
        'x': 120.0,
        'y': 80.0,
        'size': 80.0,
        'imageUrl': '',
        'prompt': '',
        'isFront': _isFrontView,
      };
      _stickers.add(newSticker);
      _selectedStickerIndex = _stickers.length - 1;
      _aiStickerController.clear();
      _customPngController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stiker/Sablon baru ditambahkan! (Biaya: +Rp 15.000)')),
    );
  }

  void _removeSticker() {
    if (_stickers.isEmpty) return;
    
    setState(() {
      _stickers.removeAt(_selectedStickerIndex);
      _selectedStickerIndex = _stickers.isEmpty ? 0 : _stickers.length - 1;
      _aiStickerController.clear();
      _customPngController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stiker/Sablon berhasil dihapus.')),
    );
  }

  void _proceedToCheckout() {
    final totalPrice = _calculateTotalPrice();
    
    // Set static parameters of CheckoutScreen
    CheckoutScreen.checkoutPrice = totalPrice;
    CheckoutScreen.checkoutItemType = _apparelType;
    CheckoutScreen.checkoutItemSize = _selectedSize;
    CheckoutScreen.checkoutStickerCount = _stickers.length;
    CheckoutScreen.checkoutItemName =
        'Custom $_apparelType Design (${_stickers.length} Sablon, Size $_selectedSize)';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Desain dikirim ke checkout! Mengalihkan...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Redirect user to the Checkout Screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculateTotalPrice();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1) Choose Apparel Type & Size Selection
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _apparelType,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Pakaian',
                              border: OutlineInputBorder(),
                            ),
                            items: _apparelTemplates.map((template) {
                              return DropdownMenuItem<String>(
                                value: template['type'],
                                child: Row(
                                  children: [
                                    Icon(template['icon'], size: 18),
                                    const SizedBox(width: 8),
                                    Text(template['type']),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _apparelType = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSize,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Ukuran',
                              border: OutlineInputBorder(),
                            ),
                            items: _sizes.map((size) {
                              return DropdownMenuItem<String>(
                                value: size,
                                child: Text(size),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSize = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2) Mockup Toggle View (Front / Back) & Color Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ToggleButtons(
                  isSelected: [_isFrontView, !_isFrontView],
                  onPressed: (index) {
                    setState(() {
                      _isFrontView = (index == 0);
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
                  children: const [
                    Text('Depan (Front)'),
                    Text('Belakang (Back)'),
                  ],
                ),
                Text(
                  'Shake HP untuk Ganti Warna',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // 3) Interactive Mockup Canvas
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
                      // Base Garment Background (Simulated 3D Tilt)
                      Positioned.fill(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspective
                            ..rotateX(_tiltX)
                            ..rotateY(_tiltY),
                          alignment: FractionalOffset.center,
                          child: Image.network(
                            _isFrontView
                                ? _apparelTemplates.firstWhere((t) => t['type'] == _apparelType)['frontImage']!
                                : _apparelTemplates.firstWhere((t) => t['type'] == _apparelType)['backImage']!,
                            headers: const {
                              'User-Agent':
                                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
                            },
                            color: _tshirtColor,
                            colorBlendMode: BlendMode.modulate,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _apparelTemplates.firstWhere(
                                  (t) => t['type'] == _apparelType,
                                  orElse: () => _apparelTemplates[0],
                                )['icon'] as IconData,
                                size: _canvasWidth * 0.75,
                                color: _tshirtColor,
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Label overlay indicating current side view
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isFrontView ? 'DEPAN (FRONT)' : 'BELAKANG (BACK)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Draggable stickers layer (renders stickers matching current view)
                      if (_stickers.isNotEmpty)
                        ..._stickers.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final sticker = entry.value;

                          if (sticker['isFront'] != _isFrontView) {
                            return const SizedBox.shrink();
                          }

                          final isSelected = idx == _selectedStickerIndex;
                          final double currentSize = sticker['size'] ?? 80.0;

                          return Positioned(
                            left: sticker['x'],
                            top: sticker['y'],
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedStickerIndex = idx;
                                  _aiStickerController.clear();
                                  _customPngController.clear();
                                });
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  sticker['x'] += details.delta.dx;
                                  sticker['y'] += details.delta.dy;

                                  // Boundaries clamped dynamically by size
                                  sticker['x'] = sticker['x'].clamp(
                                    0.0,
                                    _canvasWidth - currentSize,
                                  );
                                  sticker['y'] = sticker['y'].clamp(
                                    0.0,
                                    _canvasHeight - currentSize,
                                  );
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? Colors.purple : Colors.grey.shade400,
                                    width: isSelected ? 3 : 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                child: sticker['imageUrl'].isEmpty
                                    ? Container(
                                        width: currentSize - 6,
                                        height: currentSize - 6,
                                        alignment: Alignment.center,
                                        child: const Text('Tap & Design', style: TextStyle(fontSize: 10)),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          sticker['imageUrl'],
                                          headers: const {
                                            'User-Agent':
                                                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
                                          },
                                          width: currentSize - 6,
                                          height: currentSize - 6,
                                          loadingBuilder: (context, child, progress) {
                                            if (progress == null) {
                                              if (_isGeneratingSticker && idx == _selectedStickerIndex) {
                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                  setState(() => _isGeneratingSticker = false);
                                                });
                                              }
                                              return child;
                                            }
                                            return Container(
                                              width: currentSize - 6,
                                              height: currentSize - 6,
                                              color: Colors.grey.shade100,
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, err, stack) {
                                            if (_isGeneratingSticker && idx == _selectedStickerIndex) {
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                setState(() => _isGeneratingSticker = false);
                                              });
                                            }
                                            return Container(
                                              width: currentSize - 6,
                                              height: currentSize - 6,
                                              color: Colors.red.shade50,
                                              child: const Icon(Icons.broken_image, color: Colors.red, size: 24),
                                            );
                                          },
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4) Sticker Manager Controls (Add/Remove)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addNewSticker,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Tambah Sablon'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple.shade50, foregroundColor: Colors.deepPurple),
                  ),
                ),
                if (_stickers.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _removeSticker,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Hapus Sablon'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 5) Selected Sticker Editor (AI prompt, Custom URL, or Presets)
          if (_stickers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Sablon #${_selectedStickerIndex + 1} (${_stickers[_selectedStickerIndex]['isFront'] ? 'Depan' : 'Belakang'})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepPurple),
                          ),
                          const Icon(Icons.edit, size: 18, color: Colors.deepPurple),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Sticker Size Adjustment
                      const Text('Ukuran Sablon:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: (_stickers[_selectedStickerIndex]['size'] ?? 80.0) as double,
                              min: 40.0,
                              max: 160.0,
                              divisions: 12,
                              label: '${(_stickers[_selectedStickerIndex]['size'] ?? 80.0).round()} px',
                              onChanged: (val) {
                                setState(() {
                                  _stickers[_selectedStickerIndex]['size'] = val;
                                  // Re-clamp coordinates to avoid overflowing the canvas boundaries when scaled up
                                  final double x = _stickers[_selectedStickerIndex]['x'] ?? 0.0;
                                  final double y = _stickers[_selectedStickerIndex]['y'] ?? 0.0;
                                  _stickers[_selectedStickerIndex]['x'] = x.clamp(0.0, _canvasWidth - val);
                                  _stickers[_selectedStickerIndex]['y'] = y.clamp(0.0, _canvasHeight - val);
                                });
                              },
                            ),
                          ),
                          Text('${(_stickers[_selectedStickerIndex]['size'] ?? 80.0).round()} px', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),

                      const Divider(height: 24),
                      
                      // AI Generation
                      const Text('Buat Logo dengan AI (Pollinations AI):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _aiStickerController,
                              decoration: const InputDecoration(
                                hintText: 'Prompt AI: a cute puppy sticker, vector...',
                                hintStyle: TextStyle(fontSize: 12),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isGeneratingSticker ? null : _generateAISticker,
                            child: _isGeneratingSticker
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Generate'),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 24),
                      
                      // Custom PNG input
                      const Text('Tempel URL Gambar PNG Kustom:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customPngController,
                              decoration: const InputDecoration(
                                hintText: 'URL Gambar: https://domain.com/logo.png',
                                hintStyle: TextStyle(fontSize: 12),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _applyCustomPngUrl,
                            child: const Text('Terapkan'),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // Presets PNG Selection
                      const Text('Pilih Preset Desain Cepat:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _presetPngs.map((preset) {
                          return ActionChip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              backgroundImage: NetworkImage(preset['url']!),
                            ),
                            label: Text(preset['name']!, style: const TextStyle(fontSize: 11)),
                            onPressed: () => _applyPresetPng(preset['url']!),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 6) Display Price & Checkout Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              color: Colors.deepPurple.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimasi Harga Total:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          'Rp ${totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _proceedToCheckout,
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Pesan & Checkout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 3D Parallax Preview Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              onPressed: () {
                final template = _apparelTemplates.firstWhere((t) => t['type'] == _apparelType);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ParallaxPreviewScreen(
                      apparelType: _apparelType,
                      garmentColor: _tshirtColor,
                      stickers: _stickers,
                      frontImageUrl: template['frontImage']!,
                      backImageUrl: template['backImage']!,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.threed_rotation),
              label: const Text('Lihat Preview 3D Parallax'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
