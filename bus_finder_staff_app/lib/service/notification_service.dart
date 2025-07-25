import 'dart:async';
import 'dart:convert';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:signalr_netcore/ihub_protocol.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

  // Configuration
  static const String _hubUrl = 'https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/notificationhub';
  static const String _baseApiUrl = 'https://bus-finder-sl-a7c6a549fbb1.herokuapp.com/api';
  static const String _notificationsKey = 'notifications';

  // Shift message types that require filtering
  final Set<String> _shiftMessageTypes = {
    "ShiftCreated",
    "ShiftUpdated",
    "ShiftDeleted",
    "NormalShiftRemoved",
    "ReverseShiftRemoved"
  };

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

      // Initialize SignalR connection
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

  Future<void> _initializeSignalR() async {
    if (_isConnecting || _isConnected) {
      print('⏳ NotificationService: SignalR already connecting or connected');
      return;
    }

    print('🔌 NotificationService: Initializing SignalR connection...');
    _isConnecting = true;

    try {
      final httpConnectionOptions = HttpConnectionOptions(
        skipNegotiation: true,
        transport: HttpTransportType.WebSockets,
        logMessageContent: true,
      );

      if (_userToken != null && _userToken!.isNotEmpty) {
        httpConnectionOptions.headers = MessageHeaders();
        httpConnectionOptions.headers!.setHeaderValue("Authorization", "Bearer $_userToken");
        print('🔐 NotificationService: Added Authorization header');
      }

      _hubConnection = HubConnectionBuilder()
          .withUrl(_hubUrl, options: httpConnectionOptions)
          .withAutomaticReconnect(retryDelays: [0, 2000, 10000, 30000])
          .build();

      print('🏗 NotificationService: HubConnection built successfully');

      _setupSignalRHandlers();
      print('📡 NotificationService: Event handlers set up');

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
      rethrow;
    }
  }

  void _setupSignalRHandlers() {
    print('📡 NotificationService: Setting up SignalR event handlers...');

    if (_hubConnection == null) {
      print('❌ NotificationService: Cannot setup handlers - hubConnection is null');
      return;
    }

    // Listen for FeedbackReceived
    // ✅ Feedback
    _hubConnection!.on("FeedbackReceived", (arguments) {
      print('💬 NotificationService: Received FeedbackReceived notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleFeedbackNotification(arguments[0]);
      }
    });

    // Listen for BusAdded notifications
    _hubConnection!.on("BusAdded", (arguments) {
      print('🚌 NotificationService: Received BusAdded notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleFilteredNotification(arguments[0].toString(), "BusAdded");
      }
    });


    // Listen for ShiftCreated notifications
    _hubConnection!.on("ShiftCreated", (arguments) {
      print('📅 NotificationService: Received ShiftCreated notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleFilteredNotification(arguments[0].toString(), "ShiftCreated");
      }
    });

    _hubConnection!.on("ShiftUpdated", (arguments) {
      print('📅 NotificationService: Received ShiftUpdated notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleFilteredNotification(arguments[0].toString(), "ShiftUpdated");
      }
    });

    _hubConnection!.on("ShiftDeleted", (arguments) {
      print('📅 NotificationService: Received ShiftDeleted notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleFilteredNotification(arguments[0].toString(), "ShiftDeleted");
      }
    });

    _hubConnection!.on("NormalShiftRemoved", (arguments) {
      print('📅 NotificationService: Received NormalShiftRemoved notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleFilteredNotification(arguments[0].toString(), "NormalShiftRemoved");
      }
    });

    _hubConnection!.on("ReverseShiftRemoved", (arguments) {
      print('📅 NotificationService: Received ReverseShiftRemoved notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleFilteredNotification(arguments[0].toString(), "ReverseShiftRemoved");
      }
    });


    // Listen for FeedbackReplied notifications
    _hubConnection!.on("FeedbackReplied", (arguments) {
      print('💬 NotificationService: Received FeedbackReplied notification: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _handleFilteredNotification(arguments[0].toString(), "FeedbackReplied");
      }
    });



    // Keep original generic handlers for backward compatibility
    _hubConnection!.on('ReceiveNotification', (List<Object?>? arguments) {
      if (arguments != null && arguments.length >= 2) {
        try {
          final String message = arguments[0] as String;
          final String type = arguments[1] as String;

          print('📬 NotificationService: Received ReceiveNotification - Type: $type, Message: $message');
          _handleFilteredNotification(message, type);
        } catch (e) {
          print('⚠ NotificationService: Error handling ReceiveNotification: $e');
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
      if (_currentStaffId != null) {
        _hubConnection!.invoke('JoinStaffGroup', args: [?_currentStaffId]);
      }
    });

    print('✅ NotificationService: All event handlers set up successfully');
  }

  // New method to handle filtered notifications based on type
  Future<void> _handleFilteredNotification(String message, String type) async {
    print('🔍 NotificationService: Processing filtered notification - Type: $type');

    try {
      switch (type) {
        case "BusAdded":
          final shouldShow = await _shouldShowBusAddedNotification(message);
          if (shouldShow) {
            _createAndAddNotification(
              title: "Bus Assignment",
              description: message,
              type: "bus_added",
              message: message,
            );
          }
          break;

          case "ShiftCreated":
          case "ShiftUpdated":
          case "ShiftDeleted":
          case "NormalShiftRemoved":
          case "ReverseShiftRemoved":
          bool shouldShow = false;
      try {
      shouldShow = await _shouldShowShiftNotification(message);
      } catch (_) {
      shouldShow = false;
      }

      // Always notify, even if user is not assigned
      _createAndAddNotification(
      title: _getShiftNotificationTitle(type),
      description: message,
      type: "shift",
      message: message,
      );
      break;

        case "FeedbackReplied":
          final feedbackDetails = await _handleFeedbackReplied(message);
          if (feedbackDetails != null) {
            _createAndAddNotification(
              title: "Feedback Reply",
              description: feedbackDetails,
              type: "feedback",
              message: message,
            );
          }
          break;

        default:
        // Handle unknown types as generic notifications
          _createAndAddNotification(
            title: "Notification",
            description: message,
            type: type.toLowerCase(),
            message: message,
          );
          break;
      }
    } catch (e) {
      print('❌ NotificationService: Error processing filtered notification: $e');
      // Fallback: create generic notification
      _createAndAddNotification(
        title: "Notification",
        description: message,
        type: type.toLowerCase(),
        message: message,
      );
    }
  }

  // Helper method to create and add notification
  void _createAndAddNotification({
    required String title,
    required String description,
    required String type,
    required String message,
    String routeNo = "",
    String subject = "",
  }) {
    final dateTime = _getCurrentDateTime();
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      routeNo: routeNo,
      date: dateTime['date']!,
      time: dateTime['time']!,
      type: type,
      isRead: false,
      staffId: _currentStaffId ?? '',
      subject: subject,
      message: message,
    );

    _addNotification(notification);
  }

  // Check if bus added notification should be shown
  Future<bool> _shouldShowBusAddedNotification(String message) async {
    try {
      // Extract number plate from message: "You have been added to the bus {bus.NumberPlate}."
      final RegExp reg = RegExp(r'You have been added to the bus ([A-Z]{2}\s*-\s*\d{4})');
      final match = reg.firstMatch(message);
      if (match == null) {
        print('⚠ NotificationService: Could not extract number plate from message: $message');
        return false;
      }

      final plate = match.group(1);
      if (plate == null) return false;

      print('🔍 NotificationService: Checking bus assignment for plate: $plate');
      return await _isUserOnBus(plate);
    } catch (e) {
      print('❌ NotificationService: Error checking bus added notification: $e');
      return false;
    }
  }

  // Check if shift notification should be shown
  Future<bool> _shouldShowShiftNotification(String message) async {
    try {
      // Extract shift ID from message: "A new shift has been created: shift_1753458855154"
      final match = RegExp(r'(shift_\d+)').firstMatch(message);
      if (match == null) {
        print('⚠ NotificationService: Could not extract shift ID from message: $message');
        return false;
      }

      final shiftId = match.group(1);
      if (shiftId == null) return false;

      print('🔍 NotificationService: Checking shift assignment for shift: $shiftId');

      // Get shift details
      final url = '$_baseApiUrl/BusShift/$shiftId';
      print('🔍 NotificationService: Calling shift API: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print('❌ NotificationService: Failed to get shift details: ${response.statusCode} - ${response.body}');
        return false;
      }

      final shiftData = json.decode(response.body);
      print('🔍 NotificationService: Shift data received: $shiftData');

      final numberPlate = shiftData['numberPlate'];
      if (numberPlate == null) {
        print('⚠ NotificationService: No number plate found in shift data');
        return false;
      }

      print('🔍 NotificationService: Checking if user is on bus: $numberPlate');
      return await _isUserOnBus(numberPlate);
    } catch (e) {
      print('❌ NotificationService: Error checking shift notification: $e');
      return false;
    }
  }

  // Check if user is assigned to a specific bus
  Future<bool> _isUserOnBus(String numberPlate) async {
    try {
      // URL encode the number plate (replace spaces with %20)
      final formattedPlate = numberPlate.replaceAll(' ', '%20');
      final busUrl = '$_baseApiUrl/Bus/$formattedPlate';

      print('🔍 NotificationService: Calling bus API: $busUrl');
      final busResponse = await http.get(Uri.parse(busUrl));

      if (busResponse.statusCode != 200) {
        print('❌ NotificationService: Failed to get bus details: ${busResponse.statusCode}');
        return false;
      }

      final data = json.decode(busResponse.body);
      final driverId = data['driverId'];
      final conductorId = data['conductorId'];

      print('🔍 NotificationService: Bus data - Driver: $driverId, Conductor: $conductorId, Current Staff: $_currentStaffId');

      final isAssigned = _currentStaffId == driverId || _currentStaffId == conductorId;
      print('✅ NotificationService: User assignment check result: $isAssigned');

      return isAssigned;
    } catch (e) {
      print('❌ NotificationService: Error checking user bus assignment: $e');
      return false;
    }
  }

  // Handle feedback replied notification
  Future<String?> _handleFeedbackReplied(String message) async {
    try {
      // Extract passenger ID and subject from message:
      // "Feedback from Passenger {feedback.PassengerId} has been replied: {feedback.Subject}"
      final match = RegExp(
          r'Feedback from Passenger ([\w\d]+) has been replied: (.+)$'
      ).firstMatch(message);

      if (match == null) {
        print('⚠ NotificationService: Could not extract feedback details from message: $message');
        return null;
      }

      final passengerId = match.group(1);
      final subject = match.group(2);

      if (passengerId == null || subject == null) return null;

      print('🔍 NotificationService: Looking for feedback - Passenger: $passengerId, Subject: $subject');

      // Get all feedback
      final url = '$_baseApiUrl/Feedback';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print('❌ NotificationService: Failed to get feedback list: ${response.statusCode}');
        return null;
      }

      final List<dynamic> feedbacks = json.decode(response.body);

      // Find matching feedback
      final feedback = feedbacks.firstWhere(
            (f) => f['passengerId'] == passengerId && f['subject'] == subject,
        orElse: () => null,
      );

      if (feedback == null) {
        print('⚠ NotificationService: No matching feedback found');
        return null;
      }

      print('✅ NotificationService: Found matching feedback');

      // Format the display message
      return '''Feedback Received:
Subject: ${feedback['subject']}
Message: ${feedback['message']}
Reply: ${feedback['reply']}''';

    } catch (e) {
      print('❌ NotificationService: Error handling feedback replied: $e');
      return null;
    }
  }

  // Get clean shift message based on type
  String _getCleanShiftMessage(String type) {
    switch (type) {
      case "ShiftCreated":
        return "A new shift has been created.";
      case "ShiftUpdated":
        return "A shift has been updated.";
      case "ShiftDeleted":
        return "A shift has been deleted.";
      case "NormalShiftRemoved":
        return "A normal shift has been removed.";
      case "ReverseShiftRemoved":
        return "A reverse shift has been removed.";
      default:
        return "Shift update received.";
    }
  }

  // Get shift notification title based on type
  String _getShiftNotificationTitle(String type) {
    switch (type) {
      case "ShiftCreated":
        return "New Shift Created";
      case "ShiftUpdated":
        return "Shift Updated";
      case "ShiftDeleted":
        return "Shift Deleted";
      case "NormalShiftRemoved":
        return "Normal Shift Removed";
      case "ReverseShiftRemoved":
        return "Reverse Shift Removed";
      default:
        return "Shift Notification";
    }
  }

  // Handle emergency notification with self-notification prevention
  void _handleEmergencyNotificationWithFilter(dynamic message) async {
    print('🚨 NotificationService: Processing emergency notification with filter...');
    try {
      final messageStr = message?.toString() ?? '';

      // Check if this SOS is from the current user to prevent self-notification
      if (await _isSelfSOS(messageStr)) {
        print('🚫 NotificationService: Ignoring self SOS notification');
        return;
      }

      final dateTime = _getCurrentDateTime();
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "SOS Alert",
        description: messageStr.isEmpty ? "Emergency alert received" : messageStr,
        routeNo: "Emergency",
        date: dateTime['date']!,
        time: dateTime['time']!,
        type: "emergency",
        isRead: false,
        staffId: _currentStaffId ?? '',
        message: messageStr,
      );

      _addNotification(notification);
      print('✅ NotificationService: Emergency notification processed');
    } catch (e) {
      print('❌ NotificationService: Error handling emergency notification: $e');
    }
  }

  // Check if SOS notification is from current user
  Future<bool> _isSelfSOS(String message) async {
    try {
      // You can implement different logic here based on how SOS messages are structured
      // For example, if SOS messages contain staff ID or bus number plate

      // Method 1: If message contains staff ID
      if (message.contains(_currentStaffId ?? '')) {
        return true;
      }

      // Method 2: If message contains bus number plate, check if current user is on that bus
      final RegExp plateRegex = RegExp(r'([A-Z]{2}\s*-\s*\d{4})');
      final match = plateRegex.firstMatch(message);
      if (match != null) {
        final plate = match.group(1);
        if (plate != null) {
          // Check if current user is on this bus
          final isOnBus = await _isUserOnBus(plate);
          if (isOnBus) {
            print('🔍 NotificationService: SOS from own bus detected');
            return true;
          }
        }
      }

      // Method 3: Check recent SOS activity (if you track when user sends SOS)
      // You could store timestamp when user sends SOS and ignore notifications within a time window

      return false;
    } catch (e) {
      print('❌ NotificationService: Error checking self SOS: $e');
      return false; // When in doubt, show the notification for safety
    }
  }

  void _handleFeedbackNotification(dynamic message) {
    print('💬 NotificationService: Processing feedback notification...');
    try {
      final dateTime = _getCurrentDateTime();

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
        message: message.toString(),
      );

      _addNotification(notification);
      print('✅ NotificationService: Feedback notification processed');
    } catch (e) {
      print('❌ NotificationService: Error handling feedback notification: $e');
    }
  }

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
        message: message.toString(),
      );

      _addNotification(notification);
      print('✅ NotificationService: Shift started notification processed');
    } catch (e) {
      print('❌ NotificationService: Error handling shift started notification: $e');
    }
  }

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
        message: message.toString(),
      );

      _addNotification(notification);
      print('✅ NotificationService: Shift interval notification processed');
    } catch (e) {
      print('❌ NotificationService: Error handling shift interval notification: $e');
    }
  }

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
        message: message.toString(),
      );

      _addNotification(notification);
      print('✅ NotificationService: Shift ended notification processed');
    } catch (e) {
      print('❌ NotificationService: Error handling shift ended notification: $e');
    }
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    try {
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