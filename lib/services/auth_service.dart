import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔐 LOGIN
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _handleError(e);
    }
  }

  // 🆕 SIGN UP
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _handleError(e);
    }
  }

  // 🚪 LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ❌ ERROR HANDLING
  String _handleError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already exists';
      case 'invalid-email':
        return 'Invalid email';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      default:
        return e.message ?? 'Authentication error';
    }
  }
}
