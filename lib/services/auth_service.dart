import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../services/firebase_cloud_messaging_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in and get saved user type
  Future<Map<String, dynamic>?> checkLoginStatus() async {
    try {
      // First check SharedPreferences for saved login info
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final String? userId = prefs.getString('userId');
      
      if (isLoggedIn && userId != null) {
        // Try to get user data from Firestore using saved userId
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists) {
          final userData = UserModel.fromFirestore(doc);
          
          // Refresh login status
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userType', userData.userType.value);
          await prefs.setString('userId', userData.id);
          
          // UPDATE: Save FCM token when checking login status
          await _updateUserFCMToken(userData.id, userData.userType);
          
          return {
            'user': userData,
            'isLoggedIn': true,
          };
        }
      }
      
      // If no saved login or failed to get user data, check current Firebase user
      final User? user = currentUser;
      if (user != null) {
        // Get user data from Firestore
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final userData = UserModel.fromFirestore(doc);
          
          // Save login status
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userType', userData.userType.value);
          await prefs.setString('userId', userData.id);
          
          // UPDATE: Save FCM token
          await _updateUserFCMToken(userData.id, userData.userType);
          
          return {
            'user': userData,
            'isLoggedIn': true,
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    String? phoneNumber,
  }) async {
    try {
      print('📝 Creating new user account: $email');
      
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        print('✅ User account created: ${user.uid}');
        
        // Create user document in Firestore
        final userModel = UserModel(
          id: user.uid,
          name: name,
          email: email,
          userType: userType,
          createdAt: DateTime.now(),
          phoneNumber: phoneNumber,
          fcmToken: null, // Will be updated below
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        print('✅ User document created in Firestore');

        // Save login status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', userType.value);
        await prefs.setString('userId', user.uid);

        // UPDATE: Get and save FCM token for new user
        await _updateUserFCMToken(user.uid, userType);

        return userModel;
      }
      return null;
    } catch (e) {
      print('❌ Sign up failed: $e');
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Signing in user: $email');
      
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        print('✅ User signed in: ${user.uid}');
        
        // Get user data from Firestore
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final userModel = UserModel.fromFirestore(doc);
          
          print('✅ User data retrieved: ${userModel.name} (${userModel.userType.value})');
          
          // Save login status
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userType', userModel.userType.value);
          await prefs.setString('userId', user.uid);
          
          // UPDATE: Update FCM token on sign in
          await _updateUserFCMToken(user.uid, userModel.userType);
          
          return userModel;
        }
      }
      return null;
    } catch (e) {
      print('❌ Sign in failed: $e');
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // UPDATE: New method to update user's FCM token
  Future<void> _updateUserFCMToken(String userId, UserType userType) async {
    try {
      print('📱 Updating FCM token for user: $userId');
      
      // Get current FCM token
      String? fcmToken = await FirebaseCloudMessagingService.getCurrentToken();
      
      if (fcmToken != null) {
        // Update user document with FCM token
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'tokenActive': true,
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        print('✅ FCM token updated for user: $userId');
        print('📱 Token: ${fcmToken.substring(0, 20)}...');
        
        // If user is staff, they're now ready to receive notifications
        if (userType == UserType.staff) {
          print('👨‍⚕️ Staff member ready to receive death case notifications');
        }
      } else {
        print('❌ Could not get FCM token');
      }
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('🚪 Signing out user...');
      
      // Mark FCM token as inactive before signing out
      final User? user = currentUser;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'tokenActive': false,
            'lastLogout': FieldValue.serverTimestamp(),
          });
          print('✅ FCM token marked as inactive');
        } catch (e) {
          print('⚠️  Warning: Could not mark token as inactive: $e');
        }
      }
      
      await _auth.signOut();
      
      // Clear only login status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      // We keep userId and userType for future reference
      
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Sign out failed: $e');
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    try {
      final User? user = currentUser;
      if (user != null) {
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final userData = UserModel.fromFirestore(doc);
          
          // Ensure FCM token is up to date
          await _updateUserFCMToken(user.uid, userData.userType);
          
          return userData;
        }
      }
      return null;
    } catch (e) {
      print('❌ Failed to get user data: $e');
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  // NEW: Get all active staff members (for debugging)
  Future<List<UserModel>> getAllActiveStaff() async {
    try {
      QuerySnapshot staffQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'staff')
          .where('tokenActive', isEqualTo: true)
          .get();

      List<UserModel> staffList = [];
      for (DocumentSnapshot doc in staffQuery.docs) {
        staffList.add(UserModel.fromFirestore(doc));
      }

      print('👥 Found ${staffList.length} active staff members');
      return staffList;
    } catch (e) {
      print('❌ Error getting active staff: $e');
      return [];
    }
  }

  // NEW: Refresh current user's FCM token manually
  Future<void> refreshFCMToken() async {
    try {
      final User? user = currentUser;
      if (user != null) {
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final userData = UserModel.fromFirestore(doc);
          await _updateUserFCMToken(user.uid, userData.userType);
          print('✅ FCM token refreshed manually');
        }
      }
    } catch (e) {
      print('❌ Error refreshing FCM token: $e');
    }
  }
}