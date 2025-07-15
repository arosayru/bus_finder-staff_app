import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedSection;
  int? _expandedFaq;

  final List<Map<String, String>> faqList = [
    {
      "question": "How do I view live bus locations on the map?",
      "answer": "Navigate to the 'Live Map' section from the bottom navigation bar. The map will display real-time bus locations with their current routes. You can zoom in/out and tap on bus markers to see additional information about the bus and its route.",
    },
    {
      "question": "How can I check bus capacity and availability?",
      "answer": "Go to the 'Bus Capacity' section from the dashboard. This feature shows you the current passenger count, available seats, and capacity status for each bus. This helps you plan your journey and avoid overcrowded buses.",
    },
    {
      "question": "How do I track my shift and trips?",
      "answer": "Access the 'Shift Tracker' from the dashboard to view your current shift status, start/end times, and trip history. You can also view detailed trip information including routes taken, duration, and passenger counts.",
    },
    {
      "question": "How can I report issues or problems?",
      "answer": "Use the 'Report Issue' feature to submit technical problems, route issues, or any other concerns. Your report will be sent directly to the admin team for review and resolution.",
    },
    {
      "question": "How do I update my profile information?",
      "answer": "Go to 'More' → 'Profile' to update your personal information including name, email, and profile picture. Changes are saved automatically when you tap the 'Update' button.",
    },
    {
      "question": "What should I do if I forget my password?",
      "answer": "On the login screen, tap 'Forgot Password?' and enter your registered email address. You'll receive a password reset link via email. Follow the instructions to create a new password.",
    },
  ];

  final String appGuideText = """
Welcome to Bus Finder Staff App! This comprehensive guide will help you navigate and make the most of all available features.

🔸 Dashboard: Your central hub for quick access to all app functions. View your current status, recent activities, and quick action buttons.

🔸 Live Map: Real-time tracking of all buses in the network. See bus locations, routes, and current status. Tap on bus markers for detailed information.

🔸 Bus Capacity: Monitor passenger counts and seat availability across all buses. This helps in efficient route planning and passenger management.

🔸 Shift Tracker: Manage your work schedule, track shift times, and view trip history. Record start/end times and monitor your daily activities.

🔸 Route Management: Access detailed route information, schedules, and manage route assignments. View route maps and timing details.

🔸 Notifications: Stay updated with important alerts, schedule changes, and system notifications.

🔸 Profile Management: Update your personal information, change profile picture, and manage account settings.

🔸 Help & Support: Access FAQs, troubleshooting guides, and contact support when needed.

The app is designed to streamline bus operations and provide real-time information for better service delivery.
""";

  final List<Map<String, String>> troubleshootingList = [
    {
      "title": "Forgot Password",
      "description": "Reset your password using email verification",
      "action": "Go to Login → Forgot Password → Enter Email → Check Email → Reset Password"
    },
    {
      "title": "Update Profile Details",
      "description": "Modify your personal information and profile picture",
      "action": "More → Profile → Edit Fields → Update → Save Changes"
    },
    {
      "title": "App Not Loading",
      "description": "Troubleshoot app startup issues",
      "action": "Check internet connection → Restart app → Clear cache → Reinstall if needed"
    },
    {
      "title": "Map Not Showing",
      "description": "Fix map display issues",
      "action": "Enable location service → Check GPS → Refresh map → Restart app"
    },
    {
      "title": "Notifications Not Working",
      "description": "Enable app notifications",
      "action": "Settings → Apps → Bus Finder → Notifications → Enable"
    },
  ];

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri.parse('tel:0726407655');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No phone app found on your device')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching phone: $e')),
        );
      }
    }
  }

  Future<void> _launchEmail() async {
    try {
      // Try Gmail compose URL first (most reliable for Gmail)
      final Uri gmailComposeUri = Uri.parse(
          'https://mail.google.com/mail/?view=cm&fs=1&to=busfindersl@gmail.com&su=Bus%20Finder%20Staff%20App%20Support&body=Hello,%20I%20need%20help%20with%20the%20Bus%20Finder%20Staff%20App.'
      );

      if (await canLaunchUrl(gmailComposeUri)) {
        await launchUrl(gmailComposeUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback to mailto scheme
      final Uri mailtoUri = Uri.parse('mailto:busfindersl@gmail.com?subject=Bus%20Finder%20Staff%20App%20Support&body=Hello,%20I%20need%20help%20with%20the%20Bus%20Finder%20Staff%20App.');

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Final fallback - simple mailto
      final Uri simpleMailtoUri = Uri.parse('mailto:busfindersl@gmail.com');

      if (await canLaunchUrl(simpleMailtoUri)) {
        await launchUrl(simpleMailtoUri, mode: LaunchMode.externalApplication);
        return;
      }

      // If nothing works, show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app found. Please install Gmail or another email app.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching email: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
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
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 10.0, right: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Help & Support",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildFaqSection(0, "FAQs", Icons.question_answer_rounded),
                    _buildAppGuideSection(1, "App Guide", Icons.menu_book),
                    _buildTroubleshootingSection(2, "Troubleshooting", Icons.build),
                    _buildContactSection(3, "Contact & Support", Icons.support_agent),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSection(int index, String title, IconData icon) {
    final isExpanded = _expandedSection == index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedSection = isExpanded ? null : index;
              _expandedFaq = null;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFCF4602)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFCF4602),
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFFCF4602),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 3)),
              ],
            ),
            child: Column(
              children: faqList.asMap().entries.map((entry) {
                final i = entry.key;
                final q = entry.value;
                final isFaqExpanded = _expandedFaq == i;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isFaqExpanded ? const Color(0xFFFBE9E7) : Colors.white,
                    border: Border.all(color: const Color(0xFFCF4602), width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          q["question"]!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCF4602),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isFaqExpanded ? Icons.remove : Icons.add,
                            color: const Color(0xFFCF4602),
                          ),
                          onPressed: () {
                            setState(() {
                              _expandedFaq = isFaqExpanded ? null : i;
                            });
                          },
                        ),
                      ),
                      if (isFaqExpanded)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                          child: Text(
                            q["answer"]!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAppGuideSection(int index, String title, IconData icon) {
    final isExpanded = _expandedSection == index;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedSection = isExpanded ? null : index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFCF4602)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFCF4602),
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFFCF4602),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 3)),
              ],
            ),
            child: Text(
              appGuideText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTroubleshootingSection(int index, String title, IconData icon) {
    final isExpanded = _expandedSection == index;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedSection = isExpanded ? null : index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFCF4602)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFCF4602),
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFFCF4602),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 3)),
              ],
            ),
            child: Column(
              children: troubleshootingList.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE9E7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCF4602), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"]!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFCF4602),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item["description"]!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item["action"]!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFCF4602),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildContactSection(int index, String title, IconData icon) {
    final isExpanded = _expandedSection == index;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedSection = isExpanded ? null : index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFCF4602)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFCF4602),
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFFCF4602),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 3)),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Need help? Contact our support team through the following channels:",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Phone Contact
                GestureDetector(
                  onTap: _launchPhone,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCF4602), Color(0xFFF67F00)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Call Support",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "072 640 7655",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Email Contact
                GestureDetector(
                  onTap: _launchEmail,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCF4602), Color(0xFFF67F00)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Email Support",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "busfindersl@gmail.com",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE9E7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCF4602), width: 1),
                  ),
                  child: const Text(
                    "Our support team is available to help you with any technical issues, app-related questions, or general inquiries. We typically respond within 24 hours.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
