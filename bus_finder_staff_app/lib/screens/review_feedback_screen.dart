import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReviewFeedbackScreen extends StatefulWidget {
  const ReviewFeedbackScreen({super.key});

  @override
  State<ReviewFeedbackScreen> createState() => _ReviewFeedbackScreenState();
}

class _ReviewFeedbackScreenState extends State<ReviewFeedbackScreen> {
  List<Map<String, String>> feedbackList = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> fetchFeedbacks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse('https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api/Feedback');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Debug: Print response details
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        if (responseBody.isEmpty) {
          setState(() {
            feedbackList = [];
            isLoading = false;
          });
          return;
        }

        final dynamic decodedData = json.decode(responseBody);
        print('Decoded Data Type: ${decodedData.runtimeType}');
        print('Decoded Data: $decodedData');

        // Handle different response structures
        List<dynamic> data;
        if (decodedData is List) {
          data = decodedData;
        } else if (decodedData is Map) {
          // If response is wrapped in an object, try to find the array
          if (decodedData.containsKey('data')) {
            data = decodedData['data'] as List<dynamic>;
          } else if (decodedData.containsKey('feedbacks')) {
            data = decodedData['feedbacks'] as List<dynamic>;
          } else if (decodedData.containsKey('feedback')) {
            data = decodedData['feedback'] as List<dynamic>;
          } else {
            // If it's a single object, wrap it in a list
            data = [decodedData];
          }
        } else {
          throw Exception('Unexpected response format');
        }

        setState(() {
          feedbackList = data.map<Map<String, String>>((item) {
            print('Processing item: $item');
            print('Item type: ${item.runtimeType}');

            if (item is Map<String, dynamic>) {
              // Print all keys in the item to debug field names
              print('Available keys: ${item.keys.toList()}');

              // Try different possible field names
              String name = '';
              String feedback = '';

              // Common field name variations for name
              if (item.containsKey('name')) {
                name = item['name']?.toString() ?? '';
              } else if (item.containsKey('Name')) {
                name = item['Name']?.toString() ?? '';
              } else if (item.containsKey('userName')) {
                name = item['userName']?.toString() ?? '';
              } else if (item.containsKey('user_name')) {
                name = item['user_name']?.toString() ?? '';
              } else if (item.containsKey('username')) {
                name = item['username']?.toString() ?? '';
              } else if (item.containsKey('customerName')) {
                name = item['customerName']?.toString() ?? '';
              } else if (item.containsKey('customer_name')) {
                name = item['customer_name']?.toString() ?? '';
              }

              // Common field name variations for feedback
              if (item.containsKey('feedback')) {
                feedback = item['feedback']?.toString() ?? '';
              } else if (item.containsKey('Feedback')) {
                feedback = item['Feedback']?.toString() ?? '';
              } else if (item.containsKey('message')) {
                feedback = item['message']?.toString() ?? '';
              } else if (item.containsKey('Message')) {
                feedback = item['Message']?.toString() ?? '';
              } else if (item.containsKey('comment')) {
                feedback = item['comment']?.toString() ?? '';
              } else if (item.containsKey('Comment')) {
                feedback = item['Comment']?.toString() ?? '';
              } else if (item.containsKey('review')) {
                feedback = item['review']?.toString() ?? '';
              } else if (item.containsKey('Review')) {
                feedback = item['Review']?.toString() ?? '';
              }

              print('Extracted - Name: "$name", Feedback: "$feedback"');

              return {
                "name": name.isNotEmpty ? name : "Unknown",
                "feedback": feedback.isNotEmpty ? feedback : "No feedback provided",
              };
            } else {
              print('Item is not a Map<String, dynamic>');
              return {
                "name": "Unknown",
                "feedback": "Invalid data format",
              };
            }
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load feedbacks: ${response.statusCode}\nResponse: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching feedbacks: $e';
        isLoading = false;
      });
      print('Exception details: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFeedbacks();
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
              // Header
              Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Review Feedback",
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
              const SizedBox(height: 10),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (isLoading) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Loading feedback...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    }
                    if (errorMessage != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: fetchFeedbacks,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (feedbackList.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.feedback_outlined, color: Colors.white, size: 48),
                            SizedBox(height: 16),
                            Text(
                              'No feedbacks found.',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: fetchFeedbacks,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: feedbackList.length,
                        itemBuilder: (context, index) {
                          final feedback = feedbackList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: Color(0xFFBD2D01),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        feedback["name"] ?? "Unknown",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFBD2D01),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  feedback["feedback"] ?? "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}