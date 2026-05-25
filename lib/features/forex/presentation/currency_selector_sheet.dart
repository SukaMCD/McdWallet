import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/colors.dart';
import '../domain/forex_rate_model.dart';
import '../providers/forex_provider.dart';

/// Bottom sheet untuk memilih/mengubah daftar mata uang yang dipantau.
/// Mendukung pencarian instan dan pembatasan maksimal 5 pilihan.
class CurrencySelectorSheet extends ConsumerStatefulWidget {
  const CurrencySelectorSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<CurrencySelectorSheet> createState() =>
      _CurrencySelectorSheetState();
}

class _CurrencySelectorSheetState
    extends ConsumerState<CurrencySelectorSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filtered {
    if (_query.isEmpty) return CurrencyMetadata.allCurrencies;
    return CurrencyMetadata.allCurrencies.where((c) {
      return c['code']!.toLowerCase().contains(_query) ||
          c['name']!.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedCurrenciesProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Column(
        children: [
          // ─── Handle ─────────────────────────────────────────
          Padding(
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

          // ─── Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pilih Mata Uang',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                // Counter badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected.length >= maxSelectedCurrencies
                        ? AppColors.expense.withOpacity(0.12)
                        : const Color(0xFF059669).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${selected.length}/$maxSelectedCurrencies',
                    style: TextStyle(
                      color: selected.length >= maxSelectedCurrencies
                          ? AppColors.expense
                          : const Color(0xFF059669),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.x,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ─── Info max ────────────────────────────────────────
          if (selected.length >= maxSelectedCurrencies)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.alertCircle,
                        size: 14, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Maksimal 5 mata uang. Hapus centang untuk mengganti.',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 200.ms),

          // ─── Search bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Cari kode atau nama mata uang…',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // ─── List ────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: bottom + 24,
              ),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final c      = _filtered[index];
                final code   = c['code']!;
                final name   = c['name']!;
                final flag   = c['flag']!;
                final isOn   = selected.contains(code);
                final isFull = selected.length >= maxSelectedCurrencies;
                final isDisabled = !isOn && isFull;

                return _CurrencyTile(
                  code: code,
                  name: name,
                  flag: flag,
                  isSelected: isOn,
                  isDisabled: isDisabled,
                  onTap: () {
                    if (isDisabled) return;
                    HapticFeedback.selectionClick();
                    ref
                        .read(selectedCurrenciesProvider.notifier)
                        .toggle(code);
                  },
                ).animate().fadeIn(
                      delay: Duration(milliseconds: index * 18),
                      duration: 200.ms,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile Widget ──────────────────────────────────────────────

class _CurrencyTile extends StatelessWidget {
  final String code;
  final String name;
  final String flag;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _CurrencyTile({
    required this.code,
    required this.name,
    required this.flag,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF059669);

    return Opacity(
      opacity: isDisabled ? 0.38 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? emerald.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? emerald.withOpacity(0.35) : AppColors.border,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Flag emoji
                  Text(flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),

                  // Code + name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? emerald : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? emerald : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(LucideIcons.check,
                            color: Colors.white, size: 12)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
