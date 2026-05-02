import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    this.languageCode = 'en',
    this.isOrganizer = false,
    this.emailVerified = false,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String languageCode;
  final bool isOrganizer;
  final bool emailVerified;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  // For Android with google_sign_in v7+, provide your Firebase Web client ID.
  static const String _googleServerClientIdFromEnvironment =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');

  static const String _googleServerClientIdFallback =
      '792779153878-79s3qguve0k7bar7r72430v18mapbgtr.apps.googleusercontent.com';

  static String get _googleServerClientId {
    final configured = _googleServerClientIdFromEnvironment.trim();
    return configured.isEmpty ? _googleServerClientIdFallback : configured;
  }

  // Meta can reject `email` for apps still in development configuration.
  // Keep this off by default to avoid developer-only invalid scope warnings.
  static const bool _requestFacebookEmailScope = bool.fromEnvironment(
    'FACEBOOK_REQUEST_EMAIL_SCOPE',
    defaultValue: false,
  );

  AuthUser? _lastAuthenticatedUser;

  bool get hasRegisteredUsers => _auth.currentUser != null;

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore sign-out errors from provider SDK; Firebase signOut is primary.
    }

    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // Ignore provider SDK sign-out failures.
    }

    await _auth.signOut();
    _lastAuthenticatedUser = null;
  }

  Future<String> requestOtp({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (email.isEmpty) {
      throw Exception('Email is required for OTP verification.');
    }
    return '123456';
  }

  Future<AuthUser> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    bool isOrganizer = false,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Unable to create account.');
    }

    await firebaseUser.updateDisplayName(name.trim());
    await firebaseUser.updatePhotoURL(null);
    await firebaseUser.reload();

    final appUser = _buildAuthUser(
      _auth.currentUser ?? firebaseUser,
      phone: phone.trim(),
      isOrganizer: isOrganizer,
    );
    await _saveUserProfile(appUser, isNewUser: true);
    _lastAuthenticatedUser = appUser;
    return appUser;
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Unable to sign in.');
    }

    final appUser = await _ensureUserProfile(firebaseUser);
    _lastAuthenticatedUser = appUser;
    return appUser;
  }

  Future<bool> verifyOtp({required String otp}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final normalized = otp.replaceAll(RegExp(r'\D'), '');
    return normalized == '123456';
  }

  Future<AuthUser> updateProfile({
    required String name,
    required String phone,
    required String photoUrl,
    Uint8List? photoBytes,
    String? photoFileExtension,
    bool removePhoto = false,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('You need to be logged in to update profile details.');
    }

    final trimmedName = name.trim();
    final normalizedPhone = phone.trim();
    final normalizedPhotoUrl = photoUrl.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Name is required.');
    }

    if (!RegExp(r'^\d{10}$').hasMatch(normalizedPhone)) {
      throw Exception('Phone must be exactly 10 digits.');
    }

    final existingProfile = await _ensureUserProfile(firebaseUser);

    if (firebaseUser.displayName != trimmedName) {
      await firebaseUser.updateDisplayName(trimmedName);
    }

    var resolvedPhotoUrl = normalizedPhotoUrl;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      resolvedPhotoUrl = await _uploadProfilePhoto(
        uid: firebaseUser.uid,
        photoBytes: photoBytes,
        fileExtension: photoFileExtension,
      );
    } else if (removePhoto) {
      resolvedPhotoUrl = '';
    }

    if ((firebaseUser.photoURL ?? '') != resolvedPhotoUrl) {
      await firebaseUser.updatePhotoURL(
        resolvedPhotoUrl.isEmpty ? null : resolvedPhotoUrl,
      );
    }

    await firebaseUser.reload();
    final refreshedUser = _auth.currentUser ?? firebaseUser;

    final updated = AuthUser(
      uid: refreshedUser.uid,
      name: trimmedName,
      email: existingProfile.email.isNotEmpty
          ? existingProfile.email
          : (refreshedUser.email ?? ''),
      phone: normalizedPhone,
      photoUrl: resolvedPhotoUrl,
      languageCode: existingProfile.languageCode,
      isOrganizer: existingProfile.isOrganizer,
      emailVerified: refreshedUser.emailVerified,
    );

    await _saveUserProfile(updated, isNewUser: false);
    _lastAuthenticatedUser = updated;
    return updated;
  }

  Future<String> _uploadProfilePhoto({
    required String uid,
    required Uint8List photoBytes,
    String? fileExtension,
  }) async {
    var normalizedExtension = (fileExtension ?? 'jpg').toLowerCase();
    if (normalizedExtension.startsWith('.')) {
      normalizedExtension = normalizedExtension.substring(1);
    }

    switch (normalizedExtension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'heic':
        break;
      default:
        normalizedExtension = 'jpg';
    }

    final storageRef = _storage
        .ref()
        .child('users')
        .child(uid)
        .child(
          'profile_${DateTime.now().millisecondsSinceEpoch}.$normalizedExtension',
        );

    await storageRef.putData(
      photoBytes,
      SettableMetadata(contentType: 'image/$normalizedExtension'),
    );

    return storageRef.getDownloadURL();
  }

  Future<bool> biometricLogin() async {
    if (_lastAuthenticatedUser == null && _auth.currentUser == null) {
      return false;
    }

    final auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics;
      final supported = await auth.isDeviceSupported();
      if (!canCheck || !supported) {
        return false;
      }

      return await auth.authenticate(
        localizedReason: 'Authenticate to access EventBridge',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (_) {
      return false;
    }
  }

  AuthUser? getRememberedUser() {
    if (_lastAuthenticatedUser != null) {
      return _lastAuthenticatedUser;
    }

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    final current = _buildAuthUser(firebaseUser);
    _lastAuthenticatedUser = current;
    return current;
  }

  Future<AuthUser> updateLanguagePreference({
    required String languageCode,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('You need to be logged in to update language settings.');
    }

    final normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final currentProfile = await _ensureUserProfile(firebaseUser);
    final updated = AuthUser(
      uid: currentProfile.uid,
      name: currentProfile.name,
      email: currentProfile.email,
      phone: currentProfile.phone,
      photoUrl: currentProfile.photoUrl,
      languageCode: normalizedLanguageCode,
      isOrganizer: currentProfile.isOrganizer,
      emailVerified: currentProfile.emailVerified,
    );

    await _saveUserProfile(updated, isNewUser: false);
    _lastAuthenticatedUser = updated;
    return updated;
  }

  Future<AuthUser> socialLogin({required String provider}) async {
    switch (provider.toLowerCase()) {
      case 'google':
        return _googleLogin();
      case 'facebook':
        return _facebookLogin();
      default:
        throw Exception('Unsupported sign-in provider.');
    }
  }

  Future<AuthUser> _googleLogin() async {
    try {
      await _initializeGoogleSignIn();

      GoogleSignInAccount account;
      try {
        account = await _googleSignIn.authenticate(scopeHint: const ['email']);
      } on GoogleSignInException catch (error) {
        // Some Android builds can report a false cancel on the first attempt.
        if (error.code == GoogleSignInExceptionCode.canceled) {
          final recovered = await _googleSignIn
              .attemptLightweightAuthentication();
          if (recovered != null) {
            account = recovered;
          } else {
            throw Exception('GoogleSignInExceptionCode.canceled');
          }
        } else {
          rethrow;
        }
      }

      final authentication = account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google Sign-In did not return an ID token. Recheck Firebase OAuth setup and try again.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Google sign-in failed.');
      }

      final appUser = await _ensureUserProfile(firebaseUser);
      _lastAuthenticatedUser = appUser;
      return appUser;
    } on FirebaseAuthException catch (error) {
      throw Exception(
        _socialFirebaseAuthErrorMessage(error, provider: 'Google'),
      );
    } catch (error) {
      throw Exception(_googleAuthErrorMessage(error));
    }
  }

  Future<AuthUser> _facebookLogin() async {
    try {
      await FacebookAuth.instance.logOut();
      final permissions = _requestFacebookEmailScope
          ? const ['email', 'public_profile']
          : const ['public_profile'];

      LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: permissions,
      );

      final loginMessage = loginResult.message?.toLowerCase() ?? '';
      final isInvalidEmailScope =
          loginResult.status != LoginStatus.success &&
          _requestFacebookEmailScope &&
          loginMessage.contains('invalid scope') &&
          loginMessage.contains('email');
      if (isInvalidEmailScope) {
        // Some Meta app configurations reject `email` during development.
        // Retry with `public_profile` so Firebase sign-in can still proceed.
        loginResult = await FacebookAuth.instance.login(
          permissions: const ['public_profile'],
        );
      }

      if (loginResult.status != LoginStatus.success ||
          loginResult.accessToken == null) {
        final details = loginResult.message?.trim();
        throw Exception(
          details == null || details.isEmpty
              ? 'Facebook sign-in failed. Make sure Facebook App ID and client token are configured in Android/iOS native files.'
              : 'Facebook sign-in failed: $details',
        );
      }

      final credential = FacebookAuthProvider.credential(
        loginResult.accessToken!.tokenString,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Facebook sign-in failed.');
      }

      final appUser = await _ensureUserProfile(firebaseUser);
      _lastAuthenticatedUser = appUser;
      return appUser;
    } on FirebaseAuthException catch (error) {
      throw Exception(
        _socialFirebaseAuthErrorMessage(error, provider: 'Facebook'),
      );
    }
  }

  String _socialFirebaseAuthErrorMessage(
    FirebaseAuthException error, {
    required String provider,
  }) {
    switch (error.code) {
      case 'operation-not-allowed':
        return '$provider sign-in is disabled in Firebase Authentication. Open Firebase Console > Authentication > Sign-in method and enable $provider.';
      case 'invalid-credential':
      case 'invalid-idp-response':
      case 'invalid-oauth-response':
        return '$provider returned an invalid credential. Re-check OAuth setup (SHA fingerprints, package name, client IDs) and reinstall the app.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email using a different sign-in method. Sign in with the original method first, then link $provider from account settings.';
      case 'network-request-failed':
        return '$provider sign-in failed due to a network issue. Check internet connection and try again.';
      case 'too-many-requests':
        return 'Too many authentication attempts. Wait a few minutes and try again.';
      case 'user-disabled':
        return 'This Firebase user account is disabled.';
      default:
        return error.message ?? '$provider sign-in failed (${error.code}).';
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleSignInInitialized) {
      return;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (_googleServerClientId.isEmpty) {
        throw Exception(
          'Google Sign-In is not configured for Android. '
          'Set GOOGLE_SERVER_CLIENT_ID to your Firebase Web OAuth client ID or keep the fallback client ID in sync with Firebase.',
        );
      }
      await _googleSignIn.initialize(serverClientId: _googleServerClientId);
    } else {
      await _googleSignIn.initialize();
    }

    _isGoogleSignInInitialized = true;
  }

  String _googleAuthErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('ApiException: 10') ||
        raw.contains('code: 10') ||
        raw.contains('DEVELOPER_ERROR')) {
      return 'Google Sign-In failed with error 10 (developer configuration issue). Reinstall the app, run flutter clean, confirm the Android package name matches Firebase, and make sure the downloaded google-services.json is the latest one.';
    }
    if (raw.contains('ApiException: 12500') ||
        raw.contains('code: 12500') ||
        raw.contains('SIGN_IN_FAILED')) {
      return 'Google Sign-In failed. Usually this means Firebase Google provider is not enabled, the Web client ID is wrong, or the app is using an old build. Re-download google-services.json and rebuild the app.';
    }
    if (raw.contains('ApiException: 7') || raw.contains('code: 7')) {
      return 'Google Sign-In failed because of a network/server issue. Check internet access and try again.';
    }
    if (raw.contains('ApiException: 8') || raw.contains('code: 8')) {
      return 'Google Sign-In failed because Google Play services is unavailable or outdated on the device/emulator.';
    }
    if (raw.contains('clientConfigurationError') ||
        raw.contains('serverClientId must be provided')) {
      return 'Google Sign-In Android setup is incomplete. Add OAuth client IDs in Firebase (including Web client ID), redownload google-services.json, and run with --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.';
    }
    if (raw.contains('activity is canceled by the user')) {
      return 'Google Sign-In flow was interrupted by Android. If you selected an account and still see this, Firebase OAuth is likely still mismatched. Re-add SHA-1/SHA-256 in Firebase, redownload google-services.json, uninstall app, then rebuild.';
    }
    if (raw.contains('GoogleSignInExceptionCode.canceled') ||
        raw.contains('sign_in_canceled')) {
      return 'Google sign-in was cancelled or interrupted. Please tap Continue with Google again. If it still happens after account selection, run flutter clean, reinstall app, and verify Firebase Authentication > Sign-in method > Google is enabled.';
    }
    return raw.replaceFirst('Exception: ', '');
  }

  AuthUser _buildAuthUser(
    User firebaseUser, {
    String phone = '',
    bool isOrganizer = false,
  }) {
    return AuthUser(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!.trim()
          : (firebaseUser.email?.split('@').first ?? 'EventBridge User'),
      email: firebaseUser.email ?? '',
      phone: phone,
      photoUrl: firebaseUser.photoURL ?? '',
      languageCode: 'en',
      isOrganizer: isOrganizer,
      emailVerified: firebaseUser.emailVerified,
    );
  }

  Future<AuthUser> _ensureUserProfile(User firebaseUser) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    if (!snapshot.exists) {
      final appUser = _buildAuthUser(firebaseUser);
      await _saveUserProfile(appUser, isNewUser: true);
      return appUser;
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    return AuthUser(
      uid: firebaseUser.uid,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : (firebaseUser.displayName?.trim().isNotEmpty == true
                ? firebaseUser.displayName!.trim()
                : (firebaseUser.email?.split('@').first ?? 'EventBridge User')),
      email: (data['email'] as String?) ?? firebaseUser.email ?? '',
      phone: (data['phone'] as String?) ?? '',
      photoUrl: (data['photoUrl'] as String?) ?? firebaseUser.photoURL ?? '',
      languageCode: _normalizeLanguageCode(
        (data['languageCode'] as String?) ?? 'en',
      ),
      isOrganizer: (data['isOrganizer'] as bool?) ?? false,
      emailVerified: firebaseUser.emailVerified,
    );
  }

  Future<void> _saveUserProfile(
    AuthUser user, {
    required bool isNewUser,
  }) async {
    final data = <String, dynamic>{
      'id': user.uid,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'photoUrl': user.photoUrl,
      'languageCode': _normalizeLanguageCode(user.languageCode),
      'role': user.isOrganizer ? 'organizer' : 'user',
      'isOrganizer': user.isOrganizer,
      'isVerifiedOrganizer': false,
      'isBlocked': false,
      'themeMode': 'light',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isNewUser) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['totalBookings'] = 0;
      data['totalSpent'] = 0;
      data['walletBalance'] = 0;
      data['eventsAttended'] = 0;
      data['favoriteCategory'] = 'concert';
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }
}

String _normalizeLanguageCode(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'hi':
      return 'hi';
    case 'gu':
      return 'gu';
    default:
      return 'en';
  }
}
