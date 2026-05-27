import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../domain/forex_rate_model.dart';
import '../providers/forex_provider.dart';
import 'currency_selector_sheet.dart';
import 'forex_converter_sheet.dart';

/// Sebuah widget dashboard premium bernuansa Slate-Charcoal untuk memantau
/// kurs mata uang asing secara real-time dengan caching cerdas & manual refresh cooldown.
class ForexDashboardWidget extends ConsumerStatefulWidget {
  const ForexDashboardWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<ForexDashboardWidget> createState() => _ForexDashboardWidgetState();
}

class _ForexDashboardWidgetState extends ConsumerState<ForexDashboardWidget> {
  void _showCurrencySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CurrencySelectorSheet(),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Belum pernah';
    final formatter = DateFormat('HH:mm', 'id_ID');
    return 'Pukul ${formatter.format(dateTime.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(forexRatesProvider);
    final lastUpdateAsync = ref.watch(forexLastUpdateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header Section ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kurs Asing',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                lastUpdateAsync.when(
                  loading: () => const Text(
                    'Memeriksa waktu update...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  error: (_, __) => const Text(
                    'Gagal memuat waktu update',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  data: (time) => Text(
                    time != null ? 'Pembaruan terakhir: ${_formatTime(time)}' : 'Belum pernah diperbarui',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            // Tombol Pengaturan (Pilih Mata Uang)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showCurrencySelector(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: const Icon(
                  LucideIcons.sliders,
                  color: AppColors.textSecondary,
                  size: 15,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 350.ms),
        const SizedBox(height: 12),

        // ─── Body Section ────────────────────────────────────
        ratesAsync.when(
          loading: () => Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: AppColors.danger, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    'Koneksi gagal: Tampil data lokal/offline.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => ref.read(forexRatesProvider.notifier).refreshRates(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          data: (rates) {
            if (rates.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.globe,
                        size: 32,
                        color: AppColors.textMuted.withOpacity(0.22),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Belum ada mata uang terpilih',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _showCurrencySelector(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Pilih Sekarang', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 98,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: rates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final rate = rates[index];
                  return _ForexCardItem(rate: rate);
                },
              ),
            ).animate().fadeIn(duration: 380.ms);
          },
        ),
      ],
    );
  }
}

class _ForexCardItem extends StatelessWidget {
  final ForexRateModel rate;

  const _ForexCardItem({
    Key? key,
    required this.rate,
  }) : super(key: key);

  String _formatCompactRate(double value) {
    if (value >= 1000) {
      return 'Rp ${NumberFormat('#,###', 'id_ID').format(value.round())}';
    } else if (value >= 100) {
      return 'Rp ${NumberFormat('#,###', 'id_ID').format(value.round())}';
    } else {
      return 'Rp ${value.toStringAsFixed(2).replaceAll('.', ',')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final change = rate.changePercent;
    final isUp = rate.trend == ForexTrend.up;
    final isDown = rate.trend == ForexTrend.down;

    Color trendColor = AppColors.textMuted;
    IconData trendIcon = LucideIcons.minus;
    String sign = '';

    if (isUp) {
      trendColor = const Color(0xFF059669); // Emerald Green
      trendIcon = LucideIcons.trendingUp;
      sign = '+';
    } else if (isDown) {
      trendColor = AppColors.danger; // Red
      trendIcon = LucideIcons.trendingDown;
      sign = '';
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ForexConverterSheet(rate: rate),
        );
      },
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row 1: Flag & Code
            Row(
              children: [
                Text(rate.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  rate.code,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),

            // Row 2: Exchange Rate
            Text(
              _formatCompactRate(rate.rate),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: -0.3,
              ),
            ),

            // Row 3: Trend
            Row(
              children: [
                Icon(
                  trendIcon,
                  size: 9,
                  color: trendColor,
                ),
                const SizedBox(width: 3),
                Text(
                  '$sign${change.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: trendColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
