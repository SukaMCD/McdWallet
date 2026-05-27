import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/chat_message_model.dart';
import '../services/ai_advisor_service.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../budgets/providers/budgets_provider.dart';
import '../../savings/providers/savings_provider.dart';

/// Provider untuk mengelola riwayat pesan percakapan McdAI secara reaktif
final aiAdvisorMessagesProvider = StateNotifierProvider<AiAdvisorNotifier, List<ChatMessageModel>>((ref) {
  final service = AiAdvisorService();
  return AiAdvisorNotifier(service, ref);
});

/// Provider sederhana untuk mendeteksi apakah asisten AI sedang mengetik respons
final aiAdvisorLoadingProvider = StateProvider<bool>((ref) => false);

class AiAdvisorNotifier extends StateNotifier<List<ChatMessageModel>> {
  final AiAdvisorService _service;
  final Ref _ref;

  AiAdvisorNotifier(this._service, this._ref) : super([]);

  /// Menghapus seluruh riwayat obrolan (reset percakapan)
  void clearChat() {
    state = [];
  }

  /// Mengirimkan pesan baru dari pengguna dan menunggu respons asinkron dari Groq LLaMA
  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    // 1. Buat pesan user baru
    final userMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: cleanText,
      createdAt: DateTime.now(),
    );

    // Tambahkan pesan user ke state agar langsung ter-render di antarmuka
    state = [...state, userMessage];

    // 2. Hidupkan indikator AI sedang mengetik (typing indicator bubble)
    _ref.read(aiAdvisorLoadingProvider.notifier).state = true;

    try {
      // 3. Tarik seluruh data finansial real-time yang mutakhir dari Riverpod Providers
      final wallets = _ref.read(walletsProvider).value ?? [];
      final budgets = _ref.read(budgetsProvider).value ?? [];
      final savingsGoals = _ref.read(savingsProvider).value ?? [];
      final transactions = _ref.read(allTransactionsProvider).value ?? [];
      final totalBalance = _ref.read(totalBalanceProvider).value ?? 0.0;

      // 4. Jalankan panggilan asinkron ke Groq LLaMA API dengan riwayat percakapan sebelumnya
      final reply = await _service.chatWithAdvisor(
        wallets: wallets,
        budgets: budgets,
        savingsGoals: savingsGoals,
        transactions: transactions,
        totalBalance: totalBalance,
        history: state.sublist(0, state.length - 1),
        userMessage: cleanText,
      );

      // 5. Buat pesan asisten AI baru hasil dari balasan LLM
      final assistantMessage = ChatMessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: reply,
        createdAt: DateTime.now(),
      );

      state = [...state, assistantMessage];
    } catch (e) {
      // Jika terjadi gangguan jaringan, berikan pesan kesalahan ramah pengguna
      final errorMessage = ChatMessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: 'Aduh, maaf ya! Sistem AI kami sedang mengalami sedikit gangguan koneksi. Mohon pastikan internet Anda aktif dan ketuk kembali pertanyaan Anda. Detail kendala: $e',
        createdAt: DateTime.now(),
      );
      state = [...state, errorMessage];
    } finally {
      // 6. Matikan indikator mengetik
      _ref.read(aiAdvisorLoadingProvider.notifier).state = false;
    }
  }
}
