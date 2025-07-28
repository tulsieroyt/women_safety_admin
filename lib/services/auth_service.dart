import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User user = userCred.user!;

      DocumentSnapshot adminDoc =
      await _firestore.collection('admins').doc(user.uid).get();

      if (adminDoc.exists && adminDoc.get('isApproved') == true) {
        return user;
      } else {
        await _auth.signOut();
        return null;
      }
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? newUser = userCredential.user;

      print('The user id is: ${newUser?.uid}');
      print("Hllo");

      if (newUser != null) {
        await _firestore.collection('admins').doc(newUser.uid).set({
          'name': name,
          'email': email,
          'isSuperAdmin': false,
          'isApproved': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      print("Registration error: ${e.message}");
      rethrow;
    }
  }

  Future<void> signOut() async => await _auth.signOut();
}