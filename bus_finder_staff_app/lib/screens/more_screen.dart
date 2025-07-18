import 'package:flutter/material.dart';
import '../user_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final int currentIndex = 3;

  String staffFirstName = '';
  String staffLastName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStaffName();
  }

  Future<void> _fetchStaffName() async {
    setState(() { isLoading = true; });
    try {
      final email = await UserService.getStaffEmail();
      if (email != null && email.isNotEmpty && email != 'N/A') {
        final idUrl = Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/Staff/get-id-by-email/$email');
        final idResponse = await http.get(idUrl);
        if (idResponse.statusCode == 200) {
          final idData = jsonDecode(idResponse.body);
          final staffId = idData['staffId']?.toString() ?? idData['StaffID']?.toString();
          if (staffId != null && staffId.isNotEmpty) {
            final detailsUrl = Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/Staff/$staffId');
            final detailsResponse = await http.get(detailsUrl);
            if (detailsResponse.statusCode == 200) {
              final detailsData = jsonDecode(detailsResponse.body);
              setState(() {
                staffFirstName = detailsData['firstName']?.toString() ?? detailsData['FirstName']?.toString() ?? '';
                staffLastName = detailsData['lastName']?.toString() ?? detailsData['LastName']?.toString() ?? '';
                isLoading = false;
              });
              return;
            }
          }
        }
      }
    } catch (e) {}
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFB9933),
      body: SafeArea(
        child: Stack(
          children: [
            Container(height: 160, color: const Color(0xFFFB9933)),
            Column(
              children: [
                // 🔸 Centered Profile Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.person, size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      isLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(
                        (staffFirstName.isNotEmpty || staffLastName.isNotEmpty)
                            ? '$staffFirstName $staffLastName'
                            : '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
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
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildMenuItem(
                              icon: Icons.person,
                              label: "Profile",
                              onTap: () {
                                Navigator.pushNamed(context, 'profile');
                              }),
                          _buildMenuItem(
                              icon: Icons.feedback_outlined,
                              label: "Review Feedback",
                              onTap: () {
                                Navigator.pushNamed(context, 'review-feedback');
                              }),
                          _buildMenuItem(
                              icon: Icons.help_outline,
                              label: "Help & Support",
                              onTap: () {
                                Navigator.pushNamed(context, 'help-and-support');
                              }),
                          _buildMenuItem(
                              icon: Icons.info_outline,
                              label: "About Us",
                              onTap: () {
                                Navigator.pushNamed(context, 'about-us');
                              }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            child: GestureDetector(
                              onTap: () async {
                                await UserService.clearStaffData();
                                if (mounted) {
                                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
                                  ],
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.logout, color: Colors.white),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        "Log Out",
                                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
            ],
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

          final isSelected = index == currentIndex;

          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
              } else if (index == 1) {
                Navigator.pushNamedAndRemoveUntil(context, 'live-map', (route) => false);
              } else if (index == 2) {
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
              child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFFCF4602)),
            ),
          );
        }),
      ),
    );
  }
}
