import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstNameController = TextEditingController(text: 'Peter');
  final _lastNameController = TextEditingController(text: 'Parker');
  final _usernameController = TextEditingController(text: 'petetparker_05');
  final _emailController = TextEditingController(text: 'peterparker@gmail.com');
  final _passwordController = TextEditingController(text: '12345678');
  final _confirmPasswordController = TextEditingController(text: '12345678');

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
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
        child: SafeArea(
          child: Column(
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
                      "Profile",
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFFFB9933),
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : null,
                              child: _profileImage == null
                                  ? const Icon(Icons.person, size: 48, color: Colors.white)
                                  : null,
                            ),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(1, 2),
                                    )
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.edit, size: 16, color: Color(0xFFBD2D01)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(controller: _firstNameController, label: 'First Name'),
                        _buildTextField(controller: _lastNameController, label: 'Last Name'),
                        _buildTextField(controller: _usernameController, label: 'Username'),
                        _buildTextField(controller: _emailController, label: 'Email', enabled: false),

                        _buildPasswordField(
                          controller: _passwordController,
                          label: 'Password',
                          visible: _showPassword,
                          toggle: () => setState(() => _showPassword = !_showPassword),
                        ),

                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          visible: _showConfirmPassword,
                          toggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                        ),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Successfully updated'),
                                  duration: Duration(seconds: 1),
                                ),
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
                                  'Update',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(color: Color(0xFFBD2D01)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFF67F00)),
          filled: true,
          fillColor: const Color(0xFFFFE5CC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback toggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        obscureText: !visible,
        style: const TextStyle(color: Color(0xFFBD2D01)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFF67F00)),
          suffixIcon: IconButton(
            icon: Icon(
              visible ? Icons.visibility : Icons.visibility_off,
              color: Color(0xFFBD2D01),
            ),
            onPressed: toggle,
          ),
          filled: true,
          fillColor: const Color(0xFFFFE5CC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
