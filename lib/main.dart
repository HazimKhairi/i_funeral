import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart'; // Make sure this import exists
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
    // IMPORTANT: Wrap with OverlaySupport.global() FIRST
    return OverlaySupport.global(
      child: MaterialApp(
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
        // Remove this builder if you have it
        // builder: (context, child) {
        //   NotificationService.handleForegroundNotifications(context);
        //   return child!;
        // },
      ),
    );
  }
}

// Background notification handler (must be top-level function)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background notification received: ${message.notification?.title}');
}