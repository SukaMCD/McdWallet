import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/config.dart';
import '../../transactions/domain/wallet_model.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../budgets/domain/budget_model.dart';
import '../../savings/domain/savings_goal_model.dart';
import '../domain/chat_message_model.dart';

class AiAdvisorService {
  /// Mengirim obrolan dengan riwayat pesan ke Groq API (llama-3.3-70b-versatile)
  /// Menyisipkan ringkasan kondisi finansial real-time sebagai instruksi sistem (system prompt)
  Future<String> chatWithAdvisor({
    required List<WalletModel> wallets,
    required List<BudgetModel> budgets,
    required List<SavingsGoalModel> savingsGoals,
    required List<TransactionModel> transactions,
    required double totalBalance,
    required List<ChatMessageModel> history,
    required String userMessage,
  }) async {
    if (AppConfig.groqApiKey.isEmpty) {
      throw Exception('API Key Groq belum diatur dalam konfigurasi aplikasi.');
    }

    // 1. Hitung pengeluaran dinamis untuk setiap anggaran aktif
    final String budgetsSummary = budgets.isEmpty
        ? '  * Tidak ada batas anggaran aktif saat ini.'
        : budgets.map((b) {
            final spent = _calculateBudgetSpent(b, transactions);
            final catName = b.category?.name ?? 'Global Bulanan';
            final ratio = b.amountLimit > 0 ? (spent / b.amountLimit * 100) : 0.0;
            return '  * Anggaran $catName: Limit Rp ${b.amountLimit.toStringAsFixed(0)} | Terpakai Rp ${spent.toStringAsFixed(0)} (${ratio.toStringAsFixed(1)}%)';
          }).join('\n');

    // 2. Susun ringkasan target tabungan
    final String savingsSummary = savingsGoals.isEmpty
        ? '  * Tidak ada target tabungan saat ini.'
        : savingsGoals.map((g) {
            final pct = (g.percentage * 100).toStringAsFixed(1);
            final status = g.isAchieved ? 'TERCAPAI ✓' : 'Progres $pct%';
            final targetDateStr = g.targetDate != null
                ? ' | Target: ${g.targetDate!.toString().substring(0, 10)}'
                : '';
            final intervalInfo = g.savingInterval != 'custom' && g.savingAmountPerInterval > 0
                ? ' | Alokasi Rp ${g.savingAmountPerInterval.toStringAsFixed(0)}/${g.savingInterval == 'daily' ? 'hari' : g.savingInterval == 'weekly' ? 'minggu' : 'bulan'}'
                : '';
            return '  * ${g.name}: Terkumpul Rp ${g.currentAmount.toStringAsFixed(0)} / Target Rp ${g.targetAmount.toStringAsFixed(0)} ($status$targetDateStr$intervalInfo)';
          }).join('\n');

    // 3. Ambil 15 transaksi terakhir secara anonim untuk menjaga privasi (tanpa data sensitif)
    final String txsSummary = transactions.isEmpty
        ? '  * Belum ada riwayat transaksi mutasi.'
        : transactions.take(15).map((t) {
            final dateStr = t.date.toString().substring(0, 10);
            final typeLabel = t.type == 'expense'
                ? 'PENGELUARAN'
                : t.type == 'income'
                    ? 'PEMASUKAN'
                    : 'TRANSFER';
            final amountStr = 'Rp ${t.amount.toStringAsFixed(0)}';
            final String categoryLabel = t.category != null ? '[Kategori: ${t.category!.name}]' : '';
            final contextLabel = t.type == 'transfer' 
                ? 'Transfer Saldo' 
                : '${categoryLabel.isNotEmpty ? '$categoryLabel ' : ''}${t.description ?? 'Tanpa deskripsi'}';
            return '  * [$dateStr] $typeLabel: $amountStr ($contextLabel)';
          }).join('\n');

    // 4. Susun instruksi awal sistem (System Prompt) dengan data keuangan nyata
    final String systemPrompt = '''
Anda adalah McdAI, asisten keuangan pribadi yang KHUSUS membantu pengguna aplikasi McdWallet mengelola keuangan mereka. Anda HANYA boleh menjawab pertanyaan yang berkaitan dengan topik keuangan pribadi, seperti: pengelolaan uang, analisis transaksi, anggaran (budgeting), tabungan, investasi, pengeluaran, pemasukan, transfer, dompet, hutang, atau perencanaan finansial.

=== ATURAN MUTLAK (WAJIB DIIKUTI) ===
- TOLAK dengan sopan dan tegas setiap pertanyaan di luar topik keuangan. Ini termasuk (namun tidak terbatas pada): pertanyaan tentang pemrograman/coding, sains, sejarah, hiburan, memasak, kesehatan umum, olahraga, atau topik umum lainnya.
- Jika ada pertanyaan di luar topik, JANGAN jawab pertanyaannya sama sekali. Sampaikan dengan ramah bahwa Anda hanya bisa membantu di bidang keuangan, lalu arahkan pengguna untuk menanyakan sesuatu tentang kondisi finansial mereka.
- Contoh respons penolakan: "Wah, pertanyaan seru nih! Tapi saya McdAI fokus di bidang keuangan ya. 😊 Ada yang ingin kamu tanyakan soal keuangan, anggaran, atau tips menabung?"
======================================

=== DATA FINANSIAL PENGGUNA (REAL-TIME) ===
- Total Kekayaan Bersih (Terkonversi IDR): Rp ${totalBalance.toStringAsFixed(0)}
- Saldo Aktif per Dompet:
${wallets.isEmpty ? "  * Belum ada dompet aktif." : wallets.map((w) => "  * ${w.name}: ${w.currencyCode} ${w.balance.toStringAsFixed(0)}").join('\n')}

- Status Batas Anggaran (Budgets):
$budgetsSummary

- Target Tabungan (Savings Goals):
$savingsSummary

- 15 Transaksi Mutasi Terakhir:
$txsSummary
===========================================

PANDUAN PERILAKU ANDA:
1. Jawablah dalam Bahasa Indonesia yang luwes, santai, bersahabat, namun tetap profesional dan berbobot secara finansial (Anda bisa menyelipkan gurauan ringan atau kata sapaan hangat).
2. Jika memberikan jawaban, gunakan format Markdown yang rapi dan indah (gunakan cetak tebal, daftar poin, subjudul, atau bahkan tabel mini jika relevan) agar saran Anda sangat nyaman dibaca di layar ponsel.
3. Berikan saran yang logis berdasarkan angka di atas. Misalnya, jika ada anggaran yang terpakai > 80%, peringatkan mereka dengan ramah. Jika ada target tabungan yang hampir tercapai, semangati pengguna. Jika ada pengeluaran besar baru-baru ini, diskusikan secara taktis.
4. Jawablah secara ringkas, padat, dan terfokus. Hindari basa-basi yang terlalu panjang lebar agar pengguna langsung mendapatkan intisari saran Anda.
''';

    // 4. Bangun payload pesan dengan riwayat percakapan untuk menjaga memori chat
    final List<Map<String, dynamic>> messagesPayload = [
      {
        'role': 'system',
        'content': systemPrompt,
      },
    ];

    // Tambahkan riwayat obrolan (maksimal 10 pesan terakhir untuk efisiensi token)
    final recentHistory = history.length > 10 ? history.sublist(history.length - 10) : history;
    for (final msg in recentHistory) {
      messagesPayload.add({
        'role': msg.role,
        'content': msg.content,
      });
    }

    // Tambahkan pesan user terbaru
    messagesPayload.add({
      'role': 'user',
      'content': userMessage,
    });

    // 5. Kirim HTTP request ke Groq API
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'llama-3.3-70b-versatile',
          'messages': messagesPayload,
          'temperature': 0.65, // Mengatur agar chat mengalir secara organik dan luwes
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Groq API Error (${response.statusCode}): ${response.body}');
      }

