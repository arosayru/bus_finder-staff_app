import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GpsService extends ChangeNotifier {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  bool _isGpsEnabled = false;
  bool _isInitialized = false;

  bool get isGpsEnabled => _isGpsEnabled;
  bool get isInitialized => _isInitialized;

  // Initialize GPS state from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isGpsEnabled = prefs.getBool('gps_enabled') ?? false;
      _isInitialized = true;
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
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gps_enabled', _isGpsEnabled);
    } catch (e) {
      print('Error saving GPS state: $e');
    }
  }

  // Set GPS state directly
  Future<void> setGpsEnabled(bool enabled) async {
    if (_isGpsEnabled == enabled) return;

    _isGpsEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gps_enabled', _isGpsEnabled);
    } catch (e) {
      print('Error saving GPS state: $e');
    }
  }
}