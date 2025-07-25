import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../user_service.dart';

class BusCapacityScreen extends StatefulWidget {
  const BusCapacityScreen({super.key});

  @override
  State<BusCapacityScreen> createState() => _BusCapacityScreenState();
}

class _BusCapacityScreenState extends State<BusCapacityScreen> {
  bool? _hasAvailableSeats; // null = not set, true = available, false = full
  bool _isLoadingAvailable = false; // Separate loading state for available button
  bool _isLoadingFull = false; // Separate loading state for full button
  bool _isLoadingBusDetails = true; // Loading state for initial bus details
  String? _cachedNumberPlate; // Cache the number plate
  String? _errorMessage; // Error message if loading fails

  static const String baseUrl = "https://bus-finder-sl-a7c6a549fbb1.herokuapp.com";

  @override
  void initState() {
    super.initState();
    _loadBusDetails(); // Load bus details when screen initializes
  }

  // Load bus details using the same logic as SOS implementation
  Future<void> _loadBusDetails() async {
    setState(() {
      _isLoadingBusDetails = true;
      _errorMessage = null;
    });

    try {
      print('=== LOADING BUS DETAILS FOR CAPACITY ===');

      // Get staff email
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
        print('DEBUG: Number plate is ready for capacity functionality');

        // Load current capacity status
        await _loadCurrentCapacityStatus();
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

  // Load current capacity status from backend
  Future<void> _loadCurrentCapacityStatus() async {
    if (_cachedNumberPlate == null) return;

    try {
      print('=== LOADING CURRENT CAPACITY STATUS ===');
      final uri = Uri.parse('$baseUrl/api/Bus/$_cachedNumberPlate');
      print('DEBUG: Fetching current status from: $uri');

      final response = await http.get(uri);
      print('DEBUG: Capacity status response: ${response.statusCode}');
      print('DEBUG: Capacity status body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Try different possible field names for capacity
        bool? capacity = data['hasAvailableSeats'] ??
            data['HasAvailableSeats'] ??
            data['busCapacity'] ??
            data['BusCapacity'] ??
            data['capacity'] ??
            data['Capacity'];

        if (capacity != null) {
          setState(() {
            _hasAvailableSeats = capacity;
          });
          print('DEBUG: ✅ Current capacity status loaded: $capacity');
        }
      }
    } catch (e) {
      print('DEBUG: Error loading current capacity status: $e');
    }
  }

  // Get user email - same as SOS implementation
  Future<String?> _getUserEmail() async {
    try {
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

  // Get staff ID by email - same as SOS implementation
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

  // Get bus details by staff ID - same as SOS implementation
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
          final busData = busList[0];
          print('DEBUG: Using first bus data: $busData');

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

  // Handle capacity button press with separate loading states
  Future<void> _handleCapacityPress(bool hasAvailableSeats) async {
    print('\n=== CAPACITY BUTTON PRESSED ===');
    print('DEBUG: Setting capacity to: ${hasAvailableSeats ? "Available Seats" : "Fully Loaded"}');

    // Check which button was pressed and if it's already loading
    if (hasAvailableSeats && _isLoadingAvailable) {
      print('DEBUG: Available seats button already loading, ignoring press');
      return;
    }
    if (!hasAvailableSeats && _isLoadingFull) {
      print('DEBUG: Full button already loading, ignoring press');
      return;
    }

    // Check if number plate is available
    if (_cachedNumberPlate == null || _cachedNumberPlate!.isEmpty) {
      print('DEBUG: ❌ No number plate available for capacity request');
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

    // Set loading state for the specific button
    setState(() {
      if (hasAvailableSeats) {
        _isLoadingAvailable = true;
      } else {
        _isLoadingFull = true;
      }
    });

    try {
      // Debug logs
      print('=== CAPACITY API DEBUG ===');
      print('DEBUG: Current Capacity Status: $_hasAvailableSeats');
      print('DEBUG: New Capacity Status: $hasAvailableSeats');
      print('DEBUG: Using Number Plate: $_cachedNumberPlate');
      print('DEBUG: Full URL: $baseUrl/api/Bus/$_cachedNumberPlate/capacity');

      final uri = Uri.parse('$baseUrl/api/Bus/$_cachedNumberPlate/capacity');
      print('DEBUG: Parsed URI: $uri');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      print('DEBUG: Headers: $headers');

      // FIXED: Use 'busCapacity' to match the API example
      final requestBody = json.encode({
        'busCapacity': hasAvailableSeats,
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
        print('DEBUG: ✅ Capacity API call successful');
        setState(() {
          _hasAvailableSeats = hasAvailableSeats;
          _isLoadingAvailable = false;
          _isLoadingFull = false;
        });

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasAvailableSeats
                  ? 'Bus $_cachedNumberPlate marked as having available seats!'
                  : 'Bus $_cachedNumberPlate marked as fully loaded!',
            ),
            backgroundColor: hasAvailableSeats ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );

      } else {
        print('DEBUG: ❌ Capacity API call failed with status: ${response.statusCode}');
        print('DEBUG: Error response body: ${response.body}');

        // Try to parse error message from response
        String errorMessage = 'Failed to update capacity status (${response.statusCode})';
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
      print('DEBUG: ❌ Capacity API timeout: $e');
      setState(() {
        _isLoadingAvailable = false;
        _isLoadingFull = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timeout. Please check your internet connection.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      print('DEBUG: ❌ Capacity API error: $e');
      setState(() {
        _isLoadingAvailable = false;
        _isLoadingFull = false;
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
                  "Bus Capacity",
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
                      'Please wait while we fetch your bus information',
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

          // Main Content (when data is loaded)
          else
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Current Status Display
                  if (_hasAvailableSeats != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: _hasAvailableSeats! ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasAvailableSeats! ? Colors.green.shade200 : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasAvailableSeats! ? Icons.event_seat : Icons.airline_seat_individual_suite,
                            color: _hasAvailableSeats! ? Colors.green.shade700 : Colors.orange.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Current Status: ${_hasAvailableSeats! ? "Available Seats" : "Fully Loaded"}',
                            style: TextStyle(
                              color: _hasAvailableSeats! ? Colors.green.shade700 : Colors.orange.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Capacity Buttons
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Available Seats Button
                          GestureDetector(
                            onTap: (_isLoadingAvailable || _isLoadingFull) ? null : () => _handleCapacityPress(true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                color: _hasAvailableSeats == true
                                    ? const Color(0xFF2E7D32) // Darker green when selected
                                    : const Color(0xFF4CAF50), // Regular green
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: _hasAvailableSeats == true ? 12 : 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isLoadingAvailable
                                  ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_seat,
                                    color: Colors.white,
                                    size: _hasAvailableSeats == true ? 36 : 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Bus Has Available Seats",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _hasAvailableSeats == true ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_hasAvailableSeats == true) ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      "SELECTED",
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

                          const SizedBox(height: 30),

                          // Fully Loaded Button
                          GestureDetector(
                            onTap: (_isLoadingAvailable || _isLoadingFull) ? null : () => _handleCapacityPress(false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                color: _hasAvailableSeats == false
                                    ? const Color(0xFFE65100) // Darker orange when selected
                                    : const Color(0xFFFF9800), // Regular orange
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: _hasAvailableSeats == false ? 12 : 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isLoadingFull
                                  ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people,
                                    color: Colors.white,
                                    size: _hasAvailableSeats == false ? 36 : 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Bus is Fully Loaded",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _hasAvailableSeats == false ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_hasAvailableSeats == false) ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      "SELECTED",
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
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