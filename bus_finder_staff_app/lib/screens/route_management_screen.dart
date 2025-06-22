import 'package:flutter/material.dart';

class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({super.key});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  final List<Map<String, dynamic>> routes = List.generate(4, (index) {
    return {
      'number': 'No. 05',
      'routeName': 'Kurunegala - Colombo',
      'travelTime': 'Around 2.5 hours',
      'distance': '93.4km',
      'departureTime': '6.10 a.m',
      'arrivalTime': '8.40 a.m',
      'stops': [
        'Kurunegala',
        'Polgahawela',
        'Alawwa',
        'Warakapola',
        'Nittambuwa',
        'Yakkala',
        'Kadawatha',
        'Peliyagoda',
        'Colombo',
      ]
    };
  });

  List<bool> expanded = [];

  @override
  void initState() {
    super.initState();
    expanded = List.filled(routes.length, false);
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
                )
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                final isOpen = expanded[index];

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
                            child: Icon(Icons.directions_bus, size: 30),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(route['number'],
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                _buildDetailLine('Route Name:', route['routeName']),
                                _buildDetailLine('Departure Time:', route['departureTime']),
                                _buildDetailLine('Arrival Time:', route['arrivalTime']),
                                _buildDetailLine('Travel Time:', route['travelTime']),
                                _buildDetailLine('Distance:', route['distance']),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                expanded[index] = !expanded[index];
                              });
                            },
                            child: Icon(
                              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            ),
                          ),
                        ],
                      ),
                      if (isOpen) ...[
                        const SizedBox(height: 10),
                        const Text(
                          "Route:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          children: List.generate(route['stops'].length, (i) {
                            final isFirst = i == 0;
                            final isLast = i == route['stops'].length - 1;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    if (!isFirst)
                                      Container(height: 8, width: 2, color: Colors.grey),
                                    Icon(
                                      isLast ? Icons.location_on : Icons.radio_button_checked,
                                      color: isLast ? Colors.red : Colors.orange,
                                      size: 18,
                                    ),
                                    if (!isLast)
                                      Container(height: 20, width: 2, color: Colors.grey),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    route['stops'][i],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar (no active selection)
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

            return GestureDetector(
              onTap: () {
                if (index == 0) {
                  // Navigate to Dashboard
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
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
                  color: const Color(0xFFCF4602),
                ),
              ),
            );
          }),
        ),
      ),
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
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
