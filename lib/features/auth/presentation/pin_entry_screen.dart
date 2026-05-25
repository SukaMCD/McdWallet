import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/security_provider.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  String _enteredPin = '';
  String _errorMessage = '';
  bool _isBiometricChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricsOnStartup();
    });
  }

  Future<void> _checkBiometricsOnStartup() async {
    final securityState = ref.read(securityProvider);
    final securityService = ref.read(securityServiceProvider);
    
    final isBioEnabled = await securityService.isBiometricEnabled();
    
    if (securityState.isBiometricsSupported && isBioEnabled) {
      setState(() {
        _isBiometricChecking = true;
      });
      final authenticated = await securityService.authenticateWithBiometrics();
      setState(() {
        _isBiometricChecking = false;
      });

      if (authenticated) {
        ref.read(securityProvider.notifier).unlock();
      }
    }
  }

  Future<void> _triggerBiometricManual() async {
    setState(() {
      _isBiometricChecking = true;
    });
    final authenticated = await ref.read(securityServiceProvider).authenticateWithBiometrics();
    setState(() {
      _isBiometricChecking = false;
    });

    if (authenticated) {
      ref.read(securityProvider.notifier).unlock();
    }
  }

  void _onNumberTap(int number) {
    HapticFeedback.lightImpact();

    if (_errorMessage.isNotEmpty) {
      setState(() {
        _errorMessage = '';
      });
    }

    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += number.toString();
      });
    }

    if (_enteredPin.length == 6) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _verifyPin();
      });
    }
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    final savedPin = await ref.read(securityServiceProvider).getPin();
    if (savedPin == _enteredPin) {
      ref.read(securityProvider.notifier).unlock();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'PIN salah! Ulangi kembali.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Lock Icon ──
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Icon(LucideIcons.lock, color: AppColors.textPrimary, size: 24),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms),

              const SizedBox(height: 24),

              const Text(
                'Masukkan PIN',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: 8),

              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : '6-digit PIN untuk mengakses McdWallet',
                style: TextStyle(
                  color: _errorMessage.isNotEmpty ? AppColors.danger : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: _errorMessage.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: 36),
              
              // ── PIN Dots ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
              
              const Spacer(flex: 2),
              
              // ── Numpad ──
              Column(
                children: [
                  _buildKeyboardRow([1, 2, 3]),
                  const SizedBox(height: 20),
                  _buildKeyboardRow([4, 5, 6]),
                  const SizedBox(height: 20),
                  _buildKeyboardRow([7, 8, 9]),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (securityState.isBiometricsSupported)
                        _buildBiometricButton()
                      else
                        const SizedBox(width: 72, height: 72),
                      _buildKeyboardButton(0),
                      _buildBackspaceButton(),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(List<int> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildKeyboardButton(n)).toList(),
    );
  }

  Widget _buildKeyboardButton(int number) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberTap(number),
        borderRadius: BorderRadius.circular(36),
        splashColor: AppColors.textMuted.withOpacity(0.1),
        highlightColor: AppColors.textMuted.withOpacity(0.05),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isBiometricChecking ? null : _triggerBiometricManual,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: _isBiometricChecking
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, 
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : const Icon(
                  LucideIcons.fingerprint,
                  color: AppColors.primary,
                  size: 26,
                ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackspace,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: const Icon(
            LucideIcons.delete,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
