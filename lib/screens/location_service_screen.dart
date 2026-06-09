import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationServiceScreen extends StatefulWidget {
  const LocationServiceScreen({super.key});

  @override
  State<LocationServiceScreen> createState() => _LocationServiceScreenState();
}

class _LocationServiceScreenState extends State<LocationServiceScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;

  Position? _currentPosition;
  bool _isTracking = false;
  bool _isLoading = false;
  String? _statusMessage;

  static const List<_BranchLocation> _branches = [
    _BranchLocation(
      name: 'Jakarta Flagship',
      region: 'WIB',
      point: LatLng(-6.2088, 106.8456),
      serviceNote: 'Same-day pickup and shirt fitting.',
    ),
    _BranchLocation(
      name: 'Bali Pop-Up',
      region: 'WITA',
      point: LatLng(-8.6705, 115.2126),
      serviceNote: 'Tour merch and lightweight cotton stock.',
    ),
    _BranchLocation(
      name: 'Papua Outlet',
      region: 'WIT',
      point: LatLng(-2.5333, 140.7167),
      serviceNote: 'Remote order pickup and local delivery.',
    ),
    _BranchLocation(
      name: 'London HQ',
      region: 'London',
      point: LatLng(51.5072, -0.1276),
      serviceNote: 'International production coordination.',
    ),
  ];

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _positionSubscription?.cancel();
      setState(() {
        _isTracking = false;
        _statusMessage = 'Tracking stopped.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        setState(() {
          _statusMessage = 'Location service is disabled on this device.';
          _isLoading = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = 'Location permission is required to find a branch.';
          _isLoading = false;
        });
        return;
      }

      // Start the position stream for better accuracy and real-time updates
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // Update every 5 meters
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        setState(() {
          _currentPosition = position;
          _isTracking = true;
          _isLoading = false;
        });

        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15,
        );
      }, onError: (error) {
        setState(() {
          _statusMessage = 'GPS Stream Error: $error';
          _isTracking = false;
          _isLoading = false;
        });
      });
    } catch (error) {
      setState(() {
        _statusMessage = 'Unable to start GPS tracking: $error';
        _isLoading = false;
      });
    }
  }

  _BranchDistance? _nearestBranch() {
    final position = _currentPosition;
    if (position == null) return null;

    final distances = _branchDistances(position)
      ..sort((first, second) => first.distanceMeters.compareTo(second.distanceMeters));

    return distances.isEmpty ? null : distances.first;
  }

  List<_BranchDistance> _branchDistances(Position position) {
    return _branches.map((branch) {
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        branch.point.latitude,
        branch.point.longitude,
      );

      return _BranchDistance(
        branch: branch,
        distanceMeters: distanceMeters,
      );
    }).toList();
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  _BranchDistance? _distanceForBranch(
    List<_BranchDistance> distances,
    _BranchLocation branch,
  ) {
    for (final distance in distances) {
      if (distance.branch == branch) return distance;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentPoint = _currentPosition == null
        ? null
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final nearestBranch = _nearestBranch();

    return Scaffold(
      appBar: AppBar(title: const Text('Nearest Branch GPS')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildMap(currentPoint, nearestBranch?.branch),
          ),
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildLocationPanel(nearestBranch),
                const SizedBox(height: 16),
                _buildBranchList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(LatLng? currentPoint, _BranchLocation? nearestBranch) {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(-2.5489, 118.0149),
        initialZoom: 4,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.tpm_ta',
        ),
        MarkerLayer(
          markers: [
            ..._branches.map(
              (branch) => Marker(
                point: branch.point,
                width: 64,
                height: 64,
                child: Icon(
                  Icons.storefront,
                  color: branch == nearestBranch ? Colors.green : Colors.red,
                  size: branch == nearestBranch ? 38 : 32,
                ),
              ),
            ),
            if (currentPoint != null)
              Marker(
                point: currentPoint,
                width: 64,
                height: 64,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.deepPurple,
                  size: 38,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationPanel(_BranchDistance? nearestBranch) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.near_me),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Find Nearest T-Shirt Studio',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_currentPosition == null)
            Text(
              _statusMessage ??
                  'Use GPS to calculate the nearest branch for pickup or delivery.',
              style: TextStyle(color: Colors.grey.shade700),
            )
          else ...[
            Text(
              'Your location: '
              '${_currentPosition!.latitude.toStringAsFixed(5)}, '
              '${_currentPosition!.longitude.toStringAsFixed(5)}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            if (nearestBranch != null)
              Text(
                '${nearestBranch.branch.name} is closest '
                '(${_formatDistance(nearestBranch.distanceMeters)}).',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
          ],
          if (_statusMessage != null && _currentPosition != null) ...[
            const SizedBox(height: 8),
            Text(_statusMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _toggleTracking,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isTracking ? Icons.location_off : Icons.gps_fixed),
              label: Text(_isLoading
                  ? 'Initializing...'
                  : _isTracking
                      ? 'Stop Tracking'
                      : 'Track My Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.red.shade400 : null,
                foregroundColor: _isTracking ? Colors.white : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchList() {
    final position = _currentPosition;
    final distances = position == null
        ? <_BranchDistance>[]
        : (_branchDistances(position)
          ..sort((first, second) => first.distanceMeters.compareTo(second.distanceMeters)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Branch Distance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._branches.map((branch) {
          final distance = _distanceForBranch(distances, branch);

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: const Icon(Icons.storefront),
              title: Text(branch.name),
              subtitle: Text('${branch.region} - ${branch.serviceNote}'),
              trailing: Text(
                distance == null
                    ? 'GPS needed'
                    : _formatDistance(distance.distanceMeters),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _mapController.move(branch.point, 12),
            ),
          );
        }),
      ],
    );
  }
}

class _BranchLocation {
  const _BranchLocation({
    required this.name,
    required this.region,
    required this.point,
    required this.serviceNote,
  });

  final String name;
  final String region;
  final LatLng point;
  final String serviceNote;
}

class _BranchDistance {
  const _BranchDistance({
    required this.branch,
    required this.distanceMeters,
  });

  final _BranchLocation branch;
  final double distanceMeters;
}
