import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double  latitude;
  final double  longitude;
  final String  eneo;
  final String  wilaya;
  final String  kata;
  final String  mkoa;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.eneo,
    required this.wilaya,
    required this.kata,
    required this.mkoa,
  });
}

class LocationService {
  static final LocationService _i = LocationService._();
  factory LocationService() => _i;
  LocationService._();

  // ── Get precise GPS position ──────────────────
  Future<LocationResult> getCurrentLocation() async {
    // Check & request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Ruhusa ya GPS imekataliwa.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Ruhusa ya GPS imezuiwa. Nenda Mipangilio kubadilisha.'
      );
    }

    // Check if GPS is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS imezimwa. Tafadhali iwashe.');
    }

    // Get high accuracy position with a shorter timeout or fallback
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      // Fallback to last known position if current is too slow or fails
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        position = lastKnown;
      } else {
        // Last resort: try lower accuracy
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      }
    }

    // Reverse geocode to get human-readable address
    final addressData = await _reverseGeocode(
      position.latitude,
      position.longitude,
    );

    return LocationResult(
      latitude:  position.latitude,
      longitude: position.longitude,
      eneo:      addressData['eneo']   ?? 'Mahali pasiojulikana',
      wilaya:    addressData['wilaya'] ?? 'Haijulikani',
      kata:      addressData['kata']   ?? 'Haijulikani',
      mkoa:      addressData['mkoa']   ?? 'Dar es Salaam',
    );
  }

  Future<Map<String, String>> _reverseGeocode(
      double lat, double lng,
      ) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isEmpty) return {};

      final p = placemarks.first;

    // Tanzania-specific address parsing
    String kata = p.subLocality ?? p.locality ?? p.subAdministrativeArea ?? 'Haijulikani';
    if (kata.toLowerCase().contains('dar es salaam')) {
        // If 'Dar es Salaam' is returned in subLocality, try to get more specific
        kata = p.name ?? p.street ?? 'Haijulikani';
    }

    String rawWilaya = p.locality ?? p.subAdministrativeArea ?? '';
    String mkoa = p.administrativeArea ?? 'Dar es Salaam';

    // Normalize Wilaya to match dsm_district enum ('Ilala', 'Kinondoni', 'Temeke', 'Ubungo', 'Kigamboni')
    String wilaya = 'Ubungo'; 
    
    // Combine all potential location strings to search for district keywords
    final String searchStr = [
      rawWilaya,
      p.subLocality,
      p.administrativeArea,
      p.street,
      p.name,
    ].join(' ').toLowerCase();

    if (searchStr.contains('ilala')) {
      wilaya = 'Ilala';
    } else if (searchStr.contains('kinondoni')) {
      wilaya = 'Kinondoni';
    } else if (searchStr.contains('temeke')) {
      wilaya = 'Temeke';
    } else if (searchStr.contains('ubungo')) {
      wilaya = 'Ubungo';
    } else if (searchStr.contains('kigamboni')) {
      wilaya = 'Kigamboni';
    } else if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) {
      // Use the raw sub-admin area if no keyword matches (more accurate than default Ubungo)
      wilaya = p.subAdministrativeArea!;
    }

    // Final cleanup for kata
    if (kata.length > 30) kata = kata.substring(0, 30); // Prevent overflow

    return {
      'eneo':   '${p.street ?? ''}, ${p.subLocality ?? ''}',
      'kata':   kata,
      'wilaya': wilaya,
      'mkoa':   mkoa,
    };
    } catch (_) {
      return {
        'eneo':   'Dar es Salaam',
        'kata':   'Haijulikani',
        'wilaya': 'Haijulikani',
        'mkoa':   'Dar es Salaam',
      };
    }
  }

  // ── Stream live position updates ──────────────
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}