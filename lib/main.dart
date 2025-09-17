import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'services/notification_service.dart';
import 'services/firebase_cloud_messaging_service.dart';
import 'screens/loading_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/waris_home_screen.dart';
import 'screens/death_case_form_screen.dart';
import 'screens/staff_home_screen.dart';

// Background message handler (MUST be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Background notification received: ${message.notification?.title}');
  
  // Handle background notification here if needed
  if (message.data['type'] == 'new_case') {
    print('🚨 New case notification in background: ${message.data['caseName']}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting I-Funeral App...');
  
  // Initialize Firebase FIRST
  await Firebase.initializeApp();
  print('✅ Firebase initialized');
  
  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize Firebase Cloud Messaging
  await FirebaseCloudMessagingService.initialize();
  print('✅ Firebase Cloud Messaging initialized');
  
  // Initialize Awesome Notifications (for local notifications)
  await NotificationService.initializeNotifications();
  print('✅ Awesome Notifications initialized');
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Navigator key for navigation from notifications
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('📱 Initializing app components...');
    
    // Start listening to notification events
    NotificationService.startListeningNotificationEvents();
    
    // Check for initial notification (app opened from terminated state)
    await _checkInitialNotification();
    
    print('✅ App initialization complete');
  }

  Future<void> _checkInitialNotification() async {
    try {
      // Check if app was opened from FCM notification
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      
      if (initialMessage != null) {
        print('📱 App opened from notification: ${initialMessage.data}');
        
        // Handle initial notification
        if (initialMessage.data['type'] == 'new_case') {
          print('🚨 Opening app from new case notification');
          // Navigation will be handled after app is ready
        }
      }
    } catch (e) {
      print('❌ Error checking initial notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-Funeral',
      debugShowCheckedModeBanner: false,
      navigatorKey: MyApp.navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        primarySwatch: Colors.green,
      ),
      home: const LoadingScreen(),
      routes: {
        '/loading': (context) => const LoadingScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/auth': (context) => const AuthScreen(),
        '/waris-home': (context) => const WarisHomeScreen(),
        '/death-case-form': (context) => const DeathCaseFormScreen(),
        '/staff-home': (context) => const StaffHomeScreen(),
      },
    );
  }
}