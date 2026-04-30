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

  // Store coordinates (Yogyakarta)
  final LatLng _storeLocation = const LatLng(-7.7956, 110.3695);

  void _goToStore() {
    _mapController.move(_storeLocation, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Locator')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _storeLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tpm_ta',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _storeLocation,
                    width: 80.0,
                    height: 80.0,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _goToStore,
              icon: const Icon(Icons.local_shipping),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Track My T-Shirt Delivery'),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
