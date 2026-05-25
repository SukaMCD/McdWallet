import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../transactions/domain/transaction_model.dart';

class CashflowLineChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String period;

  const CashflowLineChart({
    Key? key,
    required this.transactions,
    required this.period,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, double> dailyIncomes = {};
    final Map<DateTime, double> dailyExpenses = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int daysCount = 7;
    DateTime startDate = today.subtract(Duration(days: daysCount - 1));

    if (period == 'week') {
      daysCount = 7;
      startDate = today.subtract(Duration(days: daysCount - 1));
    } else if (period == 'month') {
      daysCount = 30;
      startDate = today.subtract(Duration(days: daysCount - 1));
    } else {
      daysCount = 14;
      startDate = today.subtract(Duration(days: daysCount - 1));
    }

    final List<DateTime> dateRange = [];
    for (int i = 0; i < daysCount; i++) {
      final date = startDate.add(Duration(days: i));
      dateRange.add(date);
      dailyIncomes[date] = 0.0;
      dailyExpenses[date] = 0.0;
    }

    for (var tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (dailyIncomes.containsKey(txDate)) {
        if (tx.type == 'income') {
          dailyIncomes[txDate] = (dailyIncomes[txDate] ?? 0.0) + tx.amount;
        } else if (tx.type == 'expense') {
          dailyExpenses[txDate] = (dailyExpenses[txDate] ?? 0.0) + tx.amount;
        } else if (tx.type == 'transfer' && tx.adminFee != null) {
          dailyExpenses[txDate] = (dailyExpenses[txDate] ?? 0.0) + tx.adminFee!;
        }
      }
    }

    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];
    double maxVal = 100000.0;

    for (int i = 0; i < dateRange.length; i++) {
      final date = dateRange[i];
      final inc = dailyIncomes[date] ?? 0.0;
      final exp = dailyExpenses[date] ?? 0.0;

      incomeSpots.add(FlSpot(i.toDouble(), inc));
      expenseSpots.add(FlSpot(i.toDouble(), exp));

      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }

    maxVal = maxVal * 1.15;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ARUS KAS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  _buildLegendDot(AppColors.income, 'Masuk'),
                  const SizedBox(width: 12),
                  _buildLegendDot(AppColors.expense, 'Keluar'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // ── Chart ──
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: period == 'month' ? 7 : (period == 'week' ? 1 : 3),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dateRange.length) {
                          return const SizedBox.shrink();
                        }
                        final date = dateRange[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            DateFormat('dd').format(date),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (daysCount - 1).toDouble(),
                minY: 0,
                maxY: maxVal,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppColors.surface,
                    tooltipBorder: const BorderSide(color: AppColors.border, width: 0.5),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final isInc = touchedSpot.barIndex == 0;
                        final amount = touchedSpot.y;
                        return LineTooltipItem(
                          '${isInc ? "Masuk" : "Keluar"}: ${Formatters.formatCurrency(amount)}',
                          TextStyle(
                            color: isInc ? AppColors.income : AppColors.expense,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Income line
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: AppColors.income,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.income.withOpacity(0.06),
                          AppColors.income.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Expense line
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: AppColors.expense,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.expense.withOpacity(0.06),
                          AppColors.expense.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
