import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../transactions/domain/transaction_model.dart';

class ExportSheet extends StatefulWidget {
  final List<TransactionModel> transactions;

  const ExportSheet({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  String _selectedRange = 'all';
  String _selectedFormat = 'csv';
  bool _isExporting = false;

  List<TransactionModel> get _filteredTransactions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_selectedRange == '7days') {
      final limitDate = today.subtract(const Duration(days: 7));
      return widget.transactions.where((tx) => tx.date.isAfter(limitDate)).toList();
    } else if (_selectedRange == '30days') {
      final limitDate = today.subtract(const Duration(days: 30));
      return widget.transactions.where((tx) => tx.date.isAfter(limitDate)).toList();
    } else if (_selectedRange == 'month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      return widget.transactions.where((tx) => tx.date.isAfter(startOfMonth) || tx.date.isAtSameMomentAs(startOfMonth)).toList();
    }
    
    return widget.transactions;
  }

  String _generateCSV(List<TransactionModel> txs) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Tanggal,Tipe,Dompet Asal,Dompet Tujuan,Kategori,Nominal,Deskripsi');
    
    for (var tx in txs) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(tx.date);
      final walletName = tx.wallet?.name ?? '';
      final toWalletName = tx.toWallet?.name ?? '';
      final categoryName = tx.category?.name ?? '';
      final desc = tx.description?.replaceAll('"', '""') ?? '';
      
      buffer.writeln(
        '"${tx.id}","$dateStr","${tx.type}","$walletName","$toWalletName","$categoryName",${tx.amount},"$desc"'
      );
    }
    return buffer.toString();
  }

  String _generateSummaryText(List<TransactionModel> txs) {
    final buffer = StringBuffer();
    final totalIn = txs.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
    final totalOut = txs.fold(0.0, (sum, t) {
      if (t.type == 'expense') {
        return sum + t.amount;
      } else if (t.type == 'transfer' && t.adminFee != null) {
        return sum + t.adminFee!;
      }
      return sum;
    });
    final netFlow = totalIn - totalOut;

    buffer.writeln('========== LAPORAN KEUANGAN MCDWALLET ==========');
    buffer.writeln('Diekspor pada: ${Formatters.formatDateTime(DateTime.now())}');
    buffer.writeln('Jumlah Transaksi: ${txs.length}');
    buffer.writeln('------------------------------------------------');
    buffer.writeln('Total Pemasukan : ${Formatters.formatCurrency(totalIn)}');
    buffer.writeln('Total Pengeluaran: ${Formatters.formatCurrency(totalOut)}');
    buffer.writeln('Arus Kas Bersih  : ${Formatters.formatCurrency(netFlow)}');
    buffer.writeln('================================================');
    buffer.writeln();
    buffer.writeln('RINCIAN MUTASI:');
    
    for (var tx in txs) {
      final dateStr = Formatters.formatDateShort(tx.date);
      final prefix = tx.type == 'income' ? '[MASUK]' : tx.type == 'expense' ? '[KELUAR]' : '[TRANSFER]';
      final detail = tx.type == 'transfer' 
          ? '${tx.wallet?.name} -> ${tx.toWallet?.name}${tx.adminFee != null && tx.adminFee! > 0 ? " (Biaya Admin: ${Formatters.formatCurrency(tx.adminFee!)})" : ""}'
          : '${tx.category?.name ?? "Lainnya"} (${tx.wallet?.name})';
      
      buffer.writeln('$dateStr $prefix ${Formatters.formatCurrency(tx.amount)}');
      buffer.writeln('Detail: $detail');
      if (tx.description != null && tx.description!.isNotEmpty) {
        buffer.writeln('Catatan: "${tx.description}"');
      }
      buffer.writeln('---');
    }
    return buffer.toString();
  }

  void _handleCopy() async {
    setState(() {
      _isExporting = true;
    });

    final txs = _filteredTransactions;
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tidak ada transaksi untuk diekspor.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() {
        _isExporting = false;
      });
      return;
    }

    final String exportData = _selectedFormat == 'csv' 
        ? _generateCSV(txs) 
        : _generateSummaryText(txs);

    await Clipboard.setData(ClipboardData(text: exportData));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedFormat == 'csv'
                ? 'CSV disalin ke clipboard!'
                : 'Laporan disalin ke clipboard!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txs = _filteredTransactions;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ──
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Title ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ekspor Laporan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.x, color: AppColors.textSecondary, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Range ──
              const Text(
                'RENTANG',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('all', 'Semua'),
                  _buildFilterChip('month', 'Bulan Ini'),
                  _buildFilterChip('30days', '30 Hari'),
                  _buildFilterChip('7days', '7 Hari'),
                ],
              ),
              const SizedBox(height: 24),

              // ── Format ──
              const Text(
                'FORMAT',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildFormatCard('csv', 'CSV', LucideIcons.sheet)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildFormatCard('text', 'Teks', LucideIcons.fileText)),
                ],
              ),
              const SizedBox(height: 24),

              // ── Summary ──
              AppCard(
                color: AppColors.surfaceAlt,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.database, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TARGET', style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                          const SizedBox(height: 3),
                          Text(
                            '${txs.length} Transaksi',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Action ──
              CustomButton(
                text: 'Salin ke Clipboard',
                icon: LucideIcons.copy,
                isLoading: _isExporting,
                onPressed: _handleCopy,
              ),
              const SizedBox(height: 10),
              
              const Center(
                child: Text(
                  'Data disalin ke memori. Tempel di Excel, Sheets, atau WhatsApp.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedRange == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRange = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceAlt : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary.withOpacity(0.4) : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildFormatCard(String format, String label, IconData icon) {
    final isSelected = _selectedFormat == format;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFormat = format;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceAlt : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary.withOpacity(0.4) : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
