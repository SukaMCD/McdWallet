import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/security_service.dart';

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

class SecurityState {
  final bool isLocked;
  final bool hasPin;
  final bool isBiometricsSupported;

  SecurityState({
    required this.isLocked,
    required this.hasPin,
    required this.isBiometricsSupported,
  });

  SecurityState copyWith({
    bool? isLocked,
    bool? hasPin,
    bool? isBiometricsSupported,
  }) {
    return SecurityState(
      isLocked: isLocked ?? this.isLocked,
      hasPin: hasPin ?? this.hasPin,
      isBiometricsSupported: isBiometricsSupported ?? this.isBiometricsSupported,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final SecurityService _service;

  SecurityNotifier(this._service)
      : super(SecurityState(isLocked: true, hasPin: false, isBiometricsSupported: false)) {
    init();
  }

  // Menginisialisasi status keamanan lokal
  Future<void> init() async {
    final hasPin = await _service.hasPin();
    final isBioSupported = await _service.isBiometricsSupported();
    state = SecurityState(
      isLocked: hasPin, // Jika PIN sudah disetel, aplikasi dimulai dalam kondisi terkunci
      hasPin: hasPin,
      isBiometricsSupported: isBioSupported,
    );
  }

  // Membuka kunci aplikasi
  void unlock() {
    state = state.copyWith(isLocked: false);
  }

  // Mengunci aplikasi kembali (misal saat masuk background)
  void lock() {
    if (state.hasPin) {
      state = state.copyWith(isLocked: true);
    }
  }

  // Merefresh status keamanan
  Future<void> refresh() async {
    await init();
  }
}

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  final service = ref.watch(securityServiceProvider);
  return SecurityNotifier(service);
});
