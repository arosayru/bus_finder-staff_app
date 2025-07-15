import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class GpsService extends ChangeNotifier {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  bool _isGpsEnabled = false;
  bool _isInitialized = false;
  Position? _currentLocation;
  StreamSubscription<Position>? _positionSubscription;
  String? _errorMessage;

  // Getters
  bool get isGpsEnabled => _isGpsEnabled;
  bool get isInitialized => _isInitialized;
  Position? get currentLocation => _currentLocation;
  String? get errorMessage => _errorMessage;

  // Initialize GPS state from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isGpsEnabled = prefs.getBool('gps_enabled') ?? false;
      _isInitialized = true;

      // If GPS was enabled, start location tracking
      if (_isGpsEnabled) {
        await _startLocationTracking();
      }

      notifyListeners();
    } catch (e) {
      print('Error initializing GPS service: $e');
      _isGpsEnabled = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Toggle GPS state and save to SharedPreferences
  Future<void> toggleGps() async {
    _isGpsEnabled = !_isGpsEnabled;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gps_enabled', _isGpsEnabled);

      if (_isGpsEnabled) {
        await _startLocationTracking();
      } else {
        await _stopLocationTracking();
      }

      notifyListeners();
    } catch (e) {
      print('Error saving GPS state: $e');
      _errorMessage = 'Failed to toggle GPS: $e';
      notifyListeners();
    }
  }

  // Set GPS state directly
  Future<void> setGpsEnabled(bool enabled) async {
    if (_isGpsEnabled == enabled) return;

    _isGpsEnabled = enabled;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gps_enabled', _isGpsEnabled);

      if (_isGpsEnabled) {
        await _startLocationTracking();
      } else {
        await _stopLocationTracking();
      }

      notifyListeners();
    } catch (e) {
      print('Error saving GPS state: $e');
      _errorMessage = 'Failed to set GPS state: $e';
      notifyListeners();
    }
  }

  // Start location tracking
  Future<void> _startLocationTracking() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled.';
        notifyListeners();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permissions are denied.';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied.';
        notifyListeners();
        return;
      }

      // Get current position
      _currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Start listening to position changes
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
            (Position position) {
          _currentLocation = position;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Error getting location: $error';
          notifyListeners();
        },
      );

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to start location tracking: $e';
      notifyListeners();
    }
  }

  // Stop location tracking
  Future<void> _stopLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentLocation = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Get current location once (for one-time location requests)
  Future<Position?> getCurrentLocation() async {
    if (!_isGpsEnabled) {
      _errorMessage = 'GPS is disabled. Please enable GPS first.';
      notifyListeners();
      return null;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled.';
        notifyListeners();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permissions are denied.';
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied.';
        notifyListeners();
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLocation = position;
      _errorMessage = null;
      notifyListeners();
      return position;
    } catch (e) {
      _errorMessage = 'Failed to get current location: $e';
      notifyListeners();
      return null;
    }
  }

  // Clean up resources
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}