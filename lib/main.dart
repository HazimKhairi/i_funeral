import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'screens/loading_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/waris_home_screen.dart';
import 'screens/death_case_form_screen.dart';
import 'screens/staff_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Firebase Messaging
  await NotificationService.initialize();
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  void _setupNotifications() {
    // Check if app was opened from notification
    NotificationService.checkInitialNotification();
    
    // Handle notification tap when app is in background
    NotificationService.handleNotificationTap();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-Funeral',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
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
      builder: (context, child) {
        // Setup foreground notifications
        NotificationService.handleForegroundNotifications(context);
        return child!;
      },
    );
  }
}