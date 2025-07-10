import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../user_service.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstNameController = TextEditingController(text: 'Peter');
  final _lastNameController = TextEditingController(text: 'Parker');
  final _emailController = TextEditingController(text: 'peterparker@gmail.com');
  final _passwordController = TextEditingController(text: '12345678');
  final _confirmPasswordController = TextEditingController(text: '12345678');

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  File? _profileImage;
  bool _isUploading = false;
  bool _isProfileLoading = false;
  // Separate loading state for profile picture

  // Store original values for comparison
  String? _originalFirstName;
  String? _originalLastName;
  String? _originalEmail;
  String? _profilePictureUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchAndSetProfileData();
  }

  Future<String?> _getStaffIdByEmail(String email) async {
    final idUrl = Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/Staff/get-id-by-email/$email');
    final idResponse = await http.get(idUrl);
    if (idResponse.statusCode == 200) {
      final idData = jsonDecode(idResponse.body);
      return idData['staffId']?.toString() ?? idData['StaffID']?.toString();
    }
    return null;
  }

  Future<void> _fetchAndSetProfileData() async {
    setState(() => _isProfileLoading = true);
    try {
      final email = await UserService.getStaffEmail();
      if (email != null && email.isNotEmpty && email != 'N/A') {
        final staffId = await _getStaffIdByEmail(email);
        if (staffId != null && staffId.isNotEmpty) {
          final detailsUrl = Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/Staff/$staffId');
          final detailsResponse = await http.get(detailsUrl);
          if (detailsResponse.statusCode == 200) {
            final detailsData = jsonDecode(detailsResponse.body);
            final firstName = detailsData['firstName']?.toString() ?? detailsData['FirstName']?.toString() ?? '';
            final lastName = detailsData['lastName']?.toString() ?? detailsData['LastName']?.toString() ?? '';
            final emailVal = detailsData['email']?.toString() ?? detailsData['Email']?.toString() ?? '';
            final profilePicture = detailsData['profilePicture']?.toString() ?? '';
            setState(() {
              _firstNameController.text = firstName;
              _lastNameController.text = lastName;
              _emailController.text = emailVal;
              _originalFirstName = firstName;
              _originalLastName = lastName;
              _originalEmail = emailVal;
              _profilePictureUrl = profilePicture;
            });
          }
        }
      }
    } catch (e) {
      // Optionally handle error
    }
    setState(() => _isProfileLoading = false);
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _updateProfileDetails() async {
    print('DEBUG: Starting profile update process');
    setState(() => _isUploading = true);
    try {
      print('DEBUG: Fetching staff email...');
      final email = await UserService.getStaffEmail();
      print('DEBUG: Staff email retrieved: $email');

      if (email == null || email.isEmpty || email == 'N/A') {
        print('DEBUG: Staff email is null, empty, or N/A');
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff email not found'), duration: Duration(seconds: 2)),
        );
        return;
      }

      print('DEBUG: Fetching staff ID by email...');
      final staffId = await _getStaffIdByEmail(email);
      print('DEBUG: Staff ID retrieved: $staffId');

      if (staffId == null || staffId.isEmpty) {
        print('DEBUG: Failed to get staff ID by email');
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get staff ID'), duration: Duration(seconds: 2)),
        );
        return;
      }
      print('DEBUG: Staff ID retrieved: $staffId');

      if (staffId == null || staffId.isEmpty || staffId == 'N/A') {
        print('DEBUG: Staff ID is null, empty, or N/A');
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff ID not found'), duration: Duration(seconds: 2)),
        );
        return;
      }

      // Fetch current staff data to preserve unchanged fields
      print('DEBUG: Fetching current staff data...');
      final detailsUrl = Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/Staff/$staffId');
      final detailsResponse = await http.get(detailsUrl);
      print('DEBUG: Staff details response status: ${detailsResponse.statusCode}');
      print('DEBUG: Staff details response body: ${detailsResponse.body}');

      if (detailsResponse.statusCode != 200) {
        print('DEBUG: Failed to get current staff data');
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get current staff data: ${detailsResponse.body}'), duration: const Duration(seconds: 2)),
        );
        return;
      }

      final currentStaffData = jsonDecode(detailsResponse.body);
      print('DEBUG: Current staff data: $currentStaffData');

      // Compare fields and prepare complete update data
      print('DEBUG: Comparing field values...');
      print('DEBUG: Original firstName: $_originalFirstName, Current: ${_firstNameController.text.trim()}');
      print('DEBUG: Original lastName: $_originalLastName, Current: ${_lastNameController.text.trim()}');
      print('DEBUG: Original email: $_originalEmail, Current: ${_emailController.text.trim()}');

      // Start with current staff data and update only changed fields
      final Map<String, dynamic> completeUpdateData = Map<String, dynamic>.from(currentStaffData);

      bool hasChanges = false;
      if (_firstNameController.text.trim() != (_originalFirstName ?? '')) {
        completeUpdateData['firstName'] = _firstNameController.text.trim();
        print('DEBUG: firstName will be updated');
        hasChanges = true;
      }
      if (_lastNameController.text.trim() != (_originalLastName ?? '')) {
        completeUpdateData['lastName'] = _lastNameController.text.trim();
        print('DEBUG: lastName will be updated');
        hasChanges = true;
      }
      if (_emailController.text.trim() != (_originalEmail ?? '')) {
        completeUpdateData['email'] = _emailController.text.trim();
        print('DEBUG: email will be updated');
        hasChanges = true;
      }

      print('DEBUG: Complete update data: $completeUpdateData');

      if (!hasChanges) {
        print('DEBUG: No fields to update');
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes to update.'), duration: Duration(seconds: 2)),
        );
        return;
      }

      final uri = Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/Staff/$staffId');
      final body = jsonEncode(completeUpdateData);
      print('DEBUG: Making PUT request to: $uri');
      print('DEBUG: Request body: $body');

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      setState(() => _isUploading = false);

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('DEBUG: Profile update successful (status: ${response.statusCode})');
        // Update originals to new values
        setState(() {
          _originalFirstName = _firstNameController.text.trim();
          _originalLastName = _lastNameController.text.trim();
          _originalEmail = _emailController.text.trim();
        });
        print('DEBUG: Original values updated');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), duration: Duration(seconds: 2)),
        );
      } else {
        print('DEBUG: Profile update failed with status: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${response.body}'), duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      print('DEBUG: Exception occurred during profile update: $e');
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<bool> _uploadProfilePicture(String staffId) async {
    if (_profileImage == null) return false;
    try {
      final uri = Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/Staff/$staffId/update-profile-picture');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('profilePicture', _profileImage!.path));
      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('DEBUG: Profile picture uploaded successfully');
        return true;
      } else {
        print('DEBUG: Failed to upload profile picture: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('DEBUG: Exception during profile picture upload: $e');
      return false;
    }
  }

  Future<void> _updateProfileDetailsAndPicture() async {
    setState(() => _isUploading = true);
    try {
      final email = await UserService.getStaffEmail();
      if (email == null || email.isEmpty || email == 'N/A') {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff email not found'), duration: Duration(seconds: 2)),
        );
        return;
      }

      final staffId = await _getStaffIdByEmail(email);
      if (staffId == null || staffId.isEmpty || staffId == 'N/A') {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff ID not found'), duration: Duration(seconds: 2)),
        );
        return;
      }

      // Update profile details first
      await _updateProfileDetails();

      // Upload profile picture if selected
      if (_profileImage != null) {
        await _uploadProfilePicture(staffId);
      }

      // Refresh profile data to show updated picture
      await _fetchAndSetProfileData();
    } catch (e) {
      print('DEBUG: Exception in _updateProfileDetailsAndPicture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), duration: const Duration(seconds: 2)),
      );
    }
    setState(() => _isUploading = false);
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
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  color: Colors.black54,
                ),
              ),
              if (_isProfileLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
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
                                    : (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty)
                                    ? NetworkImage(_profilePictureUrl!)
                                    : null,
                                child: (_profileImage == null && (_profilePictureUrl == null || _profilePictureUrl!.isEmpty))
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
                              onPressed: _isUploading ? null : _updateProfileDetailsAndPicture,
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
                                  child: _isUploading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Text(
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




