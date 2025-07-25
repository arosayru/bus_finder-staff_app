import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/map_service.dart';

class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({super.key});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  List<Map<String, dynamic>> routes = [];
  List<bool> expanded = [];
  bool isLoading = true;
  String? errorMessage;
  bool noShiftsAssigned = false;

  static const String baseUrl = 'https://bus-finder-sl-a7c6a549fbb1.herokuapp.com';

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        noShiftsAssigned = false;
      });

      // First get the route numbers from user's shifts (same as ShiftTrackerScreen)
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final shifts = await MapService.getFutureBusShifts(date: dateStr, time: timeStr);

      // Check if shifts is null or empty
      if (shifts == null || shifts.isEmpty) {
        setState(() {
          routes = [];
          expanded = [];
          noShiftsAssigned = true;
          isLoading = false;
        });
        return;
      }

      // Extract unique route numbers from shifts
      Set<String> routeNumbers = {};
      for (var shift in shifts) {
        final routeNo = _getRouteNumber(shift);
        if (routeNo != null && routeNo != 'N/A') {
          routeNumbers.add(routeNo);
        }
      }

      // If no route numbers found from shifts, show no routes state
      if (routeNumbers.isEmpty) {
        setState(() {
          routes = [];
          expanded = [];
          noShiftsAssigned = true;
          isLoading = false;
        });
        return;
      }

      // Fetch route details for each route number
      List<Map<String, dynamic>> fetchedRoutes = [];

      for (String routeNumber in routeNumbers) {
        final routeData = await _getRouteDetailsByNumber(routeNumber);
        if (routeData != null) {
          fetchedRoutes.add(routeData);
        }
      }

      setState(() {
        routes = fetchedRoutes;
        expanded = List.filled(routes.length, false);
        isLoading = false;
        // If we couldn't fetch any route details despite having route numbers
        if (fetchedRoutes.isEmpty && routeNumbers.isNotEmpty) {
          noShiftsAssigned = true;
        }
      });
    } catch (e) {
      setState(() {
        // Check if the error is specifically about no shifts assigned
        if (e.toString().toLowerCase().contains('no shift') ||
            e.toString().toLowerCase().contains('not assigned') ||
            e.toString().toLowerCase().contains('empty') ||
            e.toString().toLowerCase().contains('404')) {
          noShiftsAssigned = true;
          errorMessage = null;
        } else {
          errorMessage = e.toString();
          noShiftsAssigned = false;
        }
        routes = [];
        expanded = [];
        isLoading = false;
      });
    }
  }

  // Same method as in ShiftTrackerScreen to extract route number
  String? _getRouteNumber(Map<String, dynamic>? shift) {
    if (shift == null) return null;

    final routeNo = shift['routeNo']?.toString() ??
        shift['RouteNo']?.toString() ??
        shift['busRoute']?.toString() ??
        shift['BusRoute']?.toString() ??
        shift['routeName']?.toString() ??
        shift['RouteName']?.toString();
    return (routeNo != null && routeNo != 'null' && routeNo.trim().isNotEmpty) ? routeNo.trim() : null;
  }

  Future<Map<String, dynamic>?> _getRouteDetailsByNumber(String routeNumber) async {
    try {
      final url = Uri.parse('$baseUrl/api/BusRoute/$routeNumber');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = json.decode(response.body);

        if (decoded is Map<String, dynamic>) {
          return _parseRouteData(decoded, routeNumber);
        } else if (decoded is String) {
          // Handle if API returns just route name as string
          return {
            'number': 'No. $routeNumber',
            'routeNumber': routeNumber,
            'routeName': decoded,
            'travelTime': 'N/A',
            'distance': 'N/A',
            'departureTime': 'N/A',
            'arrivalTime': 'N/A',
            'stops': <String>[],
            'stopCount': 0,
          };
        }
      }
      return null;
    } catch (e) {
      print('Error fetching route details for $routeNumber: $e');
      return null;
    }
  }

  Map<String, dynamic> _parseRouteData(Map<String, dynamic>? data, String routeNumber) {
    if (data == null) {
      return {
        'number': 'No. $routeNumber',
        'routeNumber': routeNumber,
        'routeName': 'N/A',
        'travelTime': 'N/A',
        'distance': 'N/A',
        'departureTime': 'N/A',
        'arrivalTime': 'N/A',
        'stops': <String>[],
        'stopCount': 0,
      };
    }

    // Helper function to safely get string values from different possible key formats
    String getStringValue(List<String> possibleKeys) {
      for (String key in possibleKeys) {
        final value = data[key]?.toString();
        if (value != null && value.isNotEmpty && value != 'null') {
          return value;
        }
      }
      return 'N/A';
    }

    // Helper function to get stops array from different possible formats
    List<String> getStopsArray(List<String> possibleKeys) {
      for (String key in possibleKeys) {
        final value = data[key];
        if (value is List) {
          return value.map((stop) => stop?.toString() ?? '').where((stop) => stop.isNotEmpty).toList();
        } else if (value is String && value.isNotEmpty && value != 'null') {
          // If stops are comma-separated string
          return value.split(',').map((stop) => stop.trim()).where((stop) => stop.isNotEmpty).toList();
        }
      }
      return <String>[];
    }

    // Helper function to get numeric values
    double getDoubleValue(List<String> possibleKeys) {
      for (String key in possibleKeys) {
        final value = data[key];
        if (value is num) {
          return value.toDouble();
        } else if (value is String && value.isNotEmpty) {
          final parsed = double.tryParse(value);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
      return 0.0;
    }

    // Extract route information based on your JSON structure
    final routeName = getStringValue([
      'routeName', 'RouteName', 'route_name', 'name', 'Name'
    ]);

    final stops = getStopsArray([
      'routeStops', 'RouteStops', 'stops', 'Stops', 'busStops', 'BusStops',
      'route_stops', 'stations', 'Stations'
    ]);

    final distance = getDoubleValue([
      'routeDistance', 'RouteDistance', 'distance', 'Distance',
      'totalDistance', 'TotalDistance', 'length', 'Length'
    ]);

    // These might not be in your current JSON but keeping for future compatibility
    final startTime = getStringValue([
      'startTime', 'StartTime', 'departureTime', 'DepartureTime',
      'firstDeparture', 'FirstDeparture'
    ]);

    final endTime = getStringValue([
      'endTime', 'EndTime', 'arrivalTime', 'ArrivalTime',
      'lastArrival', 'LastArrival'
    ]);

    final travelTime = getStringValue([
      'travelTime', 'TravelTime', 'duration', 'Duration',
      'estimatedTime', 'EstimatedTime'
    ]);

    // Calculate estimated travel time based on distance if not provided
    String calculatedTravelTime = travelTime;
    if (calculatedTravelTime == 'N/A' && distance > 0) {
      // Rough estimation: assuming average speed of 25 km/h in city traffic
      final estimatedHours = distance / 25;
      final hours = estimatedHours.floor();
      final minutes = ((estimatedHours - hours) * 60).round();

      if (hours > 0) {
        calculatedTravelTime = 'Around ${hours}h ${minutes}m';
      } else if (minutes > 0) {
        calculatedTravelTime = 'Around ${minutes}m';
      }
    }

    return {
      'number': 'No. $routeNumber',
      'routeNumber': routeNumber,
      'routeName': routeName,
      'travelTime': calculatedTravelTime,
      'distance': distance > 0 ? '${distance.toStringAsFixed(1)} km' : 'N/A',
      'departureTime': startTime,
      'arrivalTime': endTime,
      'stops': stops,
      'stopCount': stops.length,
    };
  }

  String _calculateTravelTime(String startTime, String endTime) {
    if (startTime == 'N/A' || endTime == 'N/A') return 'N/A';

    try {
      // Simple time calculation (assuming same day)
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);

      if (start != null && end != null) {
        final difference = end.difference(start);
        final hours = difference.inHours;
        final minutes = difference.inMinutes % 60;

        if (hours > 0) {
          return 'Around ${hours}h ${minutes}m';
        } else {
          return 'Around ${minutes}m';
        }
      }
    } catch (e) {
      print('Error calculating travel time: $e');
    }

    return 'N/A';
  }

  DateTime? _parseTime(String timeString) {
    try {
      // Handle different time formats
      timeString = timeString.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
            decoration: const BoxDecoration(
              color: Color(0xFFFB9933),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Route Management",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loadRoutes,
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
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFB9933)),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading routes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(errorMessage!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRoutes,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB9933),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (noShiftsAssigned || routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.route_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Routes to Manage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'You don\'t have any shifts assigned,',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'so there are no routes to manage at the moment.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please contact your supervisor for shift assignments.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadRoutes,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB9933),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Check Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        final isOpen = index < expanded.length ? expanded[index] : false;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 10, top: 4),
                    child: Icon(
                      Icons.directions_bus,
                      size: 30,
                      color: Color(0xFFFB9933),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route['number'] ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFFB9933),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildDetailLine('Route Name:', route['routeName'] ?? 'N/A'),

                        // Show distance if available
                        if (route['distance'] != null && route['distance'] != 'N/A')
                          _buildDetailLine('Distance:', route['distance']),

                        // Show travel time if available
                        if (route['travelTime'] != null && route['travelTime'] != 'N/A')
                          _buildDetailLine('Travel Time:', route['travelTime']),

                        // Show number of stops
                        if (route['stopCount'] != null && route['stopCount'] > 0)
                          _buildDetailLine('Total Stops:', '${route['stopCount']} stops'),

                        // Show departure/arrival times if available
                        if (route['departureTime'] != null && route['departureTime'] != 'N/A')
                          _buildDetailLine('Departure Time:', route['departureTime']),
                        if (route['arrivalTime'] != null && route['arrivalTime'] != 'N/A')
                          _buildDetailLine('Arrival Time:', route['arrivalTime']),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        // Ensure expanded list is long enough
                        if (expanded.length <= index) {
                          expanded = List.filled(routes.length, false);
                        }
                        expanded[index] = !expanded[index];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFFFB9933),
                      ),
                    ),
                  ),
                ],
              ),

              // Expandable route stops section
              if (isOpen) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.grey, height: 1),
                const SizedBox(height: 12),

                if (route['stops'] != null && route['stops'].isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.route, color: Color(0xFFFB9933), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Route Stops (${route['stops'].length})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFFFB9933),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Route stops with visual indicators
                  Column(
                    children: List.generate(route['stops'].length, (i) {
                      final isFirst = i == 0;
                      final isLast = i == route['stops'].length - 1;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Visual route indicator
                          Column(
                            children: [
                              if (!isFirst)
                                Container(
                                  height: 12,
                                  width: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade300,
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: isFirst
                                      ? Colors.green
                                      : isLast
                                      ? Colors.red
                                      : Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  isFirst
                                      ? Icons.play_arrow
                                      : isLast
                                      ? Icons.location_on
                                      : Icons.circle,
                                  color: Colors.white,
                                  size: isFirst || isLast ? 10 : 6,
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  height: 20,
                                  width: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade300,
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Stop name
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1, bottom: 4),
                              child: Text(
                                route['stops'][i]?.toString() ?? 'Unknown Stop',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isFirst || isLast
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isFirst
                                      ? Colors.green.shade700
                                      : isLast
                                      ? Colors.red.shade700
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),

                          // Stop number indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "No stop information available for this route",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 13.5),
          children: [
            TextSpan(
              text: "$label ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final icons = [Icons.home, Icons.location_on_outlined, Icons.notifications_none, Icons.grid_view];
    final routes = ['/dashboard', 'live-map', 'notification', 'more'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, -5),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          return GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                routes[index],
                    (route) => false
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icons[index],
                color: const Color(0xFFCF4602),
              ),
            ),
          );
        }),
      ),
    );
  }
}