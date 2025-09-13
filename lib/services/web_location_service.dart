import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class WebLocationService {
  static WebLocationService? _instance;

  WebLocationService._internal();

  factory WebLocationService() {
    _instance ??= WebLocationService._internal();
    return _instance!;
  }

  Future<WebLocationResult> getCurrentLocation() async {
    if (!kIsWeb) {
      return WebLocationResult(
        success: false,
        error: 'Web location service only works on web platform',
      );
    }

    try {
      // For now, return a mock location for testing
      // In a real implementation, you would use the browser's geolocation API
      // This is a temporary solution for testing the location-based features

      // Mock location - you can change these coordinates for testing
      return WebLocationResult(
        success: true,
        latitude: 17.385044, // Example coordinates - Hyderabad
        longitude: 78.486671,
      );
    } catch (e) {
      return WebLocationResult(
        success: false,
        error: 'Error getting location: $e',
      );
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double lat1Rad = lat1 * (math.pi / 180);
    final double lat2Rad = lat2 * (math.pi / 180);
    final double deltaLatRad = (lat2 - lat1) * (math.pi / 180);
    final double deltaLonRad = (lon2 - lon1) * (math.pi / 180);

    final double a =
        math.pow(math.sin(deltaLatRad / 2), 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.pow(math.sin(deltaLonRad / 2), 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Check if user is within specified radius of target location
  bool isWithinRadius(
    double currentLat,
    double currentLon,
    double targetLat,
    double targetLon,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(
      currentLat,
      currentLon,
      targetLat,
      targetLon,
    );
    return distance <= radiusInMeters;
  }
}

class WebLocationResult {
  final bool success;
  final double latitude;
  final double longitude;
  final String? error;

  WebLocationResult({
    required this.success,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.error,
  });
}
