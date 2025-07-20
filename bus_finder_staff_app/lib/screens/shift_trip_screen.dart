import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';


class ShiftTripScreen extends StatefulWidget {
  final Map<String, String>? shiftData;

  const ShiftTripScreen({super.key, this.shiftData});

  @override
  State<ShiftTripScreen> createState() => _ShiftTripScreenState();
}

class _ShiftTripScreenState extends State<ShiftTripScreen> {
  final List<String> activities = [];

  // Loading states for each button
  bool _isLoadingStartTrip = false;
  bool _isLoadingEndTrip = false;
  bool _isLoadingInterval = false;

  // Use shift data if available, otherwise load from API
  String? get _effectiveNumberPlate {
    if (widget.shiftData?['numberPlate'] != null && widget.shiftData!['numberPlate'] != 'N/A') {
      return widget.shiftData!['numberPlate'];
    }
    return null;
  }

  String? get _effectiveRouteNumber {
    if (widget.shiftData?['routeNumber'] != null && widget.shiftData!['routeNumber'] != 'N/A') {
      return widget.shiftData!['routeNumber'];
    }
    return null;
  }

  String? get _effectiveDisplayRouteName {
    if (widget.shiftData?['displayRouteName'] != null && widget.shiftData!['displayRouteName'] != 'N/A') {
      return widget.shiftData!['displayRouteName'];
    }
    return null;
  }

  static const String baseUrl = "https://bus-finder-sl-a7c6a549fbb1.herokuapp.com";

  @override
  void initState() {
    super.initState();
    // Only load bus details if we don't have shift data or if shift data is incomplete
    if (_effectiveNumberPlate == null) {
      _loadBusDetailsFromAPI();
    }
  }

  // Fallback method to load from API if shift data is not available
  Future<void> _loadBusDetailsFromAPI() async {
    // This is the existing API loading logic as fallback
    // Implementation would be similar to the original but simplified
    print('Loading bus details from API as fallback...');
    // Add your existing API loading logic here if needed
  }

