import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/savings_goal_model.dart';

class SavingsService {
  final SupabaseClient _supabase;

  SavingsService(this._supabase);

  // Mengambil daftar target tabungan
  Future<List<SavingsGoalModel>> fetchSavingsGoals(String userId) async {
    try {
      final response = await _supabase
          .from('savings_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      return (response as List).map((e) => SavingsGoalModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      if (e.message.contains('relation "public.savings_goals" does not exist') || e.code == '42P01') {
        throw const FormatException('TABLE_NOT_FOUND');
      }
      rethrow;
    }
  }

  // Membuat target tabungan baru
  Future<SavingsGoalModel> createSavingsGoal(SavingsGoalModel goal) async {
    try {
      final response = await _supabase
          .from('savings_goals')
          .insert(goal.toJson())
          .select()
          .single();
      return SavingsGoalModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('relation "public.savings_goals" does not exist') || e.code == '42P01') {
        throw const FormatException('TABLE_NOT_FOUND');
      }
      rethrow;
    }
  }

  // Mengupdate saldo terkini target tabungan
  Future<SavingsGoalModel> updateSavingsGoalAmount(String goalId, double newAmount) async {
    try {
      final response = await _supabase
          .from('savings_goals')
          .update({'current_amount': newAmount})
          .eq('id', goalId)
          .select()
          .single();
      return SavingsGoalModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('relation "public.savings_goals" does not exist') || e.code == '42P01') {
        throw const FormatException('TABLE_NOT_FOUND');
      }
      rethrow;
    }
  }

  // Menghapus target tabungan
  Future<void> deleteSavingsGoal(String goalId) async {
    try {
      await _supabase.from('savings_goals').delete().eq('id', goalId);
    } on PostgrestException catch (e) {
      if (e.message.contains('relation "public.savings_goals" does not exist') || e.code == '42P01') {
        throw const FormatException('TABLE_NOT_FOUND');
      }
      rethrow;
    }
  }
}
