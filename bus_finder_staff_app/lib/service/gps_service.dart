import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../user_service.dart';
import '../map_service.dart';

class GpsService extends ChangeNotifier {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  bool _isGpsEnabled = false;
  bool _isInitialized = false;
  Position? _currentLocation;
  StreamSubscription<Position>? _positionSubscription;
  String? _errorMessage;
  String? _targetBusNumberPlate;
  Timer? _locationUpdateTimer;

  // Getters
  bool get isGpsEnabled => _isGpsEnabled;
  bool get isInitialized => _isInitialized;
  Position? get currentLocation => _currentLocation;
  String? get errorMessage => _errorMessage;
  String? get targetBusNumberPlate => _targetBusNumberPlate;

  // Initialize GPS state from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isGpsEnabled = prefs.getBool('gps_enabled') ?? false;
      _isInitialized = true;

      // Get bus number plate for location sharing
      await _setTargetBusNumberPlate();

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

  // Get bus number plate for the logged-in staff
  Future<void> _setTargetBusNumberPlate() async {
    try {
      final email = await UserService.getStaffEmail();
      if (email == null) return;

      final staffId = await MapService.getStaffIdByEmail(email);
      if (staffId == null) return;

      final busDetails = await MapService.getBusDetailsByStaffId(staffId);
      if (busDetails == null) return;

      _targetBusNumberPlate = busDetails['numberPlate'];
      print('[GPS Service] Bus number plate set to: $_targetBusNumberPlate');
    } catch (e) {
      print('[GPS Service] Error getting bus number plate: $e');
    }
  }

  // Method to check if GPS is working properly
  Future<bool> checkGpsStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled on this device.';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are required to share your location.';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error checking GPS status: $e';
      notifyListeners();
      return false;
    }
  }

  // Method to force location update (useful for testing)
  Future<void> forceLocationUpdate() async {
    if (!_isGpsEnabled) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLocation = position;
      await _sendLocationUpdate(position.latitude, position.longitude);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get location: $e';
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
        // Send stop signal to backend when GPS is disabled
        await _sendStopLocationSignal();
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
        // Send stop signal to backend when GPS is disabled
        await _sendStopLocationSignal();
      }

      notifyListeners();
    } catch (e) {
      print('Error saving GPS state: $e');
      _errorMessage = 'Failed to set GPS state: $e';
      notifyListeners();
    }
  }

  // Start location tracking and sharing
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

      // Get current position and send it immediately
      _currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentLocation != null) {
        await _sendLocationUpdate(_currentLocation!.latitude, _currentLocation!.longitude);
      }

      // Start listening to position changes
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20, // Update every 20 meters
          timeLimit: Duration(seconds: 30),
        ),
      ).listen(
            (Position position) {
          _currentLocation = position;
          _errorMessage = null;
          // Send location update to backend
          _sendLocationUpdate(position.latitude, position.longitude);
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Error getting location: $error';
          notifyListeners();
        },
      );

      // Also send periodic updates (every 15 seconds)
      _locationUpdateTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
        if (_currentLocation != null) {
          await _sendLocationUpdate(_currentLocation!.latitude, _currentLocation!.longitude);
        }
      });

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
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _currentLocation = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Enhanced location update method with better error handling
  Future<void> _sendLocationUpdate(double latitude, double longitude) async {
    if (_targetBusNumberPlate == null || _targetBusNumberPlate!.isEmpty) {
      print('[GPS Service] Bus number plate not available');
      return;
    }

    final baseUrl = 'https://bus-finder-sl-a7c6a549fbb1.herokuapp.com';
    final encodedNumberPlate = Uri.encodeComponent(_targetBusNumberPlate!);
    final url = Uri.parse('$baseUrl/api/Bus/$encodedNumberPlate/location');

    final payload = {
      'currentLocationLatitude': latitude,
      'currentLocationLongitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      print('[GPS Service] Sending location update: $payload');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('[GPS Service] Location update successful - Status: ${response.statusCode}');
        _errorMessage = null; // Clear any previous errors
      } else {
        print('[GPS Service] Location update failed - Status: ${response.statusCode}, Body: ${response.body}');
        _errorMessage = 'Failed to update location on server';
      }
    } on TimeoutException catch (e) {
      print('[GPS Service] Location update timeout: $e');
      _errorMessage = 'Location update timed out';
    } on SocketException catch (e) {
      print('[GPS Service] Network error: $e');
      _errorMessage = 'Network connection failed';
    } catch (e) {
      print('[GPS Service] Location update error: $e');
      _errorMessage = 'Location update failed: $e';
    }

    notifyListeners();
  }

  // Enhanced stop signal method - now sends -1, -1 coordinates
  Future<void> _sendStopLocationSignal() async {
    if (_targetBusNumberPlate == null || _targetBusNumberPlate!.isEmpty) {
      print('[GPS Service] Bus number plate not available for stop signal');
      return;
    }

    final baseUrl = 'https://bus-finder-sl-a7c6a549fbb1.herokuapp.com';
    final encodedNumberPlate = Uri.encodeComponent(_targetBusNumberPlate!);
    final url = Uri.parse('$baseUrl/api/Bus/$encodedNumberPlate/location');

    final payload = {
      'currentLocationLatitude': -1,
      'currentLocationLongitude': -1,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      print('[GPS Service] Sending GPS disable signal with coordinates -1, -1 for bus: $_targetBusNumberPlate');
      print('[GPS Service] Payload: $payload');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('[GPS Service] GPS disable signal sent successfully - Status: ${response.statusCode}');
      } else {
        print('[GPS Service] GPS disable signal failed - Status: ${response.statusCode}, Body: ${response.body}');
      }
    } on TimeoutException catch (e) {
      print('[GPS Service] Stop signal timeout: $e');
    } on SocketException catch (e) {
      print('[GPS Service] Network error: $e');
    } catch (e) {
      print('[GPS Service] Stop signal error: $e');
    }
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

  // Method to get location sharing status summary
  String getLocationSharingStatus() {
    if (!_isInitialized) return 'GPS service not initialized';
    if (!_isGpsEnabled) return 'GPS disabled';
    if (_targetBusNumberPlate == null) return 'Bus not assigned';
    if (_currentLocation == null) return 'Getting location...';
    if (_errorMessage != null) return 'Error: $_errorMessage';
    return 'Sharing location for $_targetBusNumberPlate';
  }

  // Clean up resources
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}
