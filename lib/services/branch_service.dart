import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class BranchLocation {
  const BranchLocation({
    required this.name,
    required this.displayName,
    required this.region,
    required this.timezoneKey,
    required this.point,
    required this.serviceNote,
  });

  final String name;
  final String displayName;
  final String region;
  final String timezoneKey;
  final LatLng point;
  final String serviceNote;
}

class BranchDistance {
  const BranchDistance({
    required this.branch,
    required this.distanceMeters,
  });

  final BranchLocation branch;
  final double distanceMeters;
}

class BranchLocationException implements Exception {
  const BranchLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BranchService {
  const BranchService._();

  static const List<BranchLocation> branches = [
    BranchLocation(
      name: 'Banda Aceh Studio',
      displayName: 'Banda Aceh Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(5.5483, 95.3238),
      serviceNote: 'Custom campus tees and regional pickup.',
    ),
    BranchLocation(
      name: 'Medan Studio',
      displayName: 'Medan Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(3.5952, 98.6722),
      serviceNote: 'Bulk shirt orders and same-city pickup.',
    ),
    BranchLocation(
      name: 'Padang Studio',
      displayName: 'Padang Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-0.9471, 100.4172),
      serviceNote: 'Event merch and cotton print stock.',
    ),
    BranchLocation(
      name: 'Pekanbaru Studio',
      displayName: 'Pekanbaru Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(0.5071, 101.4478),
      serviceNote: 'Fast pickup for community orders.',
    ),
    BranchLocation(
      name: 'Batam Studio',
      displayName: 'Batam Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(1.1301, 104.0529),
      serviceNote: 'Island delivery coordination and pickup.',
    ),
    BranchLocation(
      name: 'Palembang Studio',
      displayName: 'Palembang Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-2.9761, 104.7754),
      serviceNote: 'Team shirts and local fulfillment.',
    ),
    BranchLocation(
      name: 'Bandar Lampung Studio',
      displayName: 'Bandar Lampung Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-5.3971, 105.2668),
      serviceNote: 'Student merch and custom pickup.',
    ),
    BranchLocation(
      name: 'Jakarta Flagship',
      displayName: 'Jakarta Flagship (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-6.2088, 106.8456),
      serviceNote: 'Same-day pickup and shirt fitting.',
    ),
    BranchLocation(
      name: 'Bandung Studio',
      displayName: 'Bandung Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-6.9175, 107.6191),
      serviceNote: 'Creative apparel consultation.',
    ),
    BranchLocation(
      name: 'Semarang Studio',
      displayName: 'Semarang Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-6.9667, 110.4167),
      serviceNote: 'Central Java order pickup hub.',
    ),
    BranchLocation(
      name: 'Surakarta Studio',
      displayName: 'Surakarta Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-7.5755, 110.8243),
      serviceNote: 'Batik-inspired shirt design help.',
    ),
    BranchLocation(
      name: 'UPN Veteran Yogyakarta Studio',
      displayName: 'UPN Veteran Yogyakarta Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-7.762232, 110.409279),
      serviceNote: 'Campus pickup at UPN Veteran Yogyakarta.',
    ),
    BranchLocation(
      name: 'Surabaya Studio',
      displayName: 'Surabaya Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-7.2575, 112.7521),
      serviceNote: 'East Java production and pickup hub.',
    ),
    BranchLocation(
      name: 'Malang Studio',
      displayName: 'Malang Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-7.9666, 112.6326),
      serviceNote: 'Campus organizations and event shirts.',
    ),
    BranchLocation(
      name: 'Denpasar Studio',
      displayName: 'Denpasar Studio (WITA)',
      region: 'WITA',
      timezoneKey: 'WITA',
      point: LatLng(-8.6705, 115.2126),
      serviceNote: 'Tour merch and lightweight cotton stock.',
    ),
    BranchLocation(
      name: 'Mataram Studio',
      displayName: 'Mataram Studio (WITA)',
      region: 'WITA',
      timezoneKey: 'WITA',
      point: LatLng(-8.5833, 116.1167),
      serviceNote: 'Lombok pickup and custom beachwear tees.',
    ),
    BranchLocation(
      name: 'Kupang Studio',
      displayName: 'Kupang Studio (WITA)',
      region: 'WITA',
      timezoneKey: 'WITA',
      point: LatLng(-10.1772, 123.6070),
      serviceNote: 'Nusa Tenggara pickup coordination.',
    ),
    BranchLocation(
      name: 'Pontianak Studio',
      displayName: 'Pontianak Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-0.0263, 109.3425),
      serviceNote: 'Kalimantan Barat pickup hub.',
    ),
    BranchLocation(
      name: 'Banjarmasin Studio',
      displayName: 'Banjarmasin Studio (WITA)',
      region: 'WITA',
      timezoneKey: 'WITA',
      point: LatLng(-3.3186, 114.5944),
      serviceNote: 'River city fulfillment and pickup.',
    ),
    BranchLocation(
      name: 'Balikpapan Studio',
      displayName: 'Balikpapan Studio (WITA)',
      region: 'WITA',
      timezoneKey: 'WITA',
      point: LatLng(-1.2379, 116.8529),
      serviceNote: 'Workwear tees and corporate pickup.',
    ),
    BranchLocation(
      name: 'Samarinda Studio',
      displayName: 'Samarinda Studio (WITA)',
      region: 'WITA',
      timezoneKey: 'WITA',
      point: LatLng(-0.5022, 117.1536),
      serviceNote: 'East Kalimantan local order point.',
    ),
    BranchLocation(
      name: 'Palangka Raya Studio',
      displayName: 'Palangka Raya Studio (WIB)',
      region: 'WIB',
      timezoneKey: 'WIB',
      point: LatLng(-2.2161, 113.9137),
      serviceNote: 'Central Kalimantan pickup service.',
    ),
    BranchLocation(
      name: 'Makassar Studio',
      displayName: 'Makassar Studio (WITA)',
      region: 'WITA',
      timezoneKey: 'WITA',
      point: LatLng(-5.1477, 119.4327),
      serviceNote: 'Sulawesi production coordination.',
    ),
    BranchLocation(
      name: 'Manado Studio',
      displayName: 'Manado Studio (WITA)',
      region: 'WITA',
      timezoneKey: 'WITA',
      point: LatLng(1.4748, 124.8421),
      serviceNote: 'North Sulawesi pickup and event merch.',
    ),
    BranchLocation(
      name: 'Palu Studio',
      displayName: 'Palu Studio (WITA)',
      region: 'WITA',
      timezoneKey: 'WITA',
      point: LatLng(-0.9003, 119.8780),
      serviceNote: 'Community shirt pickup point.',
    ),
    BranchLocation(
      name: 'Kendari Studio',
      displayName: 'Kendari Studio (WITA)',
      region: 'WITA',
      timezoneKey: 'WITA',
      point: LatLng(-3.9985, 122.5120),
      serviceNote: 'Southeast Sulawesi order pickup.',
    ),
    BranchLocation(
      name: 'Ambon Studio',
      displayName: 'Ambon Studio (WIT)',
      region: 'WIT',
      timezoneKey: 'WIT',
      point: LatLng(-3.6954, 128.1814),
      serviceNote: 'Maluku pickup and island delivery support.',
    ),
    BranchLocation(
      name: 'Ternate Studio',
      displayName: 'Ternate Studio (WIT)',
      region: 'WIT',
      timezoneKey: 'WIT',
      point: LatLng(0.7893, 127.3639),
      serviceNote: 'North Maluku pickup point.',
    ),
    BranchLocation(
      name: 'Sorong Studio',
      displayName: 'Sorong Studio (WIT)',
      region: 'WIT',
      timezoneKey: 'WIT',
      point: LatLng(-0.8762, 131.2558),
      serviceNote: 'West Papua pickup and remote order support.',
    ),
    BranchLocation(
      name: 'Jayapura Studio',
      displayName: 'Jayapura Studio (WIT)',
      region: 'WIT',
      timezoneKey: 'WIT',
      point: LatLng(-2.5337, 140.7181),
      serviceNote: 'Papua pickup and local delivery support.',
    ),
  ];

  static Future<Position> requestCurrentPosition() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw const BranchLocationException(
        'Location service is disabled on this device.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const BranchLocationException(
        'Location permission was denied. Showing all branches instead.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  static List<BranchDistance> branchDistances(Position position) {
    final distances = branches.map((branch) {
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        branch.point.latitude,
        branch.point.longitude,
      );

      return BranchDistance(
        branch: branch,
        distanceMeters: distanceMeters,
      );
    }).toList();

    distances.sort(
      (first, second) => first.distanceMeters.compareTo(second.distanceMeters),
    );
    return distances;
  }

