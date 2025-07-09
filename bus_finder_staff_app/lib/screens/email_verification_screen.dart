import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResending = false;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get email from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      _email = args;
    }
  }

  Future<void> _resendCode() async {
    if (_email == null) {
      _showErrorDialog('Error', 'Email address not found. Please go back and try again.');
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final client = http.Client();

      final response = await client.post(
        Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/Staff/forgot-password'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'User-Agent': 'Flutter App',
        },
        body: jsonEncode(<String, String>{
          'Email': _email!,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timeout', const Duration(seconds: 30));
        },
      );

      client.close();

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code has been resent to your email.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        String errorMsg = 'Failed to resend code. Please try again.';
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['error'] != null) {
            errorMsg = body['error'];
          } else if (body['message'] != null) {
            errorMsg = body['message'];
          }
        } catch (e) {
          // ignore parse error, use default errorMsg
        }

        if (mounted) {
          _showErrorDialog('Error', errorMsg);
        }
      }
    } on SocketException catch (e) {
      if (mounted) {
        _showErrorDialog('Network Error',
            'Please check your internet connection and try again.\nError: ${e.message}');
      }
    } on TimeoutException {
      if (mounted) {
        _showErrorDialog('Connection Timeout',
            'The request timed out. Please check your internet connection and try again.');
      }
    } on HttpException catch (e) {
      if (mounted) {
        _showErrorDialog('HTTP Error',
            'HTTP error occurred: ${e.message}');
      }
    } on FormatException {
      if (mounted) {
        _showErrorDialog('Data Error',
            'Invalid response format from server.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Unexpected Error',
            'An unexpected error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll just navigate to reset password screen
      // In a real implementation, you would verify the code with the server
      if (mounted) {
        Navigator.pushNamed(context, '/reset', arguments: _email);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Failed to verify code: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
        child: SafeArea(
          child: Column(
            children: [
              // Back Button and Title with divider
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
                          "Email Verification",
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
                ],
              ),

              const Spacer(),

              // Form Card
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Get Your Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBD2D01),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Please enter the code that send to your\nemail address',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // ✅ Floating Label Input for code
                      TextFormField(
                        controller: codeController,
                        style: const TextStyle(color: Color(0xFFBD2D01)),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Enter your code',
                          labelStyle: const TextStyle(color: Color(0xFFF67F00)),
                          filled: true,
                          fillColor: const Color(0xFFFFE5CC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the verification code';
                          }
                          if (value.length < 4) {
                            return 'Code must be at least 4 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: _isResending ? null : _resendCode,
                        child: RichText(
                          text: TextSpan(
                            text: "If you don't received the code! ",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: _isResending ? "Resending..." : "Resend",
                                style: TextStyle(
                                  color: _isResending ? Colors.grey : const Color(0xFFBD2D01),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyCode,
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
                              child: _isLoading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'Verify and Proceed',
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
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
