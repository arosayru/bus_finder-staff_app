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
  Map<String, String> routeNames = {};
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
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final shifts = await MapService.getFutureBusShifts(date: dateStr, time: timeStr);
      await _loadRouteNamesForShifts(shifts);

      setState(() {
        futureShifts = shifts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadRouteNamesForShifts(List<Map<String, dynamic>> shifts) async {
    Set<String> routeNumbers = {};
    for (var shift in shifts) {
      final routeNo = _getRouteNumber(shift);
      if (routeNo != null && routeNo != 'N/A') {
        routeNumbers.add(routeNo);
      }
    }

    for (String routeNumber in routeNumbers) {
      if (!routeNames.containsKey(routeNumber)) {
        try {
          final routeName = await _getRouteNameByNumber(routeNumber);
          if (routeName != null) {
            routeNames[routeNumber] = routeName;
          }
        } catch (_) {}
      }
    }
  }

  Future<String?> _getRouteNameByNumber(String routeNumber) async {
    try {
      final url = Uri.parse('$baseUrl/api/BusRoute/$routeNumber');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded['routeName']?.toString() ??
              decoded['RouteName']?.toString() ??
              decoded['route_name']?.toString() ??
              decoded['name']?.toString() ??
              decoded['Name']?.toString();
        } else if (decoded is String) {
          return decoded;
        }
      }
      return null;
    } catch (_) {
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
    return (routeNo != null && routeNo != 'null') ? routeNo.trim() : null;
  }

  String _getDisplayRouteName(String? routeNumber) {
    if (routeNumber == null || routeNumber == 'N/A') return 'N/A';
    final cached = routeNames[routeNumber];
    return (cached != null && cached.isNotEmpty) ? '$routeNumber - $cached' : routeNumber;
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
                const Text("Shift Tracker", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFB9933)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (futureShifts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 4))],
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
                  final routeNo = _getRouteNumber(shift);
                  final displayRouteName = _getDisplayRouteName(routeNo);

                  final numberPlate = shift['numberPlate']?.toString() ??
                      shift['NumberPlate']?.toString() ??
                      shift['busNumberPlate']?.toString() ??
                      shift['BusNumberPlate']?.toString() ?? 'N/A';

                  final normalStartTime = shift['normal']?['startTime']?.toString() ??
                      shift['normal']?['StartTime']?.toString() ?? 'N/A';
                  final normalEndTime = shift['normal']?['endTime']?.toString() ??
                      shift['normal']?['EndTime']?.toString() ?? 'N/A';
                  final normalDate = shift['normal']?['date']?.toString() ??
                      shift['normal']?['Date']?.toString() ?? 'N/A';

                  final reverseStartTime = shift['reverse']?['startTime']?.toString() ??
                      shift['reverse']?['StartTime']?.toString() ?? 'N/A';
                  final reverseEndTime = shift['reverse']?['endTime']?.toString() ??
                      shift['reverse']?['EndTime']?.toString() ?? 'N/A';
                  final reverseDate = shift['reverse']?['date']?.toString() ??
                      shift['reverse']?['Date']?.toString() ?? 'N/A';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShiftTripScreen(
                        shiftData: {
                          'routeNumber': routeNo ?? 'N/A',
                          'displayRouteName': displayRouteName,
                          'numberPlate': numberPlate,
                          'normalStartTime': normalStartTime,
                          'normalEndTime': normalEndTime,
                          'normalDate': normalDate,
                          'reverseStartTime': reverseStartTime,
                          'reverseEndTime': reverseEndTime,
                          'reverseDate': reverseDate,
                        },
                      ),
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
    String getNestedValue(String parent, List<String> keys) {
      if (shift[parent] is Map<String, dynamic>) {
        final m = shift[parent];
        for (final k in keys) {
          final val = m[k]?.toString();
          if (val != null && val != 'null') return val;
        }
      }
      return 'N/A';
    }

    String getVal(List<String> keys) {
      for (var k in keys) {
        final val = shift[k]?.toString();
        if (val != null && val != 'null') return val;
      }
      return 'N/A';
    }

    final routeNo = getVal(['routeNo', 'RouteNo', 'busRoute', 'BusRoute']);
    final displayRouteName = _getDisplayRouteName(routeNo);
    final normalStartTime = getNestedValue('normal', ['startTime', 'StartTime']);
    final normalEndTime = getNestedValue('normal', ['endTime', 'EndTime']);
    final normalDate = getNestedValue('normal', ['date', 'Date']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(displayRouteName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFB9933))),
        if (normalDate != 'N/A') _detailLine("Date:", normalDate),
        if (normalStartTime != 'N/A') _detailLine("Start:", normalStartTime),
        if (normalEndTime != 'N/A') _detailLine("End:", normalEndTime),
      ],
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 13.5),
          children: [
            TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
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
        boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(0, -5), blurRadius: 6)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          return GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, routes[index], (r) => false),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4))
              ]),
              child: Icon(icons[index], color: const Color(0xFFCF4602)),
            ),
          );
        }),
      ),
    );
  }
}
