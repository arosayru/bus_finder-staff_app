import 'dart:async';
import 'dart:convert';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:signalr_netcore/ihub_protocol.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final String routeNo;
  final String date;
  final String time;
  final String subject;
  final String message;
  final bool isRead;
  final String staffId;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.routeNo,
    required this.date,
    required this.time,
    this.subject = '',
    this.message = '',
    required this.isRead,
    required this.staffId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? json['message']?.toString() ?? '',
      routeNo: json['routeNo']?.toString() ?? json['route']?.toString() ?? '',
      date: json['date']?.toString() ?? _formatDate(DateTime.now()),
      time: json['time']?.toString() ?? _formatTime(DateTime.now()),
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] ?? json['read'] ?? false,
      staffId: json['staffId']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'routeNo': routeNo,
      'date': date,
      'time': time,
      'subject': subject,
      'message': message,
      'isRead': isRead,
      'staffId': staffId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? routeNo,
    String? date,
    String? time,
    String? subject,
    String? message,
    bool? isRead,
    String? staffId,
    DateTime? timestamp,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      routeNo: routeNo ?? this.routeNo,
      date: date ?? this.date,
      time: time ?? this.time,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      staffId: staffId ?? this.staffId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour == 0 ? 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  HubConnection? _hubConnection;
  List<NotificationModel> _notifications = [];
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentStaffId;
  String? _userToken;

  // Stream controllers
  final StreamController<NotificationModel> _notificationController =
  StreamController<NotificationModel>.broadcast();
  final StreamController<bool> _connectionController =
  StreamController<bool>.broadcast();
  final StreamController<List<NotificationModel>> _notificationListController =
  StreamController<List<NotificationModel>>.broadcast();

  // Getters
  Stream<NotificationModel> get notificationStream => _notificationController.stream;
  Stream<bool> get connectionStatusStream => _connectionController.stream;
  Stream<List<NotificationModel>> get notificationListStream => _notificationListController.stream;
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isConnected => _isConnected;

  // Configuration - Updated URL to match the working version
  static const String _hubUrl = 'https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/notificationhub';
  static const String _notificationsKey = 'notifications';

  Future<void> initialize({String? staffId}) async {
    print('🚀 NotificationService: Starting initialization...');
    try {
      _currentStaffId = staffId ?? await _getStoredStaffId();

      if (_currentStaffId == null) {
        throw Exception('Staff ID is required for notifications');
      }

      // Load user token
      await _loadUserToken();

      // Load cached notifications
      await _loadCachedNotifications();

      // Initialize SignalR connection with improved method
      await _initializeSignalR();

      print('✅ NotificationService: Initialized successfully for staff: $_currentStaffId');
    } catch (e) {
      print('❌ NotificationService: Failed to initialize: $e');
      rethrow;
    }
  }

  Future<String?> _getStoredStaffId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('staffId') ??
          prefs.getString('staff_id') ??
          prefs.getString('userId') ??
          prefs.getString('user_id') ??
          prefs.getString('driverId') ??
          prefs.getString('driver_id');
    } catch (e) {
      print('⚠ NotificationService: Error getting stored staff ID: $e');
      return null;
    }
  }

  Future<void> _loadUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userToken = prefs.getString('authToken') ??
          prefs.getString('auth_token') ??
          prefs.getString('accessToken') ??
          prefs.getString('access_token') ??
          prefs.getString('token');

      print('🔑 NotificationService: User token loaded: ${_userToken != null ? 'Present (${_userToken!.length} chars)' : 'Missing'}');
    } catch (e) {
      print('⚠ NotificationService: Error loading user token: $e');
    }
  }

  // Get current date and time formatted consistently
  Map<String, String> _getCurrentDateTime() {
    final now = DateTime.now();
    final date = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final time = "$hour:$minute:$second $period";

    return {
      'date': date,
      'time': time,
    };
  }

  // Improved SignalR initialization method from the second code
  Future<void> _initializeSignalR() async {
    if (_isConnecting || _isConnected) {
      print('⏳ NotificationService: SignalR already connecting or connected');
      return;
    }

    print('🔌 NotificationService: Initializing SignalR connection...');
    _isConnecting = true;

    try {
      // Create connection exactly like the working version
      final httpConnectionOptions = HttpConnectionOptions(
        skipNegotiation: true, // IMPORTANT: Same as React
        transport: HttpTransportType.WebSockets, // IMPORTANT: Same as React
        logMessageContent: true, // Enable for debugging
      );

      // Add auth header if token is available
      if (_userToken != null && _userToken!.isNotEmpty) {
        httpConnectionOptions.headers = MessageHeaders();
        httpConnectionOptions.headers!.setHeaderValue("Authorization", "Bearer $_userToken");
        print('🔐 NotificationService: Added Authorization header');
      }

      // Build connection like working version
      _hubConnection = HubConnectionBuilder()
          .withUrl(_hubUrl, options: httpConnectionOptions)
          .withAutomaticReconnect(retryDelays: [0, 2000, 10000, 30000])
          .build();

      print('🏗 NotificationService: HubConnection built successfully');

      // Set up event handlers BEFORE starting connection
      _setupSignalRHandlers();
      print('📡 NotificationService: Event handlers set up');

      // Start connection
      print('🚀 NotificationService: Starting SignalR connection to: $_hubUrl');
      await _hubConnection!.start();

      _isConnected = true;
      _isConnecting = false;
      _updateConnectionStatus(true);

      print('✅ NotificationService: SignalR connected successfully!');


    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _updateConnectionStatus(false);
      print('❌ NotificationService: SignalR connection error: $e');
      print('🔍 NotificationService: Connection details - URL: $_hubUrl');
      print('🔍 NotificationService: Connection state: ${_hubConnection?.state}');
      rethrow;
    }
  }

  // Enhanced SignalR event handlers matching the working version
  void _setupSignalRHandlers() {
    print('📡 NotificationService: Setting up SignalR event handlers...');

    if (_hubConnection == null) {
      print('❌ NotificationService: Cannot setup handlers - hubConnection is null');
      return;
    }

    // Listen for BusSOS (emergency) - exact same as working version
    _hubConnection!.on("BusSOS", (arguments) {
      print('🚨 NotificationService: Received BusSOS notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleEmergencyNotification(arguments[0]);
      }
    });

    // Listen for FeedbackReceived - exact same as working version
    _hubConnection!.on("FeedbackReceived", (arguments) {
      print('💬 NotificationService: Received FeedbackReceived notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleFeedbackNotification(arguments[0]);
      }
    });

    // Listen for ShiftStarted - exact same as working version
    _hubConnection!.on("ShiftStarted", (arguments) {
      print('▶ NotificationService: Received ShiftStarted notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleShiftStartedNotification(arguments[0]);
      }
    });

    // Listen for ShiftInterval - exact same as working version
    _hubConnection!.on("ShiftInterval", (arguments) {
      print('⏸ NotificationService: Received ShiftInterval notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleShiftIntervalNotification(arguments[0]);
      }
    });

    // Listen for ShiftEnded - exact same as working version
    _hubConnection!.on("ShiftEnded", (arguments) {
      print('⏹ NotificationService: Received ShiftEnded notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleShiftEndedNotification(arguments[0]);
      }
    });

    // Keep original generic handlers for backward compatibility
    _hubConnection!.on('ReceiveNotification', (List<Object?>? arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final data = arguments[0];
          if (data is Map<String, dynamic>) {
            _handleNewNotification(data);
          } else if (data is String) {
            final jsonData = json.decode(data);
            _handleNewNotification(jsonData);
          }
        } catch (e) {
          print('⚠ NotificationService: Error handling generic notification: $e');
        }
      }
    });

    _hubConnection!.on('ReceiveStaffNotification', (List<Object?>? arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final data = arguments[0];
          if (data is Map<String, dynamic>) {
            _handleNewNotification(data);
          } else if (data is String) {
            final jsonData = json.decode(data);
            _handleNewNotification(jsonData);
          }
        } catch (e) {
          print('⚠ NotificationService: Error handling staff notification: $e');
        }
      }
    });

    // Connection state change handlers
    _hubConnection!.onclose(({Exception? error}) {
      _isConnected = false;
      _updateConnectionStatus(false);
      print('🔌 NotificationService: SignalR connection closed: $error');
    });

    _hubConnection!.onreconnecting(({Exception? error}) {
      _isConnected = false;
      _updateConnectionStatus(false);
      print('🔄 NotificationService: SignalR reconnecting: $error');
    });

    _hubConnection!.onreconnected(({String? connectionId}) {
      _isConnected = true;
      _updateConnectionStatus(true);
      print('✅ NotificationService: SignalR reconnected with ID: $connectionId');
      // Rejoin staff group after reconnection
      if (_currentStaffId != null) {
        _hubConnection!.invoke('JoinStaffGroup', args: [?_currentStaffId]);
      }
    });

    print('✅ NotificationService: All event handlers set up successfully');
  }

  // Handle emergency notification (BusSOS)
  void _handleEmergencyNotification(dynamic message) {
    print('🚨 NotificationService: Processing emergency notification...');
    try {
      final dateTime = _getCurrentDateTime();
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "SOS Alert",
        description: message?.toString() ?? "Emergency alert received",
        routeNo: "Emergency",
        date: dateTime['date']!,
        time: dateTime['time']!,
        type: "emergency",
        isRead: false,
        staffId: _currentStaffId ?? '',
        message: message!.toString(),
      );

      _addNotification(notification);
      print('✅ NotificationService: Emergency notification processed');
    } catch (e) {
      print('❌ NotificationService: Error handling emergency notification: $e');
    }
  }

  // Handle feedback notification
  void _handleFeedbackNotification(dynamic message) {
    print('💬 NotificationService: Processing feedback notification...');
    try {
      final dateTime = _getCurrentDateTime();

      // Extract feedback text
      String feedbackText = "Feedback received";
      if (message is String) {
        if (message.contains(':')) {
          feedbackText = message.split(':')[1].trim();
        } else {
          feedbackText = message;
        }
      } else {
        feedbackText = message?.toString() ?? "Feedback received";
      }

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "New Feedback",
        description: feedbackText,
        routeNo: "",
        date: dateTime['date']!,
        time: dateTime['time']!,
        type: "feedback",
        isRead: false,
        staffId: _currentStaffId ?? '',
        subject: feedbackText,
        message: message!.toString(),
      );

      _addNotification(notification);
      print('✅ NotificationService: Feedback notification processed');
    } catch (e) {
      print('❌ NotificationService: Error handling feedback notification: $e');
    }
  }

  // Handle shift started notification
  void _handleShiftStartedNotification(dynamic message) {
    print('▶ NotificationService: Processing shift started notification...');
    try {
      final dateTime = _getCurrentDateTime();
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Shift Started",
        description: message?.toString() ?? "Your shift has started",
        routeNo: "Shift",
        date: dateTime['date']!,
        time: dateTime['time']!,
        type: "starts",
        isRead: false,
        staffId: _currentStaffId ?? '',
        message: message!.toString(),
      );

      _addNotification(notification);
      print('✅ NotificationService: Shift started notification processed');
    } catch (e) {
      print('❌ NotificationService: Error handling shift started notification: $e');
    }
  }

  // Handle shift interval notification
  void _handleShiftIntervalNotification(dynamic message) {
    print('⏸ NotificationService: Processing shift interval notification...');
    try {
      final dateTime = _getCurrentDateTime();
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Shift Interval",
        description: message?.toString() ?? "Shift interval notification",
        routeNo: "Shift",
        date: dateTime['date']!,
        time: dateTime['time']!,
        type: "starts",
        isRead: false,
        staffId: _currentStaffId ?? '',
        message: message!.toString(),
      );

      _addNotification(notification);
      print('✅ NotificationService: Shift interval notification processed');
    } catch (e) {
      print('❌ NotificationService: Error handling shift interval notification: $e');
    }
  }

  // Handle shift ended notification
  void _handleShiftEndedNotification(dynamic message) {
    print('⏹ NotificationService: Processing shift ended notification...');
    try {
      final dateTime = _getCurrentDateTime();
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Shift Ended",
        description: message?.toString() ?? "Your shift has ended",
        routeNo: "Shift",
        date: dateTime['date']!,
        time: dateTime['time']!,
        type: "ends",
        isRead: false,
        staffId: _currentStaffId ?? '',
        message: message!.toString(),
      );

      _addNotification(notification);
      print('✅ NotificationService: Shift ended notification processed');
    } catch (e) {
      print('❌ NotificationService: Error handling shift ended notification: $e');
    }
  }

  // Original generic notification handler
  void _handleNewNotification(Map<String, dynamic> data) {
    try {
      // Create notification model
      final notification = NotificationModel.fromJson({
        ...data,
        'staffId': _currentStaffId ?? '',
        'isRead': false,
      });

      _addNotification(notification);

      print('✅ NotificationService: Generic notification processed: ${notification.title}');
    } catch (e) {
      print('❌ NotificationService: Error processing generic notification: $e');
    }
  }

  // Add notification to list and emit events
  void _addNotification(NotificationModel notification) {
    print('📝 NotificationService: Adding new notification: ${notification.title}');
    _notifications.insert(0, notification);
    _saveNotificationsToCache();
    _notificationController.add(notification);
    _notificationListController.add(List.from(_notifications));
    print('✅ NotificationService: Notification added and broadcasted');
  }

  Future<void> _loadCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_notificationsKey);

      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        _notifications = jsonList
            .map((json) => NotificationModel.fromJson(json))
            .where((notification) => notification.staffId == _currentStaffId)
            .toList();

        // Sort by timestamp
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        _notificationListController.add(List.from(_notifications));
        print('📱 NotificationService: Loaded ${_notifications.length} cached notifications');
      }
    } catch (e) {
      print('❌ NotificationService: Error loading cached notifications: $e');
    }
  }

  Future<void> _saveNotificationsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, json.encode(jsonList));
    } catch (e) {
      print('❌ NotificationService: Error saving notifications to cache: $e');
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    _isConnected = isConnected;
    _connectionController.add(isConnected);
  }

  Future<void> markAsRead(int index) async {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotificationsToCache();
      _notificationListController.add(List.from(_notifications));
      print('✅ NotificationService: Marked notification at index $index as read');
    }
  }

  Future<void> removeNotification(int index) async {
    if (index >= 0 && index < _notifications.length) {
      final notification = _notifications[index];
      _notifications.removeAt(index);
      await _saveNotificationsToCache();
      _notificationListController.add(List.from(_notifications));
      print('✅ NotificationService: Removed notification: ${notification.title}');
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotificationsToCache();
    _notificationListController.add(List.from(_notifications));
    print('✅ NotificationService: Cleared all notifications');
  }

  Future<void> refresh() async {
    print('🔄 NotificationService: Refreshing...');
    try {
      if (!_isConnected) {
        await _initializeSignalR();
      } else {
        await _loadCachedNotifications();
        print('✅ NotificationService: Refreshed successfully');
      }
    } catch (e) {
      print('❌ NotificationService: Error refreshing: $e');
      rethrow;
    }
  }

  Future<void> reconnect() async {
    print('🔄 NotificationService: Reconnecting...');
    try {
      if (_isConnected) {
        await disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      await _initializeSignalR();
    } catch (e) {
      print('❌ NotificationService: Error reconnecting: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    print('🔌 NotificationService: Disconnecting...');
    try {
      if (_hubConnection != null && _isConnected) {
        await _hubConnection!.stop();
        _isConnected = false;
        _updateConnectionStatus(false);
        print('✅ NotificationService: Disconnected successfully');
      }
    } catch (e) {
      print('❌ NotificationService: Error disconnecting SignalR: $e');
    }
  }

  void dispose() {
    print('🗑 NotificationService: Disposing...');
    disconnect();
    _notificationController.close();
    _connectionController.close();
    _notificationListController.close();
    print('✅ NotificationService: Disposed successfully');
  }
}