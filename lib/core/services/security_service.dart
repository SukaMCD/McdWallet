import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  final LocalAuthentication _auth = LocalAuthentication();
  
  static const String _pinKey = 'security_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';

  // Mengecek apakah perangkat mendukung dan memiliki data biometrik aktif
  Future<bool> isBiometricsSupported() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  // Memicu pop-up sensor biometrik native perangkat (Fingerprint / Face ID)
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Scan sidik jari atau Face ID Anda untuk masuk ke McdWallet',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Menyimpan 6-digit PIN secara lokal di SharedPreferences
  Future<bool> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_pinKey, pin);
  }

  // Mengambil data PIN yang tersimpan
  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  // Mengecek apakah user sudah pernah menyetel PIN
  Future<bool> hasPin() async {
    final pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }

  // Mengecek apakah preferensi biometrik diaktifkan oleh user
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? true; // Default true jika perangkat mendukung
  }

  // Mengubah preferensi biometrik
  Future<bool> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(_biometricEnabledKey, enabled);
  }
}
