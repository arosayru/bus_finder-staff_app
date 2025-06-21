import 'package:flutter/material.dart';

class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({super.key});

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  // Dummy route data
  final List<Map<String, dynamic>> routes = List.generate(4, (index) {
    return {
      'number': 'No. 05',
      'routeName': 'Kurunegala - Colombo',
      'travelTime': 'Around 2.5 hours',
      'distance': '93.4km',
      'departureTime': '6.10 a.m',
      'arrivalTime': '8.40 a.m',
    };
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Custom AppBar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            decoration: const BoxDecoration(
              color: Color(0xFFFB9933),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
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

          // Routes List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
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
                  child: Row(
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
                            Text(
                              route['number'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildDetailLine('Route Name:', route['routeName']),
                            _buildDetailLine('Travel Time:', route['travelTime']),
                            _buildDetailLine('Distance:', route['distance']),
                            _buildDetailLine('Departure Time:', route['departureTime']),
                            _buildDetailLine('Arrival Time:', route['arrivalTime']),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
