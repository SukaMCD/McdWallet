import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../data/budgets_service.dart';
import '../domain/budget_model.dart';
import '../../../core/providers/supabase_provider.dart';

// Provider untuk akses BudgetsService
final budgetsServiceProvider = Provider<BudgetsService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return BudgetsService(supabase);
});

// ========================================================
// 1. STATE PROVIDER: BUDGETS LIST
// ========================================================
final budgetsProvider = StateNotifierProvider<BudgetsNotifier, AsyncValue<List<BudgetModel>>>((ref) {
  final service = ref.watch(budgetsServiceProvider);
  final authState = ref.watch(authStateProvider);

  final notifier = BudgetsNotifier(service);

  // Memuat otomatis anggaran saat user berhasil login
  authState.whenData((user) {
    if (user != null) {
      notifier.loadBudgets(user.id);
    } else {
      notifier.clear();
    }
  });

  return notifier;
});

class BudgetsNotifier extends StateNotifier<AsyncValue<List<BudgetModel>>> {
  final BudgetsService _service;

  BudgetsNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> loadBudgets(String userId) async {
    state = const AsyncValue.loading();
    try {
      final budgets = await _service.fetchBudgets(userId);
      state = AsyncValue.data(budgets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }

  Future<void> addBudget(BudgetModel budget) async {
    try {
      final newBudget = await _service.createBudget(budget);
      state.whenData((list) {
        state = AsyncValue.data([...list, newBudget]);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeBudget(String budgetId) async {
    try {
      await _service.deleteBudget(budgetId);
      state.whenData((list) {
        state = AsyncValue.data(list.where((b) => b.id != budgetId).toList());
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ========================================================
// 2. MODEL KEMAJUAN ANGGARAN (BUDGET PROGRESS)
// ========================================================
class BudgetProgress {
  final BudgetModel budget;
  final double spentAmount;
  final double remainingAmount;
  final double percentage; // Nilai 0.0 hingga 1.0+ (1.0 = 100%)

  BudgetProgress({
    required this.budget,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentage,
  });
}

// ========================================================
// 3. COMBINED DYNAMIC PROVIDER: BUDGET PROGRESS CALCULATOR
// ========================================================
// Menghitung actual spending per anggaran secara reaktif lokal di memori
// Tanpa memicu query HTTP tambahan ke Supabase (Optimalisasi Kinerja & Offline Caching)
final budgetsProgressProvider = Provider<AsyncValue<List<BudgetProgress>>>((ref) {
  final budgetsAsync = ref.watch(budgetsProvider);
  final transactionsAsync = ref.watch(allTransactionsProvider);

  return budgetsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (budgets) {
      return transactionsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
        data: (transactions) {
          final List<BudgetProgress> progressList = [];

          for (final budget in budgets) {
            double spent = 0.0;
            
            for (final tx in transactions) {
              final isWithinPeriod = tx.date.isAfter(budget.startDate.subtract(const Duration(seconds: 1))) &&
                  tx.date.isBefore(budget.endDate.add(const Duration(days: 1)));

              if (isWithinPeriod) {
                if (tx.type == 'expense') {
                  if (budget.categoryId != null) {
                    if (tx.categoryId == budget.categoryId) {
                      spent += tx.amount;
                    }
                  } else {
                    spent += tx.amount;
                  }
                } else if (tx.type == 'transfer' && tx.adminFee != null && tx.adminFee! > 0) {
                  // Admin fee on transfers are global expenses
                  if (budget.categoryId == null) {
                    spent += tx.adminFee!;
                  }
                }
              }
            }

            final remaining = budget.amountLimit - spent;
            final percentage = budget.amountLimit > 0 ? spent / budget.amountLimit : 0.0;

            progressList.add(BudgetProgress(
              budget: budget,
              spentAmount: spent,
              remainingAmount: remaining,
              percentage: percentage,
            ));
          }

          return AsyncValue.data(progressList);
        },
      );
    },
  );
});
