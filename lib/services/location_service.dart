import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_location_service.dart';

class LocationService {
  static const double LOCATION_RADIUS_METERS = 50.0;

  // Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    return await Permission.locationWhenInUse.isGranted;
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status == PermissionStatus.granted;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // For web platform, use web-specific location service
      if (kIsWeb) {
        final webService = WebLocationService();
        final result = await webService.getCurrentLocation();

        if (result.success) {
          // Create a Position-like object for web
          return Position(
            latitude: result.latitude,
            longitude: result.longitude,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
        } else {
          throw Exception(result.error ?? 'Failed to get location');
        }
      } else {
        // For mobile platforms, check services first
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled');
        }

        // Check permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permissions are denied');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied');
        }

        // Get current position
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Calculate distance between two coordinates
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    if (kIsWeb) {
      final webService = WebLocationService();
      return webService.calculateDistance(lat1, lon1, lat2, lon2);
    } else {
      return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    }
  }

  // Check if current location is within radius of target location
  Future<LocationVerificationResult> verifyLocationProximity({
    required double targetLatitude,
    required double targetLongitude,
    double radiusMeters = LOCATION_RADIUS_METERS,
  }) async {
    try {
      final currentPosition = await getCurrentLocation();
      if (currentPosition == null) {
        return LocationVerificationResult(
          isValid: false,
          distance: null,
          errorMessage: 'Unable to get current location',
        );
      }

      final distance = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLatitude,
        targetLongitude,
      );

      final isWithinRadius = distance <= radiusMeters;

      return LocationVerificationResult(
        isValid: isWithinRadius,
        distance: distance,
        currentLatitude: currentPosition.latitude,
        currentLongitude: currentPosition.longitude,
        targetLatitude: targetLatitude,
        targetLongitude: targetLongitude,
        errorMessage: isWithinRadius
            ? null
            : 'You are ${distance.toStringAsFixed(0)} meters away from the customer location. You must be within ${radiusMeters.toStringAsFixed(0)} meters to proceed.',
      );
    } catch (e) {
      return LocationVerificationResult(
        isValid: false,
        distance: null,
        errorMessage: 'Location verification failed: $e',
      );
    }
  }

  // Get location verification result with detailed information
  Future<LocationVerificationResult> getLocationVerificationResult({
    required double targetLatitude,
    required double targetLongitude,
    double radiusMeters = LOCATION_RADIUS_METERS,
  }) async {
    return await verifyLocationProximity(
      targetLatitude: targetLatitude,
      targetLongitude: targetLongitude,
      radiusMeters: radiusMeters,
    );
  }
}

class LocationVerificationResult {
  final bool isValid;
  final double? distance;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? targetLatitude;
  final double? targetLongitude;
  final String? errorMessage;

  LocationVerificationResult({
    required this.isValid,
    this.distance,
    this.currentLatitude,
    this.currentLongitude,
    this.targetLatitude,
    this.targetLongitude,
    this.errorMessage,
  });

  String get distanceDisplay {
    if (distance == null) return 'Unknown';
    if (distance! < 1000) {
      return '${distance!.toStringAsFixed(0)} meters';
    } else {
      return '${(distance! / 1000).toStringAsFixed(1)} km';
    }
  }

  String get statusMessage {
    if (isValid) {
      return 'Location verified: You are ${distanceDisplay} from the customer location';
    } else {
      return errorMessage ?? 'Location verification failed';
    }
  }
}
