import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../domain/forex_rate_model.dart';

/// Sebuah modal bottom sheet konverter valas premium bernuansa Slate-Emerald
/// yang interaktif, reaktif, dan keyboard-safe.
class ForexConverterSheet extends StatefulWidget {
  final ForexRateModel rate;

  const ForexConverterSheet({
    Key? key,
    required this.rate,
  }) : super(key: key);

  @override
  State<ForexConverterSheet> createState() => _ForexConverterSheetState();
}

class _ForexConverterSheetState extends State<ForexConverterSheet> {
  final _foreignController = TextEditingController();
  final _idrController = TextEditingController();
  
  final _foreignFocus = FocusNode();
  final _idrFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Default nilai awal: 1 unit mata uang asing
    _foreignController.text = '1';
    final initialIdr = widget.rate.rate;
    // Format awal IDR dengan titik ribuan
    _idrController.text = _formatIndonesianStyle(initialIdr, maxDecimals: 0);
  }

  @override
  void dispose() {
    _foreignController.dispose();
    _idrController.dispose();
    _foreignFocus.dispose();
    _idrFocus.dispose();
    super.dispose();
  }

  String _formatIndonesianStyle(double value, {int maxDecimals = 4}) {
    final formatter = NumberFormat.decimalPattern('id_ID');
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = maxDecimals;
    return formatter.format(value);
  }

  double? _parseIndonesianStyle(String text) {
    if (text.isEmpty) return null;
    // Bersihkan titik ribuan
    String sanitized = text.trim().replaceAll('.', '');
    // Ganti koma desimal dengan titik desimal standar Dart untuk parsing
    sanitized = sanitized.replaceAll(',', '.');
    return double.tryParse(sanitized);
  }

  void _onForeignChanged(String text) {
    // Hanya update IDR jika field foreign sedang difokuskan oleh pengguna
    if (!_foreignFocus.hasFocus) return;

    final val = _parseIndonesianStyle(text);
    if (val == null) {
      _idrController.text = '';
      return;
    }
    
    final idrVal = val * widget.rate.rate;
    _idrController.text = _formatIndonesianStyle(idrVal, maxDecimals: 0);
  }

  void _onIdrChanged(String text) {
    // Hanya update Foreign jika field IDR sedang difokuskan oleh pengguna
    if (!_idrFocus.hasFocus) return;

    final val = _parseIndonesianStyle(text);
    if (val == null) {
      _foreignController.text = '';
      return;
    }
    
    final foreignVal = val / widget.rate.rate;
    _foreignController.text = _formatIndonesianStyle(foreignVal, maxDecimals: 4);
  }

  void _applyPresetForeign(double amount) {
    HapticFeedback.selectionClick();
    _foreignFocus.requestFocus();
    _foreignController.text = _formatIndonesianStyle(amount, maxDecimals: 4);
    
    final idrVal = amount * widget.rate.rate;
    _idrController.text = _formatIndonesianStyle(idrVal, maxDecimals: 0);
  }

  void _applyPresetIdr(double amount) {
    HapticFeedback.selectionClick();
    _idrFocus.requestFocus();
    _idrController.text = _formatIndonesianStyle(amount, maxDecimals: 0);
    
    final foreignVal = amount / widget.rate.rate;
    _foreignController.text = _formatIndonesianStyle(foreignVal, maxDecimals: 4);
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    _foreignController.clear();
    _idrController.clear();
    _foreignFocus.requestFocus();
  }

  String _formatRateFull(double value) {
    return '1 ${widget.rate.code} = Rp ${NumberFormat('#,###.00', 'id_ID').format(value).replaceAll(',00', '')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    const emerald = Color(0xFF059669);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottom),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutQuad,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Handle Bar ─────────────────────────────────────
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 6),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // ─── Header Section ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(widget.rate.flag, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Konverter ${widget.rate.code}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              _formatRateFull(widget.rate.rate),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Input 1: Mata Uang Asing ─────────────────────────
                const Text(
                  'Mata Uang Asing',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _foreignFocus.hasFocus ? emerald : AppColors.border,
                      width: _foreignFocus.hasFocus ? 1.5 : 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Text(widget.rate.flag, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              widget.rate.code,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      VerticalDivider(color: AppColors.border, width: 1, thickness: 0.8),
                      Expanded(
                        child: TextField(
                          controller: _foreignController,
                          focusNode: _foreignFocus,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14),
                          ),
                          onChanged: _onForeignChanged,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ─── Preset Cepat Valas ──────────────────────────────
                SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [10.0, 50.0, 100.0, 500.0, 1000.0].map((amt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          label: Text(
                            '+${NumberFormat('#,###', 'id_ID').format(amt.round())} ${widget.rate.code}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: AppColors.border, width: 0.6),
                          onPressed: () => _applyPresetForeign(amt),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ─── Divider Animasi Panah / Swap ─────────────────────
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: emerald.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: emerald.withOpacity(0.2), width: 1),
                      ),
                      child: const Icon(
                        LucideIcons.arrowUpDown,
                        color: emerald,
                        size: 14,
                      ),
                    ),
                  ),
                ),

                // ─── Input 2: Rupiah (IDR) ──────────────────────────
                const Text(
                  'Rupiah Indonesia',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _idrFocus.hasFocus ? emerald : AppColors.border,
                      width: _idrFocus.hasFocus ? 1.5 : 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Text('🇮🇩', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 6),
                            Text(
                              'IDR',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      VerticalDivider(color: AppColors.border, width: 1, thickness: 0.8),
                      Expanded(
                        child: TextField(
                          controller: _idrController,
                          focusNode: _idrFocus,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [IndonesianCurrencyInputFormatter()],
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14),
                          ),
                          onChanged: _onIdrChanged,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ─── Preset Cepat Rupiah ─────────────────────────────
                SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      {'label': 'Rp 50K', 'value': 50000.0},
                      {'label': 'Rp 100K', 'value': 100000.0},
                      {'label': 'Rp 500K', 'value': 500000.0},
                      {'label': 'Rp 1 Juta', 'value': 1000000.0},
                      {'label': 'Rp 5 Juta', 'value': 5000000.0},
                    ].map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          label: Text(
                            item['label'] as String,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: AppColors.border, width: 0.6),
                          onPressed: () => _applyPresetIdr(item['value'] as double),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Action Button: Clear & Close ───────────────────
                Row(
                  children: [
                    // Tombol Hapus Semua
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _clearAll,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.danger, width: 0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.trash2, color: AppColors.danger, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Bersihkan',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Tombol Selesai
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emerald,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper extension to make widget onTap simplified
extension _WidgetOnTap on Widget {
  Widget onTap(VoidCallback action, {required Widget child}) {
    return InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }
}
