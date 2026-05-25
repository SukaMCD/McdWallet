import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/image_compressor.dart';
import '../domain/wallet_model.dart';
import '../domain/category_model.dart';
import '../domain/transaction_model.dart';

class TransactionsService {
  final SupabaseClient _supabase;

  TransactionsService(this._supabase);

  // ========================================================
  // 1. MANAJEMEN DOMPET (WALLETS)
  // ========================================================
  
  // Mengambil daftar dompet milik pengguna
  Future<List<WalletModel>> fetchWallets(String userId) async {
    final response = await _supabase
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .order('name');
    return (response as List).map((e) => WalletModel.fromJson(e)).toList();
  }

  // Membuat dompet baru
  Future<WalletModel> createWallet(WalletModel wallet) async {
    final response = await _supabase
        .from('wallets')
        .insert(wallet.toJson())
        .select()
        .single();
    return WalletModel.fromJson(response);
  }

  // Memperbarui properti dompet (misal: ganti nama/warna/ikon)
  Future<WalletModel> updateWallet(String walletId, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('wallets')
        .update(updates)
        .eq('id', walletId)
        .select()
        .single();
    return WalletModel.fromJson(response);
  }

  // Menghapus dompet
  Future<void> deleteWallet(String walletId) async {
    await _supabase.from('wallets').delete().eq('id', walletId);
  }

  // ========================================================
  // 2. MANAJEMEN KATEGORI (CATEGORIES)
  // ========================================================

  // Mengambil daftar kategori milik pengguna
  Future<List<CategoryModel>> fetchCategories(String userId) async {
    final response = await _supabase
        .from('categories')
        .select()
        .eq('user_id', userId)
        .order('name');
    return (response as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  // Membuat kategori kustom baru
  Future<CategoryModel> createCategory(CategoryModel category) async {
    final response = await _supabase
        .from('categories')
        .insert(category.toJson())
        .select()
        .single();
    return CategoryModel.fromJson(response);
  }

  // Memperbarui kategori kustom
  Future<CategoryModel> updateCategory(String categoryId, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('categories')
        .update(updates)
        .eq('id', categoryId)
        .select()
        .single();
    return CategoryModel.fromJson(response);
  }

  // Menghapus kategori kustom
  Future<void> deleteCategory(String categoryId) async {
    await _supabase.from('categories').delete().eq('id', categoryId);
  }

  // ========================================================
  // 3. MANAJEMEN TRANSAKSI (TRANSACTIONS)
  // ========================================================

  // Mengambil daftar transaksi dengan opsional filter & relasi join
  Future<List<TransactionModel>> fetchTransactions(
    String userId, {
    String? walletId,
    String? categoryId,
    String? type,
  }) async {
    // Join tabel wallets & categories menggunakan relasi foreign key Postgres
    var query = _supabase
        .from('transactions')
        .select('*, wallets:wallets!transactions_wallet_id_fkey(*), to_wallets:wallets!transactions_to_wallet_id_fkey(*), categories(*)');
        
    query = query.eq('user_id', userId);
    
    if (walletId != null) {
      query = query.eq('wallet_id', walletId);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (type != null) {
      query = query.eq('type', type);
    }

    final response = await query.order('date', ascending: false);
    return (response as List).map((e) => TransactionModel.fromJson(e)).toList();
  }

  // Mencatat transaksi baru (Dompet balance otomatis terhitung via database trigger)
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final response = await _supabase
        .from('transactions')
        .insert(transaction.toJson())
        .select('*, wallets:wallets!transactions_wallet_id_fkey(*), to_wallets:wallets!transactions_to_wallet_id_fkey(*), categories(*)')
        .single();
    return TransactionModel.fromJson(response);
  }

  // Menghapus catatan transaksi (Dompet balance otomatis di-rollback via database trigger)
  Future<void> deleteTransaction(String transactionId) async {
    await _supabase.from('transactions').delete().eq('id', transactionId);
  }

  // ========================================================
  // 4. STORAGE: UPLOAD STRUK BELANJA
  // ========================================================
  
  // Mengunggah file nota fisik ke Supabase Storage Bucket
  Future<String?> uploadReceipt(String userId, String filePath) async {
    File file = File(filePath);
    
    // Panggil kompresi gambar secara asinkron sebelum diunggah
    try {
      file = await ImageCompressor.compress(imageFile: file);
    } catch (_) {
      // Fallback aman menggunakan file asli jika terjadi kegagalan kompresi
    }
    
    final fileExt = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = '$userId/$fileName';

    await _supabase.storage.from('receipts').upload(path, file);
    
    // Mengambil URL Publik file struk
    final publicUrl = _supabase.storage.from('receipts').getPublicUrl(path);
    return publicUrl;
  }
}
