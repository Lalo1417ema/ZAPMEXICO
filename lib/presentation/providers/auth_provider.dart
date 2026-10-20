import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;

  String? user;
  bool isLoading = false;
  String userRole = 'user';
  Map<String, dynamic>? currentUserModel;
  String? authError;
  bool isBlocked = false;

  bool get isLoggedIn => user != null;
  bool get isAdmin => userRole == 'admin';

  AuthProvider() {
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChange);
  }

  Future<void> _handleAuthChange(User? firebaseUser) async {
    if (firebaseUser == null) {
      await _profileSubscription?.cancel();
      _profileSubscription = null;
      user = null;
      userRole = 'user';
      currentUserModel = null;
      isBlocked = false;
      notifyListeners();
      return;
    }

    try {
      await _loadUser(firebaseUser);
    } on FirebaseException catch (error) {
      authError = error.message ?? 'No se pudo cargar el perfil de usuario.';
      debugPrint('Error al cargar el perfil de Firebase: $error');
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _loadUser(firebaseUser);
    }
  }

  Future<void> _loadUser(User firebaseUser) async {
    final profileRef = _firestore.collection('users').doc(firebaseUser.uid);
    final adminRef = _firestore.collection('admins').doc(firebaseUser.uid);
    final results = await Future.wait([profileRef.get(), adminRef.get()]);
    if (_auth.currentUser?.uid != firebaseUser.uid) {
      return;
    }
    final profile = results.first.data() ?? <String, dynamic>{};

    user = firebaseUser.uid;
    userRole = results.last.exists ? 'admin' : 'user';
    isBlocked = profile['blocked'] == true && userRole != 'admin';
    authError = null;
    currentUserModel = {
      ...profile,
      'uid': firebaseUser.uid,
      'email': firebaseUser.email ?? profile['email'] ?? '',
      'name':
          profile['name'] ??
          firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'Usuario',
    };
    await _profileSubscription?.cancel();
    _profileSubscription = profileRef.snapshots().listen((snapshot) {
      if (_auth.currentUser?.uid != firebaseUser.uid) return;
      final updatedProfile = snapshot.data() ?? <String, dynamic>{};
      isBlocked = updatedProfile['blocked'] == true && !isAdmin;
      currentUserModel = {
        ...?currentUserModel,
        ...updatedProfile,
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? updatedProfile['email'] ?? '',
      };
      notifyListeners();
    });
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _loadUser(credential.user!);
    return true;
  }

  Future<bool> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      clientId: kIsWeb
          ? '814376171285-tb4qsmvnqcorb11n3uirro0t4buk2jb7.apps.googleusercontent.com'
          : null,
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return false;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    await _saveProfile(
      result.user!,
      name: result.user!.displayName ?? googleUser.displayName ?? 'Usuario',
      email: result.user!.email ?? googleUser.email,
    );
    await _loadUser(result.user!);
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String city,
    required String phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.updateDisplayName(name.trim());
    await _saveProfile(
      credential.user!,
      name: name.trim(),
      email: email.trim(),
      city: city.trim(),
      phone: phone.trim(),
    );
    await _loadUser(credential.user!);
    return true;
  }

  Future<void> _saveProfile(
    User firebaseUser, {
    required String name,
    required String email,
    String city = '',
    String phone = '',
  }) async {
    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'uid': firebaseUser.uid,
      'name': name,
      'email': email,
      'city': city,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setVisitorProfile({
    required String name,
    required String municipality,
  }) async {
    final firebaseUser =
        _auth.currentUser ?? (await _auth.signInAnonymously()).user!;
    await _saveProfile(
      firebaseUser,
      name: name.trim(),
      email: firebaseUser.email ?? '',
      city: municipality,
    );
    await _loadUser(firebaseUser);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
