import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;

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
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo_staff.png',
                  height: 150,
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700, // slightly bolder
                          color: Color(0xFFBD2D01),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      TextField(
                        style: const TextStyle(
                          color: Color(0xFFBD2D01), // input text color
                        ),
                        decoration: InputDecoration(
                          hintText: 'Email or username',
                          hintStyle: const TextStyle(color: Color(0xFFF67F00)),
                          filled: true,
                          fillColor: const Color(0xFFFFE5CC),
                          suffixIcon: const Icon(
                            Icons.person,
                            color: Color(0xFFBD2D01),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Password Field
                      TextField(
                        obscureText: _obscureText,
                        style: const TextStyle(
                          color: Color(0xFFBD2D01), // input text color
                        ),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Color(0xFFF67F00)),
                          filled: true,
                          fillColor: const Color(0xFFFFE5CC),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFFBD2D01),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/forgot');
                          },
                          child: const Text(
                            'Forget Password?',
                            style: TextStyle(
                              color: Color(0xFFBD2D01),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xFFCF4602),
                                  Color(0xFFF67F00),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(context, '/dashboard');
                                },
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
