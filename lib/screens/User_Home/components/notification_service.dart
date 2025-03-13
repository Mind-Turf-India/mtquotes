import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final DateTime timestamp;


  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.data,
    required this.timestamp,
  });

  factory NotificationModel.fromRemoteMessage(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      imageUrl: json['imageUrl'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
  
  // Save the notification even when app is in background
  await NotificationService.instance.saveNotification(
    NotificationModel.fromRemoteMessage(message)
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;
  
  // Stream controller for notifications
  final _notificationsStreamController = StreamController<List<NotificationModel>>.broadcast();
  Stream<List<NotificationModel>> get notificationsStream => _notificationsStreamController.stream;
  
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    await _requestPermission();
    
    // Load saved notifications
    await _loadSavedNotifications();

    // Setup message handlers
    await _setupMessageHandlers();

    // Get FCM token and save it
    await refreshAndSaveToken();
  }

  Future<void> refreshAndSaveToken() async {
    final token = await _messaging.getToken();
    print('FCM Token: $token');
    
    // Save the token to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token ?? '');
    
    // Here you would typically send this token to your backend
    // await _sendTokenToServer(token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    print('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    // android setup
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ios setup
    final initializationSettingsDarwin = const DarwinInitializationSettings();

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // flutter notification setup
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        final payload = details.payload;
        if (payload != null) {
          try {
            final data = json.decode(payload);
            _handleNotificationTap(data);
          } catch (e) {
            print('Error parsing notification payload: $e');
          }
        }
      },
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            largeIcon: android?.imageUrl != null ? FilePathAndroidBitmap(android!.imageUrl!) : null,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  Future<void> _setupMessageHandlers() async {
    // Foreground message
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
      
      // Save the notification
      saveNotification(NotificationModel.fromRemoteMessage(message));
    });

    // Background message
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleBackgroundMessage(message);
    });

    // Opened app from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      // open chat screen
    }
    
    // Additional handling based on notification type
    _handleNotificationTap(message.data);
  }
  
  void _handleNotificationTap(Map<String, dynamic> data) {
    // Handle notification tap based on data
    // For example, navigate to specific screen
    // This would typically involve a NavigationService or similar
  }
  
  // Methods to manage notifications
  Future<void> saveNotification(NotificationModel notification) async {
    _notifications.insert(0, notification);
    _notificationsStreamController.add(_notifications);
    
    // Save to persistent storage
    await _saveNotificationsToStorage();
  }
  
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((notification) => notification.id == id);
    _notificationsStreamController.add(_notifications);
    
    // Update persistent storage
    await _saveNotificationsToStorage();
  }
  
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _notificationsStreamController.add(_notifications);
    
    // Clear from persistent storage
    await _saveNotificationsToStorage();
  }
  
  Future<void> _loadSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNotifications = prefs.getStringList('notifications') ?? [];
      
      _notifications = savedNotifications
          .map((notificationJson) => NotificationModel.fromJson(json.decode(notificationJson)))
          .toList();
      
      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _notificationsStreamController.add(_notifications);
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }
  
  Future<void> _saveNotificationsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((notification) => json.encode(notification.toJson()))
          .toList();
      
      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }
  
  // Method to handle FCM token refresh
  void setupTokenRefresh() {
    _messaging.onTokenRefresh.listen((String token) async {
      print('FCM Token refreshed: $token');
      
      // Save the new token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      
      // Here you would typically send this token to your backend
      // await _sendTokenToServer(token);
    });
  }

  // Dispose method to clean up resources
  void dispose() {
    _notificationsStreamController.close();
  }
}