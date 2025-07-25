import 'dart:async';
import 'package:flutter/material.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  final String _fullText = '''We are a group of passionate second-year students from the National Institute of Business Management (NIBM), currently pursuing our Bachelor’s Degree in Software Engineering. As part of our academic journey, we have taken the initiative to develop the Bus Finder application as our final year project. 

Our goal is to deliver a smart and user-friendly transportation solution that improves the public bus experience in Sri Lanka, especially for foreign travelers. Through this project, we aim to apply the skills and knowledge we've gained during our studies to solve real-world problems with practical and innovative software solutions.

We are committed to continuously improving this platform and hope it brings convenience, safety, and efficiency to everyone who uses public transport in Sri Lanka.''';

  String _displayedText = '';
  int _charIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
  }

  void _startTypingAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_charIndex < _fullText.length) {
        setState(() {
          _displayedText += _fullText[_charIndex];
          _charIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              // 🔸 Header
              Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "About Us",
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
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 2,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              // 🔸 Description Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFF67F00),
                            Color(0xFFCF4602),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds);
                      },
                      child: const Text(
                        "About Us",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // required for ShaderMask
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _displayedText,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 🔸 Logo & Version (replace with your asset)
              Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png', // 🔁 make sure this asset path is correct
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    "version 0.0.1",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
