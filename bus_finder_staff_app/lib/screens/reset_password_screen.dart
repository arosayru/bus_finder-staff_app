import 'package:bus_finder_staff_app/screens/login_screen.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
        child: SafeArea(
          child: Column(
            children: [
              // Back Button and Title with Divider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Reset Password",
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
                ],
              ),

              const Spacer(),

              // Form card
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Enter New Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBD2D01),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Your new password must be different\nfrom previous used password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ✅ Floating Label Password Field
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      style: const TextStyle(color: Color(0xFFBD2D01)),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Color(0xFFF67F00)),
                        filled: true,
                        fillColor: const Color(0xFFFFE5CC),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFFBD2D01),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ✅ Floating Label Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Color(0xFFBD2D01)),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: const TextStyle(color: Color(0xFFF67F00)),
                        filled: true,
                        fillColor: const Color(0xFFFFE5CC),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFFBD2D01),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
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
                            child: const Text(
                              'Continue',
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
                  ],
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