  static BranchDistance? nearestBranch(Position? position) {
    if (position == null) return null;
    final distances = branchDistances(position);
    return distances.isEmpty ? null : distances.first;
  }

  static BranchDistance? distanceForBranch(
    List<BranchDistance> distances,
    BranchLocation branch,
  ) {
    for (final distance in distances) {
      if (distance.branch == branch) return distance;
    }

    return null;
  }

  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String estimateTravelTime(double meters) {
    const averageMetersPerMinute = 500;
    final minutes = (meters / averageMetersPerMinute).ceil();
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours hr';
    return '$hours hr $remainingMinutes min';
  }

  static Map<String, DateTime> branchDateTimes() {
    final nowUtc = DateTime.now().toUtc();
    return {
      'WIB': nowUtc.add(const Duration(hours: 7)),
      'WITA': nowUtc.add(const Duration(hours: 8)),
      'WIT': nowUtc.add(const Duration(hours: 9)),
    };
  }

  static Map<String, String> branchTimes() {
    String formatTime(DateTime dt) {
      final hours = dt.hour.toString().padLeft(2, '0');
      final minutes = dt.minute.toString().padLeft(2, '0');
      return '$hours:$minutes';
    }

    return branchDateTimes().map(
      (key, value) => MapEntry(key, formatTime(value)),
    );
  }

  static bool isBranchOpen(DateTime localBranchTime) {
    return localBranchTime.hour >= 9 && localBranchTime.hour < 21;
  }

  static String directionsUrl(BranchLocation branch, Position? position) {
    final destination = '${branch.point.latitude},${branch.point.longitude}';

    if (position == null) {
      return 'https://www.google.com/maps/dir/?api=1&destination=$destination';
    }

    final origin = '${position.latitude},${position.longitude}';
    return 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination';
  }
}
