import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:tpm_ta/services/branch_service.dart';

class FindOurBranchScreen extends StatefulWidget {
  const FindOurBranchScreen({super.key});

  @override
  State<FindOurBranchScreen> createState() => _FindOurBranchScreenState();
}

class _FindOurBranchScreenState extends State<FindOurBranchScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  Position? _currentPosition;
  bool _showNearestBranch = true;
  bool _isLoadingLocation = false;
  String _searchQuery = '';
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    if (!_showNearestBranch) return;

    setState(() {
      _isLoadingLocation = true;
      _statusMessage = null;
    });

    try {
      final position = await BranchService.requestCurrentPosition();
      final nearestBranch = BranchService.nearestBranch(position);

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      if (nearestBranch != null) {
        _mapController.move(nearestBranch.branch.point, 9);
      }
    } on BranchLocationException catch (error) {
      if (!mounted) return;
      setState(() {
        _currentPosition = null;
        _showNearestBranch = false;
        _isLoadingLocation = false;
        _statusMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _currentPosition = null;
        _showNearestBranch = false;
        _isLoadingLocation = false;
        _statusMessage = 'Unable to read GPS location: $error';
      });
    }
  }

  void _toggleNearestBranch(bool value) {
    setState(() {
      _showNearestBranch = value;
      if (!value) {
        _statusMessage = null;
      }
    });

    if (value) {
      _loadCurrentLocation();
    } else {
      _mapController.move(const LatLng(-2.5489, 118.0149), 4);
    }
  }

  void _goToBranch(LatLng location) {
    _mapController.move(location, 14);
  }

  List<BranchLocation> get _filteredBranches {
    if (_searchQuery.trim().isEmpty) return BranchService.branches;

    final query = _searchQuery.toLowerCase();
    return BranchService.branches.where((branch) {
      return branch.displayName.toLowerCase().contains(query) ||
          branch.region.toLowerCase().contains(query) ||
          branch.serviceNote.toLowerCase().contains(query);
    }).toList();
  }

  BranchDistance? get _nearestBranch {
    if (!_showNearestBranch) return null;
    return BranchService.nearestBranch(_currentPosition);
  }

  List<BranchDistance> get _branchDistances {
    final position = _currentPosition;
    if (!_showNearestBranch || position == null) return <BranchDistance>[];
    return BranchService.branchDistances(position);
  }

  Future<void> _copyDirections(BranchLocation branch) async {
    final url = BranchService.directionsUrl(branch, _currentPosition);
    await Clipboard.setData(ClipboardData(text: url));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Maps directions link copied.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearestBranch = _nearestBranch;

    return Scaffold(
      appBar: AppBar(title: const Text('Find Our Branch')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildMap(nearestBranch?.branch),
          ),
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSearchAndToggle(),
                const SizedBox(height: 12),
                if (_showNearestBranch) _buildNearestPanel(nearestBranch),
                if (_showNearestBranch) const SizedBox(height: 12),
                _buildBranchList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(BranchLocation? nearestBranch) {
    final currentPoint = _currentPosition == null
        ? null
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final visibleBranches = _filteredBranches;

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
            ...visibleBranches.map(
              (branch) {
                final isNearest = _showNearestBranch && nearestBranch == branch;

                return Marker(
                  point: branch.point,
                  width: 72,
                  height: 72,
                  child: Icon(
                    isNearest ? Icons.near_me : Icons.location_on,
                    color: isNearest ? Colors.green : Colors.red,
                    size: isNearest ? 42 : 36,
                  ),
                );
              },
            ),
            if (_showNearestBranch && currentPoint != null)
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

  Widget _buildSearchAndToggle() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search branch, region, or service...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show Nearest Branch'),
          subtitle: Text(
            _showNearestBranch
                ? 'GPS highlight is active'
                : 'Showing store locator map only',
          ),
          value: _showNearestBranch,
          onChanged: _isLoadingLocation ? null : _toggleNearestBranch,
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _statusMessage!,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNearestPanel(BranchDistance? nearestBranch) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.near_me),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nearest Branch',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (_isLoadingLocation)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingLocation)
            const Text('Reading your GPS location...')
          else if (nearestBranch == null)
            Text(
              _statusMessage ??
                  'Allow location access to highlight the closest branch.',
              style: TextStyle(color: Colors.grey.shade700),
            )
          else ...[
            Text(
              nearestBranch.branch.displayName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 6),
            Text(
                  '${BranchService.formatDistance(nearestBranch.distanceMeters)}'
                  ' away'
                  ' - about ${BranchService.estimateTravelTime(nearestBranch.distanceMeters)}',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _copyDirections(nearestBranch.branch),
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
              ),
            ),
          ],
          if (!_isLoadingLocation && nearestBranch == null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadCurrentLocation,
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Try GPS Again'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBranchList() {
    final branchDateTimes = BranchService.branchDateTimes();
    final formattedTimes = BranchService.branchTimes();
    final filteredBranches = _filteredBranches;
    final nearestBranch = _nearestBranch?.branch;

    if (filteredBranches.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No branches match your search.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'All Branches',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...filteredBranches.map((branch) {
          final localTime = branchDateTimes[branch.timezoneKey]!;
          final formattedTime = formattedTimes[branch.timezoneKey]!;
          final isOpen = BranchService.isBranchOpen(localTime);
          final distance = BranchService.distanceForBranch(
            _branchDistances,
            branch,
          );
          final isNearest = _showNearestBranch && branch == nearestBranch;

          return Card(
            elevation: isNearest ? 3 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isNearest ? Colors.green : Colors.transparent,
                width: isNearest ? 1.5 : 0,
              ),
            ),
            child: ListTile(
              onTap: () => _goToBranch(branch.point),
              leading: Icon(
                isNearest ? Icons.near_me : Icons.storefront,
                color: isNearest ? Colors.green : null,
              ),
              title: Text(branch.displayName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOpen
                        ? 'Open - Closes at 21:00'
                        : 'Closed - Opens at 09:00',
                    style: TextStyle(
                      color: isOpen ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(branch.serviceNote),
                  if (distance != null)
                    Text(
                      '${BranchService.formatDistance(distance.distanceMeters)}'
                      ' - about ${BranchService.estimateTravelTime(distance.distanceMeters)}',
                    ),
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
        }),
      ],
    );
  }
}
