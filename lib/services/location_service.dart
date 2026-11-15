import 'package:geolocator/geolocator.dart';

/// Result of a location attempt, with a graceful fallback.
class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? error;

  const LocationResult({this.latitude, this.longitude, this.error});

  bool get hasPosition => latitude != null && longitude != null;
}

class LocationService {
  /// Returns the current position, or an error message when location
  /// is unavailable / permission is denied. Never throws.
  static Future<LocationResult> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          error: 'Location services are switched off on this device.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          error: 'Location permission denied.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          error:
              'Location permission is permanently denied. Enable it in app settings to record GPS.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return LocationResult(error: 'Could not get location: $e');
    }
  }
}
