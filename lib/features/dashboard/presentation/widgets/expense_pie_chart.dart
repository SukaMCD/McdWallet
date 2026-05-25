import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../transactions/domain/transaction_model.dart';

class ExpensePieChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const ExpensePieChart({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expenses = transactions.where((tx) => tx.type == 'expense').toList();

    if (expenses.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline, size: 36, color: AppColors.textMuted.withOpacity(0.3)),
              const SizedBox(height: 10),
              const Text(
                'Tidak ada pengeluaran',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, double> categorySums = {};
    final Map<String, String> categoryColors = {};
    double totalExpense = 0.0;

    for (var tx in expenses) {
      final categoryName = tx.category?.name ?? 'Lainnya';
      final colorHex = tx.category?.color ?? '#9E9E9E';
      categorySums[categoryName] = (categorySums[categoryName] ?? 0.0) + tx.amount;
      categoryColors[categoryName] = colorHex;
      totalExpense += tx.amount;
    }

    final List<PieChartSectionData> sections = [];
    final sortedEntries = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedEntries) {
      final categoryName = entry.key;
      final amount = entry.value;
      final percentage = (amount / totalExpense) * 100;
      final hexColor = categoryColors[categoryName] ?? '#9E9E9E';
      final color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 20,
          titleStyle: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          showTitle: percentage >= 12, // Only show label when percentage is at least 12% to prevent text collision in smaller segments
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DISTRIBUSI PENGELUARAN',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // Donut chart
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 90,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 25,
                      sections: sections,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Legend
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedEntries.take(4).map((entry) {
                    final categoryName = entry.key;
                    final amount = entry.value;
                    final percentage = (amount / totalExpense) * 100;
                    final hexColor = categoryColors[categoryName] ?? '#9E9E9E';
                    final color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${Formatters.formatCurrency(amount)} · ${percentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          
          if (sortedEntries.length > 4) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '+ ${sortedEntries.length - 4} kategori lainnya',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
