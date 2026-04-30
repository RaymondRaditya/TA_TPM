import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class StoreLocatorScreen extends StatefulWidget {
  const StoreLocatorScreen({super.key});

  @override
  State<StoreLocatorScreen> createState() => StoreLocatorScreenState();
}

class StoreLocatorScreenState extends State<StoreLocatorScreen> {
  final MapController _mapController = MapController();

  // A list of store branches with their locations and timezone information
  final List<Map<String, dynamic>> _branches = [
    {
      'name': 'Jakarta Flagship (WIB)',
      'location': const LatLng(-6.2088, 106.8456),
      'timezoneKey': 'WIB',
    },
    {
      'name': 'Bali Pop-Up (WITA)',
      'location': const LatLng(-8.6705, 115.2126),
      'timezoneKey': 'WITA',
    },
    {
      'name': 'Papua Outlet (WIT)',
      'location': const LatLng(-2.5333, 140.7167),
      'timezoneKey': 'WIT',
    },
    {
      'name': 'London HQ (GMT)',
      'location': const LatLng(51.5072, -0.1276),
      'timezoneKey': 'London Time',
    },
  ];

  /// Returns a map of timezone keys to their current formatted time string (HH:mm).
  Map<String, String> getBranchTimes() {
    final nowUtc = DateTime.now().toUtc();

    String formatTime(DateTime dt) {
      final hours = dt.hour.toString().padLeft(2, '0');
      final minutes = dt.minute.toString().padLeft(2, '0');
      return '$hours:$minutes';
    }

    return {
      'WIB': formatTime(nowUtc.add(const Duration(hours: 7))),
      'WITA': formatTime(nowUtc.add(const Duration(hours: 8))),
      'WIT': formatTime(nowUtc.add(const Duration(hours: 9))),
      'London Time': formatTime(nowUtc.add(const Duration(hours: 0))),
    };
  }

  /// Helper to get DateTime objects for open/close logic.
  Map<String, DateTime> _getBranchDateTimes() {
    final nowUtc = DateTime.now().toUtc();
    return {
      'WIB': nowUtc.add(const Duration(hours: 7)),
      'WITA': nowUtc.add(const Duration(hours: 8)),
      'WIT': nowUtc.add(const Duration(hours: 9)),
      'London Time': nowUtc.add(const Duration(hours: 0)),
    };
  }

  /// Checks if a branch is open based on its local time.
  /// Branches are open from 09:00 to 21:00.
  bool isBranchOpen(DateTime localBranchTime) {
    return localBranchTime.hour >= 9 && localBranchTime.hour < 21;
  }

  /// Moves the map camera to the selected branch location.
  void _goToBranch(LatLng location) {
    _mapController.move(location, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    // Get a snapshot of the current times for this build frame.
    final branchDateTimes = _getBranchDateTimes();
    final formattedTimes = getBranchTimes();

    return Scaffold(
      appBar: AppBar(title: const Text('Store Locator')),
      body: Column(
        children: [
          // Part 1: The Map showing all branch locations
          Expanded(
            flex: 3, // Give more space to the map
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(
                  -2.5489,
                  118.0149,
                ), // Center of Indonesia
                initialZoom: 4.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tpm_ta',
                ),
                MarkerLayer(
                  markers: _branches.map((branch) {
                    return Marker(
                      point: branch['location'] as LatLng,
                      width: 80.0,
                      height: 80.0,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Part 2: The List of Branches with their status and local time
          Expanded(
            flex: 2, // Give less space to the list
            child: ListView.builder(
              itemCount: _branches.length,
              itemBuilder: (context, index) {
                final branch = _branches[index];
                final timezoneKey = branch['timezoneKey'] as String;
                final localTime = branchDateTimes[timezoneKey]!;
                final formattedTime = formattedTimes[timezoneKey]!;
                final isOpen = isBranchOpen(localTime);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    onTap: () => _goToBranch(branch['location'] as LatLng),
                    leading: const Icon(Icons.storefront),
                    title: Text(branch['name'] as String),
                    subtitle: Row(
                      children: [
                        Text(
                          isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: isOpen ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(' • Closes at 21:00'),
                      ],
                    ),
                    trailing: Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
