import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/route_management_screen.dart';
import 'screens/shift_tracker_screen.dart';
import 'screens/bus_capacity_screen.dart';
import 'screens/report_issue_screen.dart';
import 'screens/live_map_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/more_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/language_screen.dart';

void main() {
  runApp(const BusFinderApp());
}

class BusFinderApp extends StatelessWidget {
  const BusFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bus Finder',
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/verify': (context) => const EmailVerificationScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        'route-management': (context) => const RouteManagementScreen(),
        'shift-tracker': (context) => const ShiftTrackerScreen(),
        'bus-capacity': (context) => const BusCapacityScreen(),
        'report-issue': (context) => const ReportIssueScreen(),
        'live-map': (context) => const LiveMapScreen(),
        'notification': (context) => const NotificationsScreen(),
        'more': (context) => const MoreScreen(),
        'profile': (context) => const ProfileScreen(),
        'language': (context) => const LanguageScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 10), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_staff.png',
                height: 180,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
