import 'package:flutter/material.dart';
import '../user_service.dart';
import '/service/gps_service.dart'; // Import the GPS service
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late GpsService _gpsService;
  int currentIndex = 0;
  String staffId = 'N/A';
  bool isLoading = true;
  String staffFirstName = '';
  String staffLastName = '';

  @override
  void initState() {
    super.initState();
    _gpsService = GpsService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize GPS service first
    await _gpsService.initialize();
    // Then fetch staff ID
    await _fetchStaffId();
  }

  Future<void> _fetchStaffId() async {
    try {
      final email = await UserService.getStaffEmail();
      if (email != null && email.isNotEmpty && email != 'N/A') {
        // Step 1: Get staffId by email
        final idUrl = Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/Staff/get-id-by-email/$email');
        final idResponse = await http.get(idUrl);
        if (idResponse.statusCode == 200) {
          final idData = jsonDecode(idResponse.body);
          final fetchedStaffId = idData['staffId']?.toString() ?? idData['StaffID']?.toString();
          if (fetchedStaffId != null && fetchedStaffId.isNotEmpty) {
            // Step 2: Get staff details by staffId
            final detailsUrl = Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/Staff/$fetchedStaffId');
            final detailsResponse = await http.get(detailsUrl);
            if (detailsResponse.statusCode == 200) {
              final detailsData = jsonDecode(detailsResponse.body);
              setState(() {
                staffId = fetchedStaffId;
                staffFirstName = detailsData['firstName']?.toString() ?? detailsData['FirstName']?.toString() ?? '';
                staffLastName = detailsData['lastName']?.toString() ?? detailsData['LastName']?.toString() ?? '';
                isLoading = false;
              });
              return;
            }
            // If details fetch fails, fallback to just staffId
            setState(() {
              staffId = fetchedStaffId;
              staffFirstName = '';
              staffLastName = '';
              isLoading = false;
            });
            return;
          }
        }
        // If staffId fetch fails, fallback to email
        setState(() {
          staffId = email;
          staffFirstName = '';
          staffLastName = '';
          isLoading = false;
        });
      } else {
        setState(() {
          staffId = 'N/A';
          staffFirstName = '';
          staffLastName = '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        staffId = 'N/A';
        staffFirstName = '';
        staffLastName = '';
        isLoading = false;
      });
    }
  }

  String getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFB9933),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFFFB9933),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            isLoading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Text(
                              staffFirstName.isNotEmpty || staffLastName.isNotEmpty
                                  ? 'Hi $staffFirstName $staffLastName,'
                                  : 'Hi $staffId,',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              getGreetingMessage(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Enhanced GPS Toggle Container with detailed feedback
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 25),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF67F00),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: AnimatedBuilder(
                            animation: _gpsService,
                            builder: (context, child) {
                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _gpsService.isGpsEnabled ? "GPS Location Sharing" : "GPS Disabled",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              _gpsService.isGpsEnabled
                                                  ? 'Sharing live location...'
                                                  : 'Location sharing stopped',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          // Toggle GPS using the global service
                                          await _gpsService.toggleGps();

                                          // Show feedback to user
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  _gpsService.isGpsEnabled
                                                      ? 'GPS enabled. Sharing live location...'
                                                      : 'GPS disabled. Location sharing stopped.',
                                                ),
                                                backgroundColor: _gpsService.isGpsEnabled ? Colors.green : Colors.red,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          width: 52,
                                          height: 30,
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: AnimatedAlign(
                                            alignment: _gpsService.isGpsEnabled
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            duration: const Duration(milliseconds: 200),
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: _gpsService.isGpsEnabled
                                                    ? const Color(0xFF23C51E)
                                                    : const Color(0xFFC51E1E),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Additional GPS information
                                  if (_gpsService.targetBusNumberPlate != null ||
                                      _gpsService.currentLocation != null ||
                                      _gpsService.errorMessage != null)
                                    const SizedBox(height: 8),
                                  if (_gpsService.targetBusNumberPlate != null)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Bus: ${_gpsService.targetBusNumberPlate}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if (_gpsService.currentLocation != null)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Last update: ${_gpsService.currentLocation!.latitude.toStringAsFixed(4)}, ${_gpsService.currentLocation!.longitude.toStringAsFixed(4)}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  if (_gpsService.errorMessage != null)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _gpsService.errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 25),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              children: [
                                _buildFeatureCard("Route\nManagement", () {
                                  Navigator.pushNamed(context, 'route-management');
                                }),
                                _buildFeatureCard("Shift\nTracker", () {
                                  Navigator.pushNamed(context, 'shift-tracker');
                                }),
                                _buildFeatureCard("Bus\nCapacity", () {
                                  Navigator.pushNamed(context, 'bus-capacity');
                                }),
                                _buildFeatureCard("Report\nIssue", () {
                                  Navigator.pushNamed(context, 'report-issue');
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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

            final isSelected = index == currentIndex;
            return GestureDetector(
              onTap: () {
                setState(() => currentIndex = index);

                if (index == 0) {
                  // Already on dashboard, do nothing
                } else if (index == 1) {
                  Navigator.pushNamed(context, 'live-map');
                } else if (index == 2) {
                  Navigator.pushNamed(context, 'notification');
                } else if (index == 3) {
                  Navigator.pushNamed(context, 'more');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomLeft,
                    stops: [0.0, 0.1, 0.5, 0.9, 1.0],
                    colors: [
                      Color(0xFFBD2D01),
                      Color(0xFFCF4602),
                      Color(0xFFF67F00),
                      Color(0xFFCF4602),
                      Color(0xFFBD2D01),
                    ],
                  )
                      : null,
                  color: isSelected ? null : Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFFCF4602),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.1, 0.5, 0.9, 1.0],
            colors: [
              Color(0xFFBD2D01),
              Color(0xFFCF4602),
              Color(0xFFF67F00),
              Color(0xFFCF4602),
              Color(0xFFBD2D01),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(2, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the GPS service here as it's a singleton
    super.dispose();
  }
}