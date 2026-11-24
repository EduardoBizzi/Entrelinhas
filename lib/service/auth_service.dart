import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _providedAuth = auth;
  final FirebaseAuth? _providedAuth;
  FirebaseAuth get _auth => _providedAuth ?? FirebaseAuth.instance;
  Stream<User?> get changes => _auth.userChanges();

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register(String name, String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user!.updateDisplayName(name.trim());
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  Future<void> logout() => _auth.signOut();
}
