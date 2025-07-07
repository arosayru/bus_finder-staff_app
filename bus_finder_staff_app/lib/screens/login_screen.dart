import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      // Create HTTP client with custom configuration
      final client = http.Client();

      final response = await client.post(
        Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/staff/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'User-Agent': 'Flutter App',
        },
        body: jsonEncode(<String, String>{
          'Email': _email,
          'Password': _password,
        }),
      ).timeout(
        const Duration(seconds: 30), // Add timeout
        onTimeout: () {
          throw TimeoutException('Connection timeout', const Duration(seconds: 30));
        },
      );

      client.close(); // Close the client

      if (response.statusCode == 200) {
        // Parse the response to get staff data
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          // Save staff data to local storage
          if (responseData['staff'] != null) {
            await UserService.saveStaffData(responseData['staff']);
          } else {
            // If no staff data in response, create a basic staff object
            await UserService.saveStaffData({
              'Email': _email,
              'StaffID': responseData['staffId'] ?? responseData['staff_id'] ?? 'N/A',
              'Name': responseData['name'] ?? responseData['fullName'] ?? 'Staff Member',
            });
          }
        } catch (e) {
          // If parsing fails, save basic data
          await UserService.saveStaffData({
            'Email': _email,
            'StaffID': 'N/A',
            'Name': 'Staff Member',
          });
        }

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        String errorMsg = 'Login failed. Please try again.';
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['error'] == 'INVALID_LOGIN_CREDENTIALS') {
            errorMsg = 'Invalid username or password.';
          } else if (body['error'] == 'INVALID_EMAIL') {
            errorMsg = 'Invalid email format.';
          } else if (body['error'] == 'MISSING_PASSWORD') {
            errorMsg = 'Please enter your password.';
          } else if (body['message'] != null) {
            errorMsg = body['message'];
          }
        } catch (e) {
          // ignore parse error, use default errorMsg
        }

        if (mounted) {
          _showErrorDialog('Login Failed', errorMsg);
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBD2D01),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(
                              color: Color(0xFFF67F00),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFE5CC),
                            suffixIcon: const Icon(Icons.person, color: Color(0xFFBD2D01)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (value) => _email = value!.trim(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(
                              color: Color(0xFFF67F00),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFE5CC),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFFBD2D01),
                              ),
                              onPressed: () {
                                setState(() => _obscureText = !_obscureText);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSaved: (value) => _password = value ?? '',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
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
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
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
                      ],
                    ),
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
