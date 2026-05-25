import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/budget_model.dart';

class BudgetsService {
  final SupabaseClient _supabase;

  BudgetsService(this._supabase);

  // Mengambil daftar anggaran milik pengguna
  Future<List<BudgetModel>> fetchBudgets(String userId) async {
    final response = await _supabase
        .from('budgets')
        .select('*, categories(*)')
        .eq('user_id', userId)
        .order('created_at');
    return (response as List).map((e) => BudgetModel.fromJson(e)).toList();
  }

  // Membuat anggaran baru
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    final response = await _supabase
        .from('budgets')
        .insert(budget.toJson())
        .select('*, categories(*)')
        .single();
    return BudgetModel.fromJson(response);
  }

  // Memperbarui limit anggaran
  Future<BudgetModel> updateBudget(String budgetId, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('budgets')
        .update(updates)
        .eq('id', budgetId)
        .select('*, categories(*)')
        .single();
    return BudgetModel.fromJson(response);
  }

  // Menghapus anggaran
  Future<void> deleteBudget(String budgetId) async {
    await _supabase.from('budgets').delete().eq('id', budgetId);
  }

  // Mengambil total pengeluaran aktual untuk kategori & rentang tanggal tertentu
  Future<double> getActualSpending(
    String userId,
    String? categoryId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    var query = _supabase
        .from('transactions')
        .select('amount')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String());

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final response = await query;
    double total = 0.0;
    for (var row in response as List) {
      total += (row['amount'] as num).toDouble();
    }
    return total;
  }
}
