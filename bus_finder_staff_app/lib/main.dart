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
import 'screens/review_feedback_screen.dart';
import 'screens/help_and_support_screen.dart';
import 'screens/about_us_screen.dart';
import 'service/gps_service.dart';

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
        primarySwatch: Colors.orange,
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
        'review-feedback': (context) => ReviewFeedbackScreen(),
        'help-and-support': (context) => const HelpSupportScreen(),
        'about-us': (context) => const AboutUsScreen()
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
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize GPS service when app starts
      final gpsService = GpsService();
      await gpsService.initialize();

      setState(() {
        _isInitialized = true;
      });

      // Wait for splash screen duration (10 seconds as per original)
      await Future.delayed(const Duration(seconds: 10));

      // Navigate to login screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }

    } catch (e) {
      print('Error initializing app: $e');
      setState(() {
        _isInitialized = true;
        _hasError = true;
        _errorMessage = 'Failed to initialize GPS service';
      });

      // Still navigate to login after delay even if GPS fails
      await Future.delayed(const Duration(seconds: 10));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
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
              // App Logo
              Image.asset(
                'assets/images/logo_staff.png',
                height: 180,
              ),
              const SizedBox(height: 30),

              // Loading indicator and status
              if (!_isInitialized) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initializing app...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else if (_hasError) ...[
                const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Continuing to login...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App initialized successfully!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Progress indicator for splash screen duration
              const SizedBox(height: 40),
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}