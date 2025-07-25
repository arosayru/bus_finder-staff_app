import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../user_service.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  bool _isSOSActive = false;
  bool _isLoading = false;
  bool _isLoadingBusDetails = true; // Loading state for initial bus details
  Timer? _sosTimer;
  String? _cachedNumberPlate; // Cache the number plate
  String? _errorMessage; // Error message if loading fails

  static const String baseUrl = "https://bus-finder-sl-a7c6a549fbb1.herokuapp.com";

  @override
  void initState() {
    super.initState();
    _loadBusDetails(); // Load bus details when screen initializes
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    super.dispose();
  }

  // Load bus details using the same logic as MapService
  Future<void> _loadBusDetails() async {
    setState(() {
      _isLoadingBusDetails = true;
      _errorMessage = null;
    });

    try {
      print('=== LOADING BUS DETAILS ===');

      // Get staff email - you'll need to implement getUserEmail() or use UserService
      final email = await _getUserEmail();
      print('DEBUG: Retrieved staff email: $email');

      if (email == null || email.isEmpty || email == 'N/A') {
        print('DEBUG: No staff email found');
        setState(() {
          _isLoadingBusDetails = false;
          _errorMessage = 'Unable to retrieve staff information';
        });
        return;
      }

      // Get staff ID by email
      final staffId = await _getStaffIdByEmail(email);
      print('DEBUG: Retrieved staff ID: $staffId');

      if (staffId == null || staffId.isEmpty) {
        print('DEBUG: Failed to get staff ID for email: $email');
        setState(() {
          _isLoadingBusDetails = false;
          _errorMessage = 'Unable to retrieve staff details';
        });
        return;
      }

      // Get bus details by staff ID
      final busDetails = await _getBusDetailsByStaffId(staffId);
      print('DEBUG: Retrieved bus details: $busDetails');

      if (busDetails != null && busDetails['numberPlate'] != null) {
        setState(() {
          _cachedNumberPlate = busDetails['numberPlate'];
          _isLoadingBusDetails = false;
          _errorMessage = null;
        });
        print('DEBUG: ✅ Successfully cached number plate: $_cachedNumberPlate');
        print('DEBUG: Number plate is ready for SOS functionality');
      } else {
        print('DEBUG: ❌ Failed to get number plate from bus details');
        setState(() {
          _isLoadingBusDetails = false;
          _errorMessage = 'Unable to retrieve bus information';
        });
      }
    } catch (e) {
      print('DEBUG: ❌ Error loading bus details: $e');
      setState(() {
        _isLoadingBusDetails = false;
        _errorMessage = 'Error loading bus details. Please try again.';
      });
    }
  }

  // Get user email - implement this based on how you store user data
  Future<String?> _getUserEmail() async {
    try {
      // Get staff data from UserService
      final staffData = await UserService.getStaffData();

      if (staffData != null && staffData['Email'] != null) {
        final email = staffData['Email'].toString();
        print('DEBUG: Retrieved email from UserService: $email');
        return email;
      } else {
        print('DEBUG: No staff data or email found in UserService');
        return null;
      }
    } catch (e) {
      print('DEBUG: Error retrieving email from UserService: $e');
      return null;
    }
  }

  // Get staff ID by email (copied from MapService logic)
  Future<String?> _getStaffIdByEmail(String email) async {
    try {
      final idUrl = Uri.parse('$baseUrl/api/Staff/get-id-by-email/$email');
      print('DEBUG: Getting staff ID from: $idUrl');

      final idResponse = await http.get(idUrl);
      print('DEBUG: Staff ID response status: ${idResponse.statusCode}');
      print('DEBUG: Staff ID response body: ${idResponse.body}');

      if (idResponse.statusCode == 200) {
        final idData = jsonDecode(idResponse.body);
        final staffId = idData['staffId']?.toString() ?? idData['StaffID']?.toString();
        print('DEBUG: Extracted staff ID: $staffId');
        return staffId;
      }
      return null;
    } catch (e) {
      print('Error getting staff ID by email: $e');
      return null;
    }
  }

  // Get bus details by staff ID (copied from MapService logic)
  Future<Map<String, String>?> _getBusDetailsByStaffId(String staffId) async {
    try {
      final busUrl = Uri.parse('$baseUrl/api/Bus/by-staff/$staffId');
      print('DEBUG: Fetching bus details from: $busUrl');

      final busResponse = await http.get(busUrl);
      print('DEBUG: Bus details response status: ${busResponse.statusCode}');
      print('DEBUG: Bus details response body: ${busResponse.body}');

      if (busResponse.statusCode == 200) {
        final responseData = jsonDecode(busResponse.body);
        print('DEBUG: Parsed response data: $responseData');

        // Handle both array and single object responses
        List<dynamic> busList;
        if (responseData is List) {
          busList = responseData;
        } else {
          busList = [responseData];
        }

        print('DEBUG: Bus list length: ${busList.length}');

        if (busList.isNotEmpty) {
          // Use the first bus in the list
          final busData = busList[0];
          print('DEBUG: Using first bus data: $busData');

          // Handle different possible field names
          String? numberPlate = busData['numberPlate']?.toString() ??
              busData['NumberPlate']?.toString() ??
              busData['number_plate']?.toString();

          String? busRouteNumber = busData['busRouteNumber']?.toString() ??
              busData['BusRouteNumber']?.toString() ??
              busData['bus_route_number']?.toString();

          print('DEBUG: Extracted numberPlate: $numberPlate');
          print('DEBUG: Extracted busRouteNumber: $busRouteNumber');

          if (numberPlate != null && busRouteNumber != null) {
            return {
              'numberPlate': numberPlate,
              'busRouteNumber': busRouteNumber,
            };
          } else {
            print('DEBUG: ❌ numberPlate or busRouteNumber is null');
          }
        } else {
          print('DEBUG: ❌ Bus list is empty');
        }
      } else {
        print('DEBUG: ❌ Bus details API call failed with status: ${busResponse.statusCode}');
      }
      return null;
    } catch (e) {
      print('Error getting bus details by staff ID: $e');
      return null;
    }
  }

  Future<void> _handleSOSPress() async {
    print('\n=== SOS BUTTON PRESSED ===');

    if (_isLoading) {
      print('DEBUG: SOS request already in progress, ignoring press');
      return;
    }

    // Check if number plate is available
    if (_cachedNumberPlate == null || _cachedNumberPlate!.isEmpty) {
      print('DEBUG: ❌ No number plate available for SOS request');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Bus information not loaded. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    print('DEBUG: ✅ Number plate available: $_cachedNumberPlate');

    setState(() {
      _isLoading = true;
    });

    try {
      // Toggle SOS status
      bool newSOSStatus = !_isSOSActive;

      // Debug logs
      print('=== SOS API DEBUG ===');
      print('DEBUG: Current SOS Status: $_isSOSActive');
      print('DEBUG: New SOS Status: $newSOSStatus');
      print('DEBUG: Using Number Plate: $_cachedNumberPlate');
      print('DEBUG: Full URL: $baseUrl/api/Bus/$_cachedNumberPlate/sos-status');

      final uri = Uri.parse('$baseUrl/api/Bus/$_cachedNumberPlate/sos-status');
      print('DEBUG: Parsed URI: $uri');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      print('DEBUG: Headers: $headers');

      // FIXED: Use 'sosStatus' instead of 'request' to match backend API
      final requestBody = json.encode({
        'sosStatus': newSOSStatus,
      });
      print('DEBUG: Request Body: $requestBody');

      print('DEBUG: Making HTTP PUT request...');

      final response = await http.put(
        uri,
        headers: headers,
        body: requestBody,
      ).timeout(const Duration(seconds: 10));

      print('DEBUG: Response Status Code: ${response.statusCode}');
      print('DEBUG: Response Headers: ${response.headers}');
      print('DEBUG: Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('DEBUG: ✅ SOS API call successful');
        setState(() {
          _isSOSActive = newSOSStatus;
          _isLoading = false;
        });

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSOSActive
                  ? 'SOS Alert Activated for bus $_cachedNumberPlate!'
                  : 'SOS Alert Deactivated for bus $_cachedNumberPlate!',
            ),
            backgroundColor: _isSOSActive ? Colors.red : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // If SOS is activated, set timer to auto-deactivate after 20 seconds
        if (_isSOSActive) {
          print('DEBUG: Starting 20-second auto-deactivate timer');
          _startSOSTimer();
        } else {
          print('DEBUG: Cancelling auto-deactivate timer');
          _sosTimer?.cancel();
        }

      } else {
        print('DEBUG: ❌ SOS API call failed with status: ${response.statusCode}');
        print('DEBUG: Error response body: ${response.body}');

        // Try to parse error message from response
        String errorMessage = 'Failed to update SOS status (${response.statusCode})';
        try {
          final errorData = json.decode(response.body);
          if (errorData['title'] != null) {
            errorMessage = errorData['title'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          print('DEBUG: Could not parse error response: $e');
        }

        throw Exception(errorMessage);
      }

    } on TimeoutException catch (e) {
      print('DEBUG: ❌ SOS API timeout: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timeout. Please check your internet connection.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      print('DEBUG: ❌ SOS API error: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _startSOSTimer() {
    _sosTimer?.cancel();
    _sosTimer = Timer(const Duration(seconds: 20), () {
      if (_isSOSActive) {
        print('DEBUG: ⏰ 20 seconds elapsed, auto-deactivating SOS');
        _deactivateSOSAutomatically();
      }
    });
  }

  Future<void> _deactivateSOSAutomatically() async {
    if (_cachedNumberPlate == null) {
      print('DEBUG: ❌ Cannot auto-deactivate: No number plate available');
      return;
    }

    print('=== AUTO-DEACTIVATE SOS DEBUG ===');
    print('DEBUG: Auto-deactivating SOS for bus: $_cachedNumberPlate');

    try {
      final uri = Uri.parse('$baseUrl/api/Bus/$_cachedNumberPlate/sos-status');
      print('DEBUG: Auto-deactivate URL: $uri');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // FIXED: Use 'sosStatus' instead of 'request' for auto-deactivate too
      final requestBody = json.encode({
        'sosStatus': false,
      });
      print('DEBUG: Auto-deactivate Request Body: $requestBody');

      final response = await http.put(
        uri,
        headers: headers,
        body: requestBody,
      ).timeout(const Duration(seconds: 10));

      print('DEBUG: Auto-deactivate Response Status: ${response.statusCode}');
      print('DEBUG: Auto-deactivate Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('DEBUG: ✅ Auto-deactivate successful');
        setState(() {
          _isSOSActive = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SOS Alert for $_cachedNumberPlate automatically deactivated after 20 seconds'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('DEBUG: ❌ Auto-deactivate failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: ❌ Auto-deactivate error: $e');
    }
  }

  // Retry loading bus details
  void _retryLoadBusDetails() {
    _loadBusDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
            width: double.infinity,
            color: const Color(0xFFFB9933),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Report Issue",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),

          // Loading State
          if (_isLoadingBusDetails)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFB9933)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Loading bus details...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Please wait while we prepare the SOS system',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )

          // Error State
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Unable to Load Bus Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _retryLoadBusDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFB9933),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )

          // Main SOS Content (when data is loaded)
          else
            Expanded(
              child: Column(
                children: [
                  const Spacer(),

                  // SOS Button
                  Center(
                    child: GestureDetector(
                      onTap: _isLoading ? null : _handleSOSPress,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: _isSOSActive
                              ? const Color(0xFF8B0000) // Darker red when active
                              : const Color(0xFFBD2D01), // Original red
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: _isSOSActive ? 20 : 15,
                              offset: const Offset(4, 6),
                            ),
                            BoxShadow(
                              color: _isSOSActive
                                  ? const Color(0xFF5A5A5A)
                                  : const Color(0xFF7E7573),
                              blurRadius: _isSOSActive ? 12 : 8,
                              offset: const Offset(-4, -4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "SOS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _isSOSActive ? 36 : 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            if (_isSOSActive) ...[
                              const SizedBox(height: 8),
                              const Text(
                                "ACTIVE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status text
                  if (_isSOSActive && _cachedNumberPlate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "SOS Alert is ACTIVE for bus $_cachedNumberPlate\nWill auto-deactivate in 20 seconds",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
        ],
      ),

      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black26, offset: Offset(0, -5), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          IconData icon;
          switch (index) {
            case 0:
              icon = Icons.home;
              break;
            case 1:
              icon = Icons.location_on_outlined;
              break;
            case 2:
              icon = Icons.notifications_none;
              break;
            case 3:
              icon = Icons.grid_view;
              break;
            default:
              icon = Icons.help_outline;
          }

          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
              } else if (index == 1) {
                Navigator.pushNamedAndRemoveUntil(context, 'live-map', (route) => false);
              } else if (index == 2) {
                Navigator.pushNamedAndRemoveUntil(context, 'notification', (route) => false);
              } else if (index == 3) {
                Navigator.pushNamedAndRemoveUntil(context, 'more', (route) => false);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4)),
                ],
              ),
              child: Icon(icon, color: const Color(0xFFCF4602)),
            ),
          );
        }),
      ),
    );
  }
}