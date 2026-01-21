import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _userNameKey = 'last_user_name';
  static const String _userRoleKey = 'last_user_role';
  static const String _userLevelKey = 'last_user_level';

  /// Check if the device is capable of biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Authenticate the user using biometrics
  Future<bool> authenticate() async {
    // Defense in depth: Check preference before attempting auth
    final enabled = await getBiometricEnabled();
    if (!enabled) return false;

    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à l\'application',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Get available biometrics (Face, Fingerprint, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return <BiometricType>[];
    }
  }

  // --- Persistence Methods ---

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> saveUserCredentials(String username, String role, String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, username);
    await prefs.setString(_userRoleKey, role);
    await prefs.setString(_userLevelKey, level);
  }

  Future<Map<String, String>?> getUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_userNameKey);
    final role = prefs.getString(_userRoleKey);
    final level = prefs.getString(_userLevelKey);

    if (username != null && role != null && level != null) {
      return {
        'username': username,
        'role': role,
        'level': level,
      };
    }
    return null;
  }

  // --- Full Profile Persistence ---

  Future<void> saveUserProfile(String username, Map<String, String> profile) async {
    final prefs = await SharedPreferences.getInstance();
    // Key example: profile_admin, profile_jean
    final key = 'profile_$username';
    
    for (var entry in profile.entries) {
      await prefs.setString('${key}_${entry.key}', entry.value);
    }
    
    // Also update credentials if core fields changed
    if (profile.containsKey('role') || profile.containsKey('level')) {
       await saveUserCredentials(username, profile['role']!, profile['level']!);
    }
  }

  Future<Map<String, String>?> getUserProfile(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'profile_$username';
    
    // Check if at least name exists to see if profile is initialized
    final name = prefs.getString('${key}_name');
    if (name == null) return null;

    return {
      'name': name,
      'email': prefs.getString('${key}_email') ?? '',
      'phone': prefs.getString('${key}_phone') ?? '',
      'role': prefs.getString('${key}_role') ?? '',
      'level': prefs.getString('${key}_level') ?? '',
      'bio': prefs.getString('${key}_bio') ?? '',
      'imagePath': prefs.getString('${key}_imagePath') ?? '',
    };
  }
}
