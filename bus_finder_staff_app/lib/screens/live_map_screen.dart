import 'package:flutter/material.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final int currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 🔸 Top Header
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
                  "Live Map",
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

          // 🔸 Location Inputs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildInputRow(Icons.radio_button_checked, "Kurunegala"),
                const SizedBox(height: 8),
                _buildInputRow(Icons.location_pin, "Colombo"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🔸 Map Image Placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/sample_map.jpeg',
                fit: BoxFit.cover,
                height: 400,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildInputRow(IconData icon, String hint) {
    return Row(
      children: [
        Icon(icon, color: Colors.red, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            readOnly: true,
            controller: TextEditingController(text: hint),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red),
                borderRadius: BorderRadius.circular(6),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red),
                borderRadius: BorderRadius.circular(6),
              ),
              isDense: true,
            ),
          ),
        ),
      ],
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

          final isSelected = index == currentIndex;

          return GestureDetector(
            onTap: () {
              if (index == 1) {
                // Already on Live Map
              } else if (index == 0) {
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
              } else if (index == 2){
                Navigator.pushNamedAndRemoveUntil(context, 'notification', (route) => false);
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
