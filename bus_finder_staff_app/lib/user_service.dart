import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _staffDataKey = 'staff_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save staff data after successful login
  static Future<void> saveStaffData(Map<String, dynamic> staffData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_staffDataKey, jsonEncode(staffData));
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get staff data
  static Future<Map<String, dynamic>?> getStaffData() async {
    final prefs = await SharedPreferences.getInstance();
    final staffDataString = prefs.getString(_staffDataKey);
    if (staffDataString != null) {
      return jsonDecode(staffDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get staff ID
  static Future<String?> getStaffId() async {
    final staffData = await getStaffData();
    return staffData?['StaffID'] ?? staffData?['staffId'] ?? staffData?['staff_id'];
  }

  // Get staff name
  static Future<String?> getStaffName() async {
    final staffData = await getStaffData();
    return staffData?['Name'] ?? staffData?['name'] ?? staffData?['fullName'];
  }

  // Get staff email
  static Future<String?> getStaffEmail() async {
    final staffData = await getStaffData();
    return staffData?['Email'] ?? staffData?['email'];
  }

  // Clear all stored data (logout)
  static Future<void> clearStaffData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_staffDataKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
}