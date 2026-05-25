import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/security_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  void _onNumberTap(int number) {
    HapticFeedback.lightImpact();

    if (_errorMessage.isNotEmpty) {
      setState(() {
        _errorMessage = '';
      });
    }

    if (!_isConfirming) {
      if (_pin.length < 6) {
        setState(() {
          _pin += number.toString();
        });
      }

      if (_pin.length == 6) {
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            _isConfirming = true;
          });
        });
      }
    } else {
      if (_confirmPin.length < 6) {
        setState(() {
          _confirmPin += number.toString();
        });
      }

      if (_confirmPin.length == 6) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _verifyAndSavePin();
        });
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    if (!_isConfirming) {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
        });
      }
    } else {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        });
      } else {
        setState(() {
          _isConfirming = false;
          _pin = '';
        });
      }
    }
  }

  Future<void> _verifyAndSavePin() async {
    if (_pin == _confirmPin) {
      final success = await ref.read(securityServiceProvider).savePin(_pin);
      if (success) {
        await ref.read(securityProvider.notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('PIN Keamanan berhasil disetel!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Gagal menyimpan PIN. Coba lagi.';
          _pin = '';
          _confirmPin = '';
          _isConfirming = false;
        });
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'PIN tidak cocok! Silakan ulangi.';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePin = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // ── Progress Steps ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(1, !_isConfirming),
                  Container(width: 40, height: 1.5, color: _isConfirming ? AppColors.primary : AppColors.border),
                  _buildStepIndicator(2, _isConfirming),
                ],
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 36),

              // ── Icon ──
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 24),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // ── Title ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _isConfirming ? 'Konfirmasi PIN' : 'Setel PIN Keamanan',
                  key: ValueKey(_isConfirming),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : _isConfirming 
                        ? 'Masukkan kembali 6-digit PIN Anda' 
                        : 'PIN digunakan setiap kali membuka aplikasi',
                style: TextStyle(
                  color: _errorMessage.isNotEmpty ? AppColors.danger : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: _errorMessage.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              // ── PIN Dots ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < activePin.length;
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
              ),
              
              const Spacer(),
              
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
                      const SizedBox(width: 72, height: 72),
                      _buildKeyboardButton(0),
                      _buildBackspaceButton(),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primary : AppColors.surface,
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$step',
        style: TextStyle(
          color: isActive ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
