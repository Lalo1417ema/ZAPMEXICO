import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  static const _biometricEnabledKey = 'biometric_login_enabled';
  static const _biometricUserKey = 'biometric_login_user';
  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;

  String? user;
  bool isLoading = false;
  String userRole = 'user';
  Map<String, dynamic>? currentUserModel;
  String? authError;
  bool isBlocked = false;
  bool needsProfileCompletion = false;

  bool get isLoggedIn => user != null;
  bool get isAdmin => userRole == 'admin';
  bool get isVisitor => _auth.currentUser?.isAnonymous ?? false;
  bool get isRegisteredUser => isLoggedIn && !isVisitor;

  Future<bool> get canUseBiometrics async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }
    return (await _localAuthentication.getAvailableBiometrics()).isNotEmpty;
  }

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
      needsProfileCompletion = false;
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
    needsProfileCompletion =
        firebaseUser.providerData.any(
          (provider) => provider.providerId == 'google.com',
        ) &&
        (profile['city']?.toString().trim().isEmpty ?? true);
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
    needsProfileCompletion = false;
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _loadUser(credential.user!);
    return true;
  }

  Future<bool> loginWithGoogle() async {
    needsProfileCompletion = false;
    late final UserCredential result;
    String? googleDisplayName;
    String? googleEmail;
    if (kIsWeb) {
      result = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false;
      googleDisplayName = googleUser.displayName;
      googleEmail = googleUser.email;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      result = await _auth.signInWithCredential(credential);
    }
    final firebaseUser = result.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'google-account-unavailable',
        message: 'Google no devolvió una cuenta válida.',
      );
    }
    final profile = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    final profileData = profile.data() ?? <String, dynamic>{};
    needsProfileCompletion =
        profileData['city']?.toString().trim().isEmpty ?? true;
    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'uid': firebaseUser.uid,
      'name': firebaseUser.displayName ?? googleDisplayName ?? 'Usuario',
      'email': firebaseUser.email ?? googleEmail ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _loadUser(firebaseUser);
    return true;
  }

  Future<bool> isBiometricLoginEnabled() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || !await canUseBiometrics) return false;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_biometricEnabledKey) == true &&
        preferences.getString(_biometricUserKey) == firebaseUser.uid;
  }

  Future<void> enableBiometricLogin() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw StateError('Inicia sesión antes de activar la huella.');
    }
    if (!await canUseBiometrics) {
      throw StateError('Este dispositivo no tiene biometría configurada.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_biometricUserKey, firebaseUser.uid);
    await preferences.setBool(_biometricEnabledKey, true);
  }

  Future<bool> authenticateWithBiometrics() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || !await isBiometricLoginEnabled()) return false;
    final authenticated = await _localAuthentication.authenticate(
      localizedReason: 'Confirma tu identidad para abrir Zap México',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
    if (!authenticated) return false;
    await _loadUser(firebaseUser);
    return true;
  }

  Future<void> completeGoogleProfile({
    required String name,
    required String city,
    required String phone,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null ||
        !firebaseUser.providerData.any(
          (provider) => provider.providerId == 'google.com',
        )) {
      throw StateError('Inicia sesión con Google para completar el perfil.');
    }
    await firebaseUser.updateDisplayName(name.trim());
    await _saveProfile(
      firebaseUser,
      name: name.trim(),
      email: firebaseUser.email ?? '',
      city: city.trim(),
      phone: phone.trim(),
      username: firebaseUser.email?.split('@').first ?? '',
    );
    needsProfileCompletion = false;
    await _loadUser(firebaseUser);
  }

  Future<bool> register({
    required String name,
    String username = '',
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
      username: username.trim().isEmpty
          ? email.trim().split('@').first
          : username.trim(),
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
    String username = '',
  }) async {
    final profile = <String, dynamic>{
      'uid': firebaseUser.uid,
      'name': name,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (city.isNotEmpty) profile['city'] = city;
    if (phone.isNotEmpty) profile['phone'] = phone;
    if (username.isNotEmpty) profile['username'] = username;
    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(profile, SetOptions(merge: true));
  }

  Future<void> updateProfile({
    required String name,
    required String username,
    File? profileImage,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || firebaseUser.isAnonymous) {
      throw StateError('Regístrate o inicia sesión para editar tu perfil.');
    }
    final normalizedName = name.trim();
    final normalizedUsername = username.trim();
    if (normalizedName.isEmpty || normalizedUsername.isEmpty) {
      throw ArgumentError('El nombre y el usuario son obligatorios.');
    }
    var photoUrl = currentUserModel?['photoUrl']?.toString() ?? '';
    if (profileImage != null) {
      final fileName = profileImage.path.split(RegExp(r'[\\/]')).last;
      final extension = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'jpg';
      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final reference = _storage.ref().child(
        'user_profiles/${firebaseUser.uid}/profile.$extension',
      );
      await reference.putFile(
        profileImage,
        SettableMetadata(contentType: contentType),
      );
      photoUrl = await reference.getDownloadURL();
    }
    await firebaseUser.updateDisplayName(normalizedName);
    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'uid': firebaseUser.uid,
      'name': normalizedName,
      'username': normalizedUsername,
      'email': firebaseUser.email ?? '',
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _loadUser(firebaseUser);
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
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_biometricEnabledKey);
    await preferences.remove(_biometricUserKey);
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