      final responseData = json.decode(response.body);
      final String? assistantReply = responseData['choices']?[0]?['message']?['content'];

      if (assistantReply == null || assistantReply.isEmpty) {
        throw Exception('Groq API mengembalikan respons kosong.');
      }

      return assistantReply.trim();
    } catch (e) {
      debugPrint('AI Advisor Service: Obrolan gagal dengan kesalahan: $e');
      rethrow;
    }
  }

  /// Menghitung akumulasi nominal pengeluaran dinamis untuk anggaran tertentu
  double _calculateBudgetSpent(BudgetModel budget, List<TransactionModel> allTxs) {
    double spent = 0.0;
    for (final tx in allTxs) {
      // Cek apakah transaksi berada dalam rentang tanggal anggaran
      final txWithinPeriod = tx.date.isAfter(budget.startDate.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(budget.endDate.add(const Duration(days: 1)));

      if (txWithinPeriod) {
        if (tx.type == 'expense') {
          final double txAmountInIdr = tx.amountInIdr ?? tx.amount;
          if (budget.categoryId != null) {
            if (tx.categoryId == budget.categoryId) {
              spent += txAmountInIdr;
            }
          } else {
            spent += txAmountInIdr;
          }
        } else if (tx.type == 'transfer' && tx.adminFee != null && tx.adminFee! > 0) {
          if (budget.categoryId == null) {
            spent += tx.adminFee!;
          }
        }
      }
    }
    return spent;
  }
}
