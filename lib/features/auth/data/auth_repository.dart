import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A simple exception that carries a message safe to show to the user.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

/// Talks to Firebase Auth (and creates the user document in Firestore).
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<User> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.code} - ${e.message}');
      throw AuthException(_readableMessage(e.code));
    }
  }

  Future<User> register(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = cred.user!;
      // Create the users/{userId} document.
      // If this fails (e.g. Firestore not created / rules not published) the
      // account already exists, so we log the problem and keep going.
      try {
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          'createdAt': Timestamp.now(),
        });
      } catch (e) {
        debugPrint('Could not create user document: $e');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Register error: ${e.code} - ${e.message}');
      throw AuthException(_readableMessage(e.code));
    }
  }

  Future<void> logout() => _auth.signOut();

  /// Converts Firebase error codes into friendly messages.
  String _readableMessage(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase Console.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}
