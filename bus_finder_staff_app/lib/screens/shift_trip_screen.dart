import 'package:flutter/material.dart';

class ShiftTripScreen extends StatefulWidget {
  const ShiftTripScreen({super.key});

  @override
  State<ShiftTripScreen> createState() => _ShiftTripScreenState();
}

class _ShiftTripScreenState extends State<ShiftTripScreen> {
  final String routeNo = "No. 05";
  final String routeName = "Kurunegala - Colombo";
  final String distance = "93.4km";
  final String travelTime = "Around 2.5 hours";
  final String departure = "6.10 a.m";
  final String arrival = "8.40 a.m";

  final List<String> activities = [];

  void _addActivity(String label) {
    final now = DateTime.now();
    final time =
        "${now.hour % 12 == 0 ? 12 : now.hour % 12}.${now.minute.toString().padLeft(2, '0')}${now.hour >= 12 ? 'p.m' : 'a.m'}";
    final date =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    setState(() {
      activities.insert(
        0,
        "Route No: $routeNo\nRoute Name: $routeName\nDate: $date\n$label at $time",
      );
    });
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
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
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
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(routeNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                        _detail("Route Name:", routeName),
                        _detail("Distance:", distance),
                        _detail("Departure Time:", departure),
                        _detail("Arrival Time:", arrival),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStyledButton(
                    "Start Trip",
                    const Color(0xFF23C51E),
                    () => _addActivity("Starts Trip"),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildStyledButton(
                    "End Trip",
                    const Color(0xFFC51E1E),
                    () => _addActivity("Ends Trip"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStyledButton(
              "Interval",
              const Color(0xFF1263CE),
              () => _addActivity("Interval"),
              isWide: true,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF67F00),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 4),
                  )
                ],
              ),
              child: const Text(
                "Activities",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    color: const Color(0xFFFFF1E6),
                    child: Text(activities[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _detail(String label, String value) {
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

  Widget _buildStyledButton(String text, Color color, VoidCallback onPressed, {bool isWide = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isWide ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.9),
              color,
              color.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 4)),
            BoxShadow(color: Colors.white60, blurRadius: 3, offset: Offset(-2, -2)),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
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
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("This section will be implemented soon."),
                    duration: Duration(seconds: 2),
                  ),
                );
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
