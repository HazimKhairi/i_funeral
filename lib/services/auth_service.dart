import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this
import '../models/user_model.dart';
import '../models/enums.dart';

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
          
          return {
            'user': userData,
            'isLoggedIn': true,
          };
        }
      }
      return null;
    } catch (e) {
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
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Create user document in Firestore
        final userModel = UserModel(
          id: user.uid,
          name: name,
          email: email,
          userType: userType,
          createdAt: DateTime.now(),
          phoneNumber: phoneNumber,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        // Save login status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', userType.value);
        await prefs.setString('userId', user.uid);

        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Get user data from Firestore
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final userModel = UserModel.fromFirestore(doc);
          
          // Save login status
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userType', userModel.userType.value);
          await prefs.setString('userId', user.uid);
          
          return userModel;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      // Clear only login status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      // We keep userId and userType for future reference
    } catch (e) {
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
          return UserModel.fromFirestore(doc);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }
}