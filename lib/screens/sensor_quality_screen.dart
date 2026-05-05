import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorQualityScreen extends StatefulWidget {
  const SensorQualityScreen({super.key});

  @override
  State<SensorQualityScreen> createState() => _SensorQualityScreenState();
}

class _SensorQualityScreenState extends State<SensorQualityScreen> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  double _accelerometerX = 0;
  double _accelerometerY = 0;
  double _accelerometerZ = 0;
  double _gyroscopeX = 0;
  double _gyroscopeY = 0;
  double _gyroscopeZ = 0;

  bool _isMonitoring = true;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!_isMonitoring || !mounted) return;
      setState(() {
        _accelerometerX = event.x;
        _accelerometerY = event.y;
        _accelerometerZ = event.z;
      });
    });

    _gyroscopeSubscription = gyroscopeEventStream().listen((event) {
      if (!_isMonitoring || !mounted) return;
      setState(() {
        _gyroscopeX = event.x;
        _gyroscopeY = event.y;
        _gyroscopeZ = event.z;
      });
    });
  }

  void _toggleMonitoring() {
    setState(() => _isMonitoring = !_isMonitoring);
  }

  double get _tiltMagnitude {
    return sqrt(
      (_accelerometerX * _accelerometerX) +
          (_accelerometerY * _accelerometerY),
    );
  }

  double get _rotationMagnitude {
    return sqrt(
      (_gyroscopeX * _gyroscopeX) +
          (_gyroscopeY * _gyroscopeY) +
          (_gyroscopeZ * _gyroscopeZ),
    );
  }

  double get _qualityScore {
    final tiltPenalty = (_tiltMagnitude / 9.8).clamp(0.0, 1.0) * 55;
    final rotationPenalty = (_rotationMagnitude / 5).clamp(0.0, 1.0) * 45;
    return (100 - tiltPenalty - rotationPenalty).clamp(0.0, 100.0);
  }

  String get _qualityLabel {
    if (_qualityScore >= 80) return 'Stable for print preview';
    if (_qualityScore >= 50) return 'Hold steadier';
    return 'Too much movement';
  }

  Color get _qualityColor {
    if (_qualityScore >= 80) return Colors.green;
    if (_qualityScore >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewOffset = Offset(
      _accelerometerX.clamp(-6, 6) * 8,
      _accelerometerY.clamp(-6, 6) * 8,
    );
    final previewRotation = _gyroscopeZ.clamp(-4, 4) * 0.08;

    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Print Check')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildPreview(previewOffset, previewRotation),
          const SizedBox(height: 16),
          _buildSensorReadouts(),
          const SizedBox(height: 16),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sensors),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motion-Based Print Stability',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _qualityLabel,
                  style: TextStyle(
                    color: _qualityColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _qualityScore.toStringAsFixed(0),
            style: TextStyle(
              color: _qualityColor,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(Offset previewOffset, double previewRotation) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            Transform.translate(
              offset: previewOffset,
              child: Transform.rotate(
                angle: previewRotation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.checkroom,
                      size: 128,
                      color: _qualityColor,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _qualityColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRINT ZONE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorReadouts() {
    return Column(
      children: [
        _buildSensorCard(
          title: 'Accelerometer',
          subtitle: 'Used for shirt tilt and balance',
          icon: Icons.screen_rotation,
          values: [
            _SensorValue('X', _accelerometerX),
            _SensorValue('Y', _accelerometerY),
            _SensorValue('Z', _accelerometerZ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSensorCard(
          title: 'Gyroscope',
          subtitle: 'Used for spin and shake stability',
          icon: Icons.threed_rotation,
          values: [
            _SensorValue('X', _gyroscopeX),
            _SensorValue('Y', _gyroscopeY),
            _SensorValue('Z', _gyroscopeZ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<_SensorValue> values,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: values
                  .map(
                    (value) => Expanded(
                      child: Column(
                        children: [
                          Text(
                            value.axis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            value.reading.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _toggleMonitoring,
        icon: Icon(_isMonitoring ? Icons.pause : Icons.play_arrow),
        label: Text(_isMonitoring ? 'Pause Sensor Check' : 'Resume Sensor Check'),
      ),
    );
  }
}

class _SensorValue {
  const _SensorValue(this.axis, this.reading);

  final String axis;
  final double reading;
}
