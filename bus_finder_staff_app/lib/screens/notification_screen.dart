import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final int currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notifications = [
      {
        "title": "Assigned",
        "routeNo": "No. 05",
        "description": "Departure at 9.16 a.m",
        "date": "01/06/2026",
        "time": "9.16 a.m"
      },
      {
        "title": "Update the route",
        "routeNo": "No. 05",
        "description": "",
        "date": "01/06/2026",
        "time": "9.16 a.m"
      },
    ];

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
                  onTap: () {
                    // 🔁 Force dashboard reload and reset nav state
                    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                  },
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Notifications",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Notification Cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.directions_bus, size: 28, color: Colors.black),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notification["title"]!,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black)),
                                  const SizedBox(height: 4),
                                  Text(notification["routeNo"]!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, color: Colors.black)),
                                  if (notification["description"]!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(notification["description"]!,
                                          style: const TextStyle(color: Colors.black)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Date: ${notification["date"]}",
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text("Time: ${notification["time"]}",
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500)),
                              ],
                            )
                          ],
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            // TODO: implement dismiss
                          },
                          child: const Icon(Icons.close, size: 16, color: Colors.black),
                        ),
                      )
                    ],
                  ),
                );
              },
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
              icon = Icons.notifications;
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
              if (index == 2) {
                // Already on Notifications screen
              } else if (index == 0) {
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
              } else if (index == 1) {
                Navigator.pushNamedAndRemoveUntil(context, 'live-map', (route) => false);
              } else if (index == 3) {
                Navigator.pushNamedAndRemoveUntil(context, 'more', (route) => false);
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
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4)),
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
    );
  }
}
