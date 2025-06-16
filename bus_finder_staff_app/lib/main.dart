import 'package:flutter/material.dart';

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
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
              Color(0xFFBD2D01), // 0%
              Color(0xFFCF4602), // 10%
              Color(0xFFF67F00), // 50%
              Color(0xFFCF4602), // 90%
              Color(0xFFBD2D01), // 100%
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bus Logo
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