  // Send notification to admin - uses shift data number plate if available
  Future<void> _sendNotification(String action, String endpoint) async {
    print('\n=== SENDING SHIFT NOTIFICATION ===');
    print('DEBUG: Action: $action');
    print('DEBUG: Endpoint: $endpoint');

    final numberPlateToSend = _effectiveNumberPlate;

    if (numberPlateToSend == null || numberPlateToSend.isEmpty) {
      print('DEBUG: ❌ CRITICAL ERROR: No number plate available');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Bus information is not available.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    print('DEBUG: ✅ Using number plate: $numberPlateToSend');

    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestBody = json.encode(numberPlateToSend);
      print('DEBUG: Request Body: $requestBody');

      final response = await http.post(
        uri,
        headers: headers,
        body: requestBody,
      ).timeout(const Duration(seconds: 15));

      print('DEBUG: Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$action notification sent for bus $numberPlateToSend'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        String errorMessage = 'Failed to send $action notification (Status: ${response.statusCode})';
        try {
          final errorData = json.decode(response.body);
          if (errorData['title'] != null) {
            errorMessage = errorData['title'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          print('DEBUG: Could not parse error response: $e');
        }
        throw Exception(errorMessage);
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request timeout. Please check your internet connection and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      rethrow;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending $action notification: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      rethrow;
    }
  }

  void _addActivity(String label, String action, String endpoint) async {
    setState(() {
      switch (action) {
        case 'Start Trip':
          _isLoadingStartTrip = true;
          break;
        case 'End Trip':
          _isLoadingEndTrip = true;
          break;
        case 'Interval':
          _isLoadingInterval = true;
          break;
      }
    });

    try {
      await _sendNotification(action, endpoint);

      final now = DateTime.now();
      final time = "${now.hour % 12 == 0 ? 12 : now.hour % 12}.${now.minute.toString().padLeft(2, '0')}${now.hour >= 12 ? 'p.m' : 'a.m'}";
      final date = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

      // Create detailed activity log with shift information
      String activityDetail = '';

      if (_effectiveDisplayRouteName != null && _effectiveDisplayRouteName != 'N/A') {
        activityDetail += "Route: $_effectiveDisplayRouteName\n";
      } else if (_effectiveRouteNumber != null && _effectiveRouteNumber != 'N/A') {
        activityDetail += "Route No: $_effectiveRouteNumber\n";
      }

      if (_effectiveNumberPlate != null) {
        activityDetail += "Bus: $_effectiveNumberPlate\n";
      }

      // Add direction-specific timing if available
      if (widget.shiftData != null) {
        if (widget.shiftData!['normalStartTime'] != 'N/A' && widget.shiftData!['normalEndTime'] != 'N/A') {
          activityDetail += "Normal: ${widget.shiftData!['normalStartTime']} - ${widget.shiftData!['normalEndTime']}\n";
        }
        if (widget.shiftData!['reverseStartTime'] != 'N/A' && widget.shiftData!['reverseEndTime'] != 'N/A') {
          activityDetail += "Reverse: ${widget.shiftData!['reverseStartTime']} - ${widget.shiftData!['reverseEndTime']}\n";
        }
      }

      activityDetail += "Date: $date\n$label at $time";

      setState(() {
        activities.insert(0, activityDetail);
      });

    } catch (e) {
      print('DEBUG: Failed to send notification: $e');
    } finally {
      setState(() {
        _isLoadingStartTrip = false;
        _isLoadingEndTrip = false;
        _isLoadingInterval = false;
      });
    }
  }

  Widget _buildStyledButton(String text, Color color, VoidCallback? onPressed, {bool isWide = false, bool isLoading = false}) {
    return SizedBox(
      width: isWide ? double.infinity : null,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey.shade300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: onPressed != null ? 3 : 0,
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: onPressed != null ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasShiftData = widget.shiftData != null && _effectiveNumberPlate != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
            width: double.infinity,
            color: const Color(0xFFFB9933),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Shift Tracker",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Shift Details Card - Show shift information in an organized way
          if (hasShiftData)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route information
                    if (_effectiveDisplayRouteName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFB9933).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFB9933).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.route, color: Color(0xFFFB9933), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _effectiveDisplayRouteName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFFFB9933),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Bus details
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, color: Color(0xFFFB9933), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_effectiveNumberPlate != null)
                                _detail("Bus Number:", _effectiveNumberPlate!),

                              // Normal direction timing
                              if (widget.shiftData?['normalStartTime'] != 'N/A' ||
                                  widget.shiftData?['normalEndTime'] != 'N/A') ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Normal Direction:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFFFB9933),
                                  ),
                                ),
                                if (widget.shiftData!['normalDate'] != 'N/A')
                                  _detail("Date:", widget.shiftData!['normalDate']!),
                                if (widget.shiftData!['normalStartTime'] != 'N/A')
                                  _detail("Start:", widget.shiftData!['normalStartTime']!),
                                if (widget.shiftData!['normalEndTime'] != 'N/A')
                                  _detail("End:", widget.shiftData!['normalEndTime']!),
                              ],

                              // Reverse direction timing
                              if (widget.shiftData?['reverseStartTime'] != 'N/A' ||
                                  widget.shiftData?['reverseEndTime'] != 'N/A') ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Reverse Direction:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFFFB9933),
                                  ),
                                ),
                                if (widget.shiftData!['reverseDate'] != 'N/A')
                                  _detail("Date:", widget.shiftData!['reverseDate']!),
                                if (widget.shiftData!['reverseStartTime'] != 'N/A')
                                  _detail("Start:", widget.shiftData!['reverseStartTime']!),
                                if (widget.shiftData!['reverseEndTime'] != 'N/A')
                                  _detail("End:", widget.shiftData!['reverseEndTime']!),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Loading state for when no shift data is available
          if (!hasShiftData)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No shift details available. Please select a shift from the tracker.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Action Buttons - Enable when shift data is available
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStyledButton(
                    "Start Trip",
                    const Color(0xFF23C51E),
                    (_isLoadingStartTrip || !hasShiftData) ? null : () => _addActivity(
                        "Starts Trip",
                        "Start Trip",
                        "/api/BusShift/notify-shift-start"
                    ),
                    isLoading: _isLoadingStartTrip,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildStyledButton(
                    "End Trip",
                    const Color(0xFFC51E1E),
                    (_isLoadingEndTrip || !hasShiftData) ? null : () => _addActivity(
                        "Ends Trip",
                        "End Trip",
                        "/api/BusShift/notify-shift-end"
                    ),
                    isLoading: _isLoadingEndTrip,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStyledButton(
              "Interval",
              const Color(0xFF1263CE),
              (_isLoadingInterval || !hasShiftData) ? null : () => _addActivity(
                  "Interval",
                  "Interval",
                  "/api/BusShift/notify-shift-interval"
              ),
              isWide: true,
              isLoading: _isLoadingInterval,
            ),
          ),
          const SizedBox(height: 20),

          // Activities section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF67F00),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: const Text(
                "Activities",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFF67F00), width: 2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: activities.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No activities yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the buttons above to start tracking',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => Container(
                    height: 1,
                    color: const Color(0xFFF5B27E),
                  ),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      color: const Color(0xFFFFF1E6),
                      child: Text(
                        activities[index],
                        style: const TextStyle(
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}