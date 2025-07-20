import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'shift_trip_screen.dart';
import '/map_service.dart';

class ShiftTrackerScreen extends StatefulWidget {
  const ShiftTrackerScreen({super.key});

  @override
  State<ShiftTrackerScreen> createState() => _ShiftTrackerScreenState();
}

class _ShiftTrackerScreenState extends State<ShiftTrackerScreen> {
  List<Map<String, dynamic>> futureShifts = [];
  Map<String, String> routeNames = {}; // Cache for route names
  bool isLoading = true;
  String? errorMessage;
  static const String baseUrl = 'https://bus-finder-sl-a7c6a549fbb1.herokuapp.com';

  @override
  void initState() {
    super.initState();
    _loadFutureShifts();
  }

  Future<void> _loadFutureShifts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final now = DateTime.now();

      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Format time as HH:MM:SS
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      print('DEBUG: Using date format: $dateStr');
      print('DEBUG: Using time format: $timeStr');

      // Use the existing MapService method
      final shifts = await MapService.getFutureBusShifts(
        date: dateStr,
        time: timeStr,
      );

      // Load route names for all shifts
      await _loadRouteNamesForShifts(shifts);

      setState(() {
        futureShifts = shifts;
        isLoading = false;
      });

      print('DEBUG: Loaded ${shifts.length} future shifts');
      for (int i = 0; i < shifts.length; i++) {
        print('DEBUG: Shift ${i + 1}: ${shifts[i]}');
      }

    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      print('Error loading future shifts: $e');
    }
  }

  Future<void> _loadRouteNamesForShifts(List<Map<String, dynamic>> shifts) async {
    // Extract unique route numbers
    Set<String> routeNumbers = {};
    for (var shift in shifts) {
      final routeNo = _getRouteNumber(shift);
      if (routeNo != null && routeNo != 'N/A') {
        routeNumbers.add(routeNo);
      }
    }

    print('DEBUG: Found ${routeNumbers.length} unique route numbers: $routeNumbers');

    // Fetch route names for each unique route number
    for (String routeNumber in routeNumbers) {
      if (!routeNames.containsKey(routeNumber)) {
        try {
          final routeName = await _getRouteNameByNumber(routeNumber);
          if (routeName != null) {
            routeNames[routeNumber] = routeName;
            print('DEBUG: Cached route name for $routeNumber: $routeName');
          }
        } catch (e) {
          print('DEBUG: Failed to get route name for $routeNumber: $e');
          // Continue with other routes even if one fails
        }
      }
    }

    print('DEBUG: Total cached route names: ${routeNames.length}');
  }

  Future<String?> _getRouteNameByNumber(String routeNumber) async {
    try {
      final url = Uri.parse('$baseUrl/api/BusRoute/$routeNumber');
      print('DEBUG: Fetching route name from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Route name response status: ${response.statusCode}');
      print('DEBUG: Route name response body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
        print('DEBUG: Decoded route response: $decoded');

        // Handle different possible response structures
        String? routeName;
        if (decoded is Map<String, dynamic>) {
          // Try different possible field names for route name
          routeName = decoded['routeName']?.toString() ??
              decoded['RouteName']?.toString() ??
              decoded['route_name']?.toString() ??
              decoded['name']?.toString() ??
              decoded['Name']?.toString();
        } else if (decoded is String) {
          routeName = decoded;
        }

        if (routeName != null && routeName.trim().isNotEmpty && routeName != 'null') {
          print('DEBUG: Successfully extracted route name: $routeName');
          return routeName.trim();
        }
      }

      print('DEBUG: No valid route name found for route number: $routeNumber');
      return null;
    } catch (e) {
      print('DEBUG: Exception getting route name for $routeNumber: $e');
      return null;
    }
  }

  String? _getRouteNumber(Map<String, dynamic> shift) {
    final routeNo = shift['routeNo']?.toString() ??
        shift['RouteNo']?.toString() ??
        shift['busRoute']?.toString() ??
        shift['BusRoute']?.toString() ??
        shift['routeName']?.toString() ??
        shift['RouteName']?.toString();

    if (routeNo != null && routeNo.trim().isNotEmpty && routeNo != 'null') {
      return routeNo.trim();
    }
    return null;
  }

  String _getDisplayRouteName(String? routeNumber) {
    if (routeNumber == null || routeNumber == 'N/A') {
      return 'N/A';
    }

    final cachedName = routeNames[routeNumber];
    if (cachedName != null && cachedName.isNotEmpty) {
      return '$routeNumber - $cachedName';
    }

    // Return just the route number if name is not available
    return routeNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
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
                  "Shift Tracker",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loadFutureShifts,
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFB9933)));
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading shifts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(errorMessage!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFutureShifts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB9933),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (futureShifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No future shifts available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Check back later for upcoming shifts'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: futureShifts.length,
      itemBuilder: (context, index) {
        final shift = futureShifts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 4)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 10, top: 4),
                child: Icon(Icons.directions_bus, size: 30, color: Color(0xFFFB9933)),
              ),
              Expanded(child: _buildShiftDetails(shift)),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ShiftTripScreen(),
                      // You can pass shift data if needed
                      // settings: RouteSettings(arguments: shift),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShiftDetails(Map<String, dynamic> shift) {
    // Helper function to safely get values with multiple key options
    String getValue(List<String> keys) {
      for (var key in keys) {
        if (shift.containsKey(key) && shift[key] != null) {
          final value = shift[key].toString().trim();
          if (value.isNotEmpty && value != 'null') {
            return value;
          }
        }
      }
      return 'N/A';
    }

    // Helper function to get nested values
    String getNestedValue(String parentKey, List<String> childKeys) {
      if (shift.containsKey(parentKey) && shift[parentKey] is Map<String, dynamic>) {
        final parentObj = shift[parentKey] as Map<String, dynamic>;
        for (var key in childKeys) {
          if (parentObj.containsKey(key) && parentObj[key] != null) {
            final value = parentObj[key].toString().trim();
            if (value.isNotEmpty && value != 'null') {
              return value;
            }
          }
        }
      }
      return 'N/A';
    }

    // Extract main shift information
    final shiftId = getValue(['shiftId', 'ShiftId', 'id', 'Id', 'shiftNumber', 'ShiftNumber']);
    final routeNo = getValue(['routeNo', 'RouteNo', 'busRoute', 'BusRoute', 'routeName', 'RouteName']);
    final numberPlate = getValue(['numberPlate', 'NumberPlate', 'busNumberPlate', 'BusNumberPlate']);

    // Get the display route name (route number + route name if available)
    final displayRouteName = _getDisplayRouteName(routeNo != 'N/A' ? routeNo : null);

    // Extract normal direction details
    final normalStartTime = getNestedValue('normal', ['startTime', 'StartTime']);
    final normalEndTime = getNestedValue('normal', ['endTime', 'EndTime']);
    final normalDate = getNestedValue('normal', ['date', 'Date']);

    // Extract reverse direction details
    final reverseStartTime = getNestedValue('reverse', ['startTime', 'StartTime']);
    final reverseEndTime = getNestedValue('reverse', ['endTime', 'EndTime']);
    final reverseDate = getNestedValue('reverse', ['date', 'Date']);

    // Fallback for when data might be at root level
    final fallbackStartTime = getValue(['startTime', 'StartTime', 'departureTime', 'DepartureTime']);
    final fallbackEndTime = getValue(['endTime', 'EndTime', 'arrivalTime', 'ArrivalTime']);
    final fallbackDate = getValue(['date', 'Date', 'shiftDate', 'ShiftDate']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            shiftId != 'N/A' ? 'Shift: $shiftId' : 'Bus Shift',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        const SizedBox(height: 4),
        if (displayRouteName != 'N/A') _detailLine("Route:", displayRouteName),
        if (numberPlate != 'N/A') _detailLine("Bus:", numberPlate),

        // Show normal direction if available
        if (normalStartTime != 'N/A' || normalEndTime != 'N/A' || normalDate != 'N/A') ...[
          const SizedBox(height: 8),
          const Text(
              'Normal Direction:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFB9933))
          ),
          if (normalDate != 'N/A') _detailLine("Date:", normalDate),
          if (normalStartTime != 'N/A') _detailLine("Start:", normalStartTime),
          if (normalEndTime != 'N/A') _detailLine("End:", normalEndTime),
        ],

        // Show reverse direction if available
        if (reverseStartTime != 'N/A' || reverseEndTime != 'N/A' || reverseDate != 'N/A') ...[
          const SizedBox(height: 8),
          const Text(
              'Reverse Direction:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFB9933))
          ),
          if (reverseDate != 'N/A') _detailLine("Date:", reverseDate),
          if (reverseStartTime != 'N/A') _detailLine("Start:", reverseStartTime),
          if (reverseEndTime != 'N/A') _detailLine("End:", reverseEndTime),
        ],

        // Show fallback data if no normal/reverse structure found
        if (normalStartTime == 'N/A' && reverseStartTime == 'N/A' &&
            (fallbackStartTime != 'N/A' || fallbackEndTime != 'N/A' || fallbackDate != 'N/A')) ...[
          const SizedBox(height: 4),
          if (fallbackDate != 'N/A') _detailLine("Date:", fallbackDate),
          if (fallbackStartTime != 'N/A') _detailLine("Start Time:", fallbackStartTime),
          if (fallbackEndTime != 'N/A') _detailLine("End Time:", fallbackEndTime),
        ],
      ],
    );
  }

  Widget _detailLine(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 13.5),
          children: [
            TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? "N/A"),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(0, -5), blurRadius: 6)],
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
              final routes = ['/dashboard', 'live-map', 'notification', 'more'];
              Navigator.pushNamedAndRemoveUntil(context, routes[index], (route) => false);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4))],
              ),
              child: Icon(icon, color: const Color(0xFFCF4602)),
            ),
          );
        }),
      ),
    );
  }
}