import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<User?> signUp(String email, String password, String displayName) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    
    if (credential.user != null) {
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();
    }
    
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<String> updateAuthProfile({String? displayName, String? newEmail, String? newPassword}) async {
    User? user = _auth.currentUser;
    if (user == null) return "No hay usuario";

    try {
      if (displayName != null && displayName != user.displayName) {
        await user.updateDisplayName(displayName);
      }
      if (newEmail != null && newEmail.isNotEmpty && newEmail != user.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
      }
      if (newPassword != null && newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }
      await user.reload();
      return "Cambios guardados correctamente";
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }
}