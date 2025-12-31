import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart' as app_models;
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Initialize GoogleSignIn with the web client ID from google-services.json
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '157923135399-9h7odse0i09o0s10d2gdu163sbvftbpe.apps.googleusercontent.com',
  );
  final NotificationService _notificationService = NotificationService();
  
  app_models.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  app_models.User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      // Load user data from Firestore
      await _loadUserData(firebaseUser.uid);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      debugPrint('Loading user data for userId: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        debugPrint('User document exists, parsing data...');
        debugPrint('Document data: ${doc.data()}');
        _currentUser = app_models.User.fromJson({
          ...doc.data()!,
          'id': doc.id,
        });
        debugPrint('User loaded successfully: ${_currentUser?.name}');
        
        // Update lastActive timestamp every time user data is loaded (app launch)
        await _firestore.collection('users').doc(userId).update({
          'lastActive': FieldValue.serverTimestamp(),
        }).catchError((e) => debugPrint('Error updating lastActive: $e'));
        
        notifyListeners();
      } else {
        debugPrint('Warning: User document not found for $userId - creating one now');
        // Get the current firebase auth user to create the document
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null) {
          final userData = app_models.User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
            avatarUrl: firebaseUser.photoURL,
            level: 1,
            experience: 0,
            createdAt: DateTime.now(),
          );
          
          await _firestore.collection('users').doc(firebaseUser.uid).set({
            ...userData.toJson()..remove('id'),
            'lastActive': FieldValue.serverTimestamp(),
          });
          
          _currentUser = userData;
          debugPrint('Created new user document for: ${userData.name}');
          notifyListeners();
        } else {
          _currentUser = null;
          notifyListeners();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading user data: $e');
      debugPrint('Stack trace: $stackTrace');
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Attempting to sign in with email: $email');
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('Sign in successful, user: ${credential.user?.uid}');
      
      if (credential.user != null) {
        // Check if email is verified
        if (!credential.user!.emailVerified) {
          debugPrint('Email not verified');
          _errorMessage = 'Please verify your email address before logging in. Check your inbox for the verification link.';
          await _firebaseAuth.signOut();
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        debugPrint('Email verified, loading user data...');
        
        // Try to load/create user data, but don't fail login if Firestore has issues
        try {
          final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
          
          if (!userDoc.exists) {
            debugPrint('Creating new user document...');
            final userData = app_models.User(
              id: credential.user!.uid,
              email: email,
              name: credential.user!.displayName ?? email.split('@')[0],
              level: 1,
              experience: 0,
              createdAt: DateTime.now(),
            );
            
            await _firestore.collection('users').doc(credential.user!.uid).set({
              'email': userData.email,
              'name': userData.name,
              'avatarUrl': userData.avatarUrl,
              'level': userData.level,
              'experience': userData.experience,
              'createdAt': userData.createdAt.toIso8601String(),
              'studyTechnique': userData.studyTechnique,
              'lastActive': FieldValue.serverTimestamp(),
            });
            debugPrint('User document created');
          } else {
            debugPrint('User document exists, updating lastActive...');
            await _firestore.collection('users').doc(credential.user!.uid).update({
              'lastActive': FieldValue.serverTimestamp(),
            });
          }
          
          await _loadUserData(credential.user!.uid);
        } catch (firestoreError) {
          debugPrint('Firestore error (non-fatal): $firestoreError');
          // Create a basic user object from Firebase Auth data
          _currentUser = app_models.User(
            id: credential.user!.uid,
            email: credential.user!.email ?? email,
            name: credential.user!.displayName ?? email.split('@')[0],
            level: 1,
            experience: 0,
            createdAt: DateTime.now(),
          );
        }
        
        _isLoading = false;
        notifyListeners();
        debugPrint('Login complete, currentUser: ${_currentUser?.name}');
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      
      // Set error code for UI to handle
      if (e.code == 'user-not-found') {
        _errorMessage = 'No account found with this email address.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-credential') {
        _errorMessage = 'Invalid email or password. Please check your credentials.';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Please enter a valid email address.';
      } else if (e.code == 'user-disabled') {
        _errorMessage = 'This account has been disabled. Please contact support.';
      } else if (e.code == 'too-many-requests') {
        _errorMessage = 'Too many failed attempts. Please try again later.';
      } else {
        _errorMessage = _getFirebaseErrorMessage(e);
      }
      
      notifyListeners();
      debugPrint('Login error: ${e.code} - ${e.message}');
      return false;
    } catch (e, stackTrace) {
      _isLoading = false;
      debugPrint('Login unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      // Show actual error for debugging
      _errorMessage = 'Login failed: ${e.toString().split('\n').first}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create Firebase Auth user
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Send email verification
        await credential.user!.sendEmailVerification();
        
        // Create user document in Firestore
        final userData = app_models.User(
          id: credential.user!.uid,
          email: email,
          name: name,
          level: 1,
          experience: 0,
          createdAt: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(credential.user!.uid).set(
          userData.toJson()..remove('id'), // Remove id as it's the document ID
        );
        
        // Send welcome notification/email
        await _notificationService.sendWelcomeNotification(
          credential.user!.uid,
          email,
          name,
        );
        
        // Create welcome in-app notification
        await _notificationService.createInAppNotification(
          userId: credential.user!.uid,
          title: 'Welcome to IntelliPlan! 🎓',
          message: 'Start your journey to better study habits. Complete your profile and begin your first study session!',
          type: 'success',
        );
        
        debugPrint('✅ Welcome notifications sent to $email');
        
        // Sign out the user - they need to verify email first
        await _firebaseAuth.signOut();
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      
      // Set user-friendly error messages
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'An account already exists with this email address. Please sign in instead.';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'Password is too weak. Please use at least 6 characters with letters and numbers.';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Please enter a valid email address.';
      } else {
        _errorMessage = _getFirebaseErrorMessage(e);
      }
      
      notifyListeners();
      debugPrint('Registration error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Registration failed. Please try again.';
      notifyListeners();
      debugPrint('Registration error: $e');
      return false;
    }
  }

  // Google Sign-In
  // isRegistration: true if called from register screen, false if from login screen
  Future<bool> signInWithGoogle({bool isRegistration = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        _isLoading = false;
        _errorMessage = null; // Don't show error for user cancellation
        notifyListeners();
        return false;
      }

      final email = googleUser.email;
      
      // If this is registration, check Firestore FIRST to see if user already exists
      if (isRegistration) {
        debugPrint('REGISTRATION MODE: Checking if user exists with email: $email');
        
        // Query Firestore for existing user with this email
        final existingUsers = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        
        if (existingUsers.docs.isNotEmpty) {
          // User already exists!
          await _googleSignIn.signOut();
          _isLoading = false;
          _errorMessage = 'An account already exists with this email. Please sign in instead.';
          notifyListeners();
          debugPrint('❌ BLOCKED: Account already exists with this email!');
          return false;
        }
        debugPrint('✅ Email not found in Firestore, can proceed with registration');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      debugPrint('✅ Proceeding with Firebase sign-in...');
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        debugPrint('Firebase sign-in successful. UID: ${userCredential.user!.uid}');
        
        // Check if user document exists
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        if (!userDoc.exists) {
          // New user from Google Sign-In - create profile
          final userData = app_models.User(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'User',
            avatarUrl: userCredential.user!.photoURL,
            level: 1,
            experience: 0,
            createdAt: DateTime.now(),
          );
          
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            ...userData.toJson()..remove('id'),
            'lastActive': FieldValue.serverTimestamp(),
          });
          
          // Send welcome notification for new Google Sign-In users
          await _notificationService.sendWelcomeNotification(
            userCredential.user!.uid,
            userCredential.user!.email ?? '',
            userCredential.user!.displayName ?? 'User',
          );
          
          // Create welcome in-app notification
          await _notificationService.createInAppNotification(
            userId: userCredential.user!.uid,
            title: 'Welcome to IntelliPlan! 🎓',
            message: 'You\'re all set! Start exploring study techniques and track your progress.',
            type: 'success',
          );
          
          debugPrint('✅ Welcome notifications sent for Google user');
        } else {
          // Existing user - update lastActive timestamp
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
        
        await _loadUserData(userCredential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      
      // Handle specific Firebase Auth errors
      if (e.code == 'account-exists-with-different-credential') {
        _errorMessage = 'This email is already linked to a different sign-in method.';
      } else if (e.code == 'email-already-in-use') {
        _errorMessage = 'An account already exists with this email address.';
      } else if (e.code == 'invalid-credential') {
        _errorMessage = 'Google sign-in failed. Please try again.';
      } else if (e.code == 'operation-not-allowed') {
        _errorMessage = 'Google sign-in is not enabled. Please contact support.';
      } else if (e.code == 'user-disabled') {
        _errorMessage = 'This account has been disabled.';
      } else {
        _errorMessage = _getFirebaseErrorMessage(e);
      }
      
      await _googleSignIn.signOut();
      notifyListeners();
      debugPrint('Google Sign-In Firebase error: ${e.code} - ${e.message}');
      return false;
    } catch (e, stackTrace) {
      _isLoading = false;
      // Show actual error for debugging
      debugPrint('Google Sign-In error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      String errorMsg = e.toString();
      if (errorMsg.contains('ApiException: 10')) {
        _errorMessage = 'Google Sign-In configuration error. SHA-1 fingerprint may be missing in Firebase Console.';
      } else if (errorMsg.contains('ApiException: 12500')) {
        _errorMessage = 'Google Sign-In failed. Please update Google Play Services.';
      } else if (errorMsg.contains('ApiException: 7')) {
        _errorMessage = 'Network error. Please check your internet connection.';
      } else if (errorMsg.contains('network_error') || errorMsg.contains('NETWORK_ERROR')) {
        _errorMessage = 'Network error. Please check your internet connection.';
      } else if (errorMsg.contains('sign_in_canceled') || errorMsg.contains('canceled')) {
        _errorMessage = null; // User cancelled, no error to show
        await _googleSignIn.signOut();
        notifyListeners();
        return false;
      } else {
        _errorMessage = 'Google Sign-In failed: ${e.toString().split('\n').first}';
      }
      
      await _googleSignIn.signOut();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Check email verification status in real-time
  Future<bool> checkEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload(); // Reload user data from Firebase
        final updatedUser = _firebaseAuth.currentUser;
        return updatedUser?.emailVerified ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  // Wait for email verification with periodic checks
  Future<bool> waitForEmailVerification({
    Duration timeout = const Duration(minutes: 5),
    Duration checkInterval = const Duration(seconds: 3),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      final isVerified = await checkEmailVerification();
      if (isVerified) {
        return true;
      }
      await Future.delayed(checkInterval);
    }
    
    return false; // Timeout
  }

  // Resend verification email
  Future<bool> resendVerificationEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      return false;
    }
  }

  // Helper method to get user-friendly error messages
  String _getFirebaseErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      
      if (e.code == 'user-not-found') {
        _errorMessage = 'No account found with this email address.';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Invalid email address.';
      } else {
        _errorMessage = _getFirebaseErrorMessage(e);
      }
      
      notifyListeners();
      debugPrint('Password reset error: ${e.message}');
      return false;
    }
  }

  Future<void> updateProfile(String name, String? avatarUrl) async {
    if (_currentUser != null) {
      try {
        final updatedUser = _currentUser!.copyWith(
          name: name,
          avatarUrl: avatarUrl,
        );
        
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'name': name,
          'avatarUrl': avatarUrl,
        });
        
        _currentUser = updatedUser;
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating profile: $e');
      }
    }
  }

  Future<void> addExperience(int points) async {
    if (_currentUser != null) {
      int newExp = _currentUser!.experience + points;
      int newLevel = _currentUser!.level;
      
      // Simple level calculation: 1000 XP per level
      while (newExp >= newLevel * 1000) {
        newExp -= newLevel * 1000;
        newLevel++;
      }
      
      final updatedUser = _currentUser!.copyWith(
        experience: newExp,
        level: newLevel,
      );
      
      try {
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'experience': newExp,
          'level': newLevel,
        });
        
        _currentUser = updatedUser;
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating experience: $e');
      }
    }
  }

  /// Refresh current user data from Firestore
  Future<void> refreshUser() async {
    if (_currentUser != null) {
      await _loadUserData(_currentUser!.id);
    }
  }
}
