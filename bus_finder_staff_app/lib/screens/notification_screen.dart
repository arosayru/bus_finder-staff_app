import 'package:flutter/material.dart';
import 'dart:async';
import '/service/notification_service.dart'; // Update path as needed

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final int currentIndex = 2;
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  bool _isConnected = false;
  List<NotificationModel> _notifications = [];
  String _selectedFilter = 'all';

  late StreamSubscription<NotificationModel> _notificationSubscription;
  late StreamSubscription<bool> _connectionSubscription;
  late StreamSubscription<List<NotificationModel>> _notificationListSubscription;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get staff ID from your authentication/storage system
      String? staffId = await _getStaffId(); // Implement this method based on your auth system

      // Initialize the notification service
      await _notificationService.initialize(staffId: staffId);

      // Set up stream subscriptions
      _setupStreamSubscriptions();

      // Update initial state
      setState(() {
        _isConnected = _notificationService.isConnected;
        _notifications = _notificationService.notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing notifications: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showErrorSnackBar('Failed to initialize notifications: ${e.toString()}');
      }
    }
  }

  Future<String?> _getStaffId() async {
    // TODO: Implement this based on your authentication system
    // This could come from SharedPreferences, secure storage, or your auth service
    // For example:
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getString('staffId');

    // For now, return a dummy value - replace with actual implementation
    return "1"; // Replace with actual staff ID retrieval
  }

  void _setupStreamSubscriptions() {
    // Listen for new notifications
    _notificationSubscription = _notificationService.notificationStream.listen(
          (notification) {
        if (mounted) {
          _showNotificationSnackBar(notification);
        }
      },
      onError: (error) {
        print('Notification stream error: $error');
      },
    );

    // Listen for connection status changes
    _connectionSubscription = _notificationService.connectionStatusStream.listen(
          (isConnected) {
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
          });
        }
      },
      onError: (error) {
        print('Connection status stream error: $error');
      },
    );

    // Listen for notification list updates
    _notificationListSubscription = _notificationService.notificationListStream.listen(
          (notifications) {
        if (mounted) {
          setState(() {
            _notifications = notifications;
          });
        }
      },
      onError: (error) {
        print('Notification list stream error: $error');
      },
    );
  }

  void _showNotificationSnackBar(NotificationModel notification) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${notification.title}: ${notification.description}"),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: "View",
            onPressed: () {
              // Scroll to top to show the new notification
            },
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _dismissNotification(int index) async {
    try {
      await _notificationService.removeNotification(index);
    } catch (e) {
      print('Error dismissing notification: $e');
      _showErrorSnackBar('Failed to dismiss notification');
    }
  }

  Future<void> _markAsRead(int index) async {
    try {
      await _notificationService.markAsRead(index);
    } catch (e) {
      print('Error marking notification as read: $e');
      _showErrorSnackBar('Failed to mark notification as read');
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.refresh();
    } catch (e) {
      print('Error refreshing notifications: $e');
      _showErrorSnackBar('Failed to refresh notifications');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reconnect() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.reconnect();
      _showSuccessSnackBar('Reconnected successfully');
    } catch (e) {
      print('Error reconnecting: $e');
      _showErrorSnackBar('Failed to reconnect');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await _notificationService.clearAll();
      _showSuccessSnackBar('All notifications cleared');
    } catch (e) {
      print('Error clearing notifications: $e');
      _showErrorSnackBar('Failed to clear notifications');
    }
  }

  List<NotificationModel> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'emergency':
        return _notifications.where((n) => n.type.toLowerCase() == 'emergency').toList();
      case 'shift':
        return _notifications.where((n) =>
        n.type.toLowerCase().contains('shift') ||
            n.type.toLowerCase() == 'starts' ||
            n.type.toLowerCase() == 'ends').toList();
      case 'feedback':
        return _notifications.where((n) => n.type.toLowerCase() == 'feedback').toList();
      case 'all':
      default:
        return _notifications;
    }
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    _connectionSubscription.cancel();
    _notificationListSubscription.cancel();
    // Don't dispose the service here as it might be used elsewhere
    // _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
            width: double.infinity,
            color: const Color(0xFFFB9933),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                  },
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Notifications",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Connection status indicator with tap to reconnect
                GestureDetector(
                  onTap: !_isConnected ? _reconnect : null,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isConnected ? Colors.green : Colors.red,
                      border: !_isConnected ? Border.all(color: Colors.white, width: 1) : null,
                    ),
                    child: Icon(
                      _isConnected ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _refreshNotifications,
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
                const SizedBox(width: 8),
                if (_notifications.isNotEmpty)
                  GestureDetector(
                    onTap: _clearAllNotifications,
                    child: const Icon(Icons.clear_all, color: Colors.white),
                  ),
              ],
            ),
          ),

          // Filter buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                _buildFilterButton('All', 'all'),
                _buildFilterButton('Emergency', 'emergency'),
                _buildFilterButton('Shift', 'shift'),
                _buildFilterButton('Feedback', 'feedback'),
              ],
            ),
          ),

          // Connection status banner
          if (!_isConnected && !_isLoading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connection lost. Tap the icon above to reconnect.',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          if (!_isConnected && !_isLoading) const SizedBox(height: 16),

          // Notification Cards
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredNotifications.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredNotifications.length,
                itemBuilder: (context, index) {
                  final notification = filteredNotifications[index];
                  final originalIndex = _notifications.indexOf(notification);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? const Color(0xFFE0E0E0)
                          : const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _markAsRead(originalIndex),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _getNotificationIcon(notification.type),
                                  size: 28,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification.title.isEmpty
                                            ? _getDefaultTitle(notification.type)
                                            : notification.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (notification.routeNo.isNotEmpty)
                                        Text(
                                          notification.routeNo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      if (notification.subject.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Subject: ${notification.subject}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      if (notification.description.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            notification.description,
                                            style: const TextStyle(color: Colors.black),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Date: ${notification.date}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Time: ${notification.time}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _dismissNotification(originalIndex),
                            child: const Icon(Icons.close, size: 16, color: Colors.black),
                          ),
                        ),
                        if (!notification.isRead)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFB9933) : Colors.white,
          border: Border.all(
            color: const Color(0xFFFB9933),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFFB9933),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _getDefaultTitle(String type) {
    switch (type.toLowerCase()) {
      case 'feedback':
        return 'Passenger Feedback';
      case 'emergency':
        return 'Emergency Alert';
      case 'shift_assign':
      case 'shift_assignment':
        return 'Shift Assignment';
      case 'starts':
        return 'Shift Started';
      case 'ends':
        return 'Shift Ended';
      default:
        return 'Notification';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'feedback':
        return Icons.feedback;
      case 'emergency':
        return Icons.warning;
      case 'shift_assign':
      case 'shift_assignment':
      case 'starts':
      case 'ends':
        return Icons.schedule;
      case 'general':
      default:
        return Icons.notifications;
    }
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final icons = [Icons.home, Icons.location_on_outlined, Icons.notifications_none, Icons.grid_view];
    final routes = ['/dashboard', 'live-map', 'notification', 'more'];

    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(0, -5), blurRadius: 6)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              return GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, routes[index], (r) => false),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4))
                  ]),
                  child: Icon(icons[index], color: const Color(0xFFCF4602)),
                ),
              );
            }),
            ),
        );
    }
}