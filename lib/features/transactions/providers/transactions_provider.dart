import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/transactions_service.dart';
import '../domain/wallet_model.dart';
import '../domain/category_model.dart';
import '../domain/transaction_model.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../budgets/providers/budgets_provider.dart';

// Provider untuk TransactionsService
final transactionsServiceProvider = Provider<TransactionsService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TransactionsService(supabase);
});

// ========================================================
// 1. STATE PROVIDER: WALLETS LIST
// ========================================================
final walletsProvider = StateNotifierProvider<WalletsNotifier, AsyncValue<List<WalletModel>>>((ref) {
  final service = ref.watch(transactionsServiceProvider);
  final authState = ref.watch(authStateProvider);
  
  final notifier = WalletsNotifier(service, ref);
  
  // Memuat otomatis dompet ketika user berhasil login
  authState.whenData((user) {
    if (user != null) {
      notifier.loadWallets(user.id);
    } else {
      notifier.clear();
    }
  });
  
  return notifier;
});

class WalletsNotifier extends StateNotifier<AsyncValue<List<WalletModel>>> {
  final TransactionsService _service;
  final Ref _ref;

  WalletsNotifier(this._service, this._ref) : super(const AsyncValue.loading());

  Future<void> loadWallets(String userId) async {
    state = const AsyncValue.loading();
    try {
      final wallets = await _service.fetchWallets(userId);

      // Load custom order from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final orderedIds = prefs.getStringList('wallet_order_$userId');

      if (orderedIds != null && orderedIds.isNotEmpty) {
        final Map<String, int> orderMap = {
          for (int i = 0; i < orderedIds.length; i++) orderedIds[i]: i
        };
        wallets.sort((a, b) {
          final indexA = orderMap[a.id] ?? 9999;
          final indexB = orderMap[b.id] ?? 9999;
          return indexA.compareTo(indexB);
        });
      }

      state = AsyncValue.data(wallets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }

  Future<void> addWallet(WalletModel wallet) async {
    try {
      final newWallet = await _service.createWallet(wallet);
      state.whenData((list) {
        state = AsyncValue.data([...list, newWallet]);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeWallet(String walletId) async {
    try {
      await _service.deleteWallet(walletId);
      state.whenData((list) {
        state = AsyncValue.data(list.where((w) => w.id != walletId).toList());
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorderWallets(int oldIndex, int newIndex) async {
    state.whenData((list) async {
      final updatedList = List<WalletModel>.from(list);
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = updatedList.removeAt(oldIndex);
      updatedList.insert(newIndex, item);
      state = AsyncValue.data(updatedList);

      try {
        final user = _ref.read(authStateProvider).value;
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          final ids = updatedList.map((w) => w.id).toList();
          await prefs.setStringList('wallet_order_${user.id}', ids);
        }
      } catch (e) {
        // Safely ignore storage errors
      }
    });
  }
}

// ========================================================
// 2. STATE PROVIDER: CATEGORIES LIST
// ========================================================
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>((ref) {
  final service = ref.watch(transactionsServiceProvider);
  final authState = ref.watch(authStateProvider);
  
  final notifier = CategoriesNotifier(service);
  
  // Memuat otomatis kategori ketika user berhasil login
  authState.whenData((user) {
    if (user != null) {
      notifier.loadCategories(user.id);
    } else {
      notifier.clear();
    }
  });
  
  return notifier;
});

class CategoriesNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final TransactionsService _service;

  CategoriesNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> loadCategories(String userId) async {
    state = const AsyncValue.loading();
    try {
      final categories = await _service.fetchCategories(userId);
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      final newCat = await _service.createCategory(category);
      state.whenData((list) {
        state = AsyncValue.data([...list, newCat]);
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(String categoryId, CategoryModel category) async {
    try {
      final updatedCat = await _service.updateCategory(categoryId, category.toJson());
      state.whenData((list) {
        final index = list.indexWhere((c) => c.id == categoryId);
        if (index != -1) {
          final newList = [...list];
          newList[index] = updatedCat;
          state = AsyncValue.data(newList);
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeCategory(String categoryId) async {
    try {
      await _service.deleteCategory(categoryId);
      state.whenData((list) {
        state = AsyncValue.data(list.where((c) => c.id != categoryId).toList());
      });
    } catch (e) {
      rethrow;
    }
  }
}

// ========================================================
// 3. STATE PROVIDERS: ACTIVE FILTERS
// ========================================================
final walletFilterProvider = StateProvider<String?>((ref) => null);
final categoryFilterProvider = StateProvider<String?>((ref) => null);
final typeFilterProvider = StateProvider<String?>((ref) => null);

// ========================================================
// 3.5. STATE PROVIDER: ALL TRANSACTIONS LIST (UNFILTERED)
// ========================================================
final allTransactionsProvider = StateNotifierProvider<AllTransactionsNotifier, AsyncValue<List<TransactionModel>>>((ref) {
  final service = ref.watch(transactionsServiceProvider);
  final authState = ref.watch(authStateProvider);

  final notifier = AllTransactionsNotifier(service);

  authState.whenData((user) {
    if (user != null) {
      notifier.loadAllTransactions(user.id);
    } else {
      notifier.clear();
    }
  });

  return notifier;
});

class AllTransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final TransactionsService _service;

  AllTransactionsNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> loadAllTransactions(String userId) async {
    state = const AsyncValue.loading();
    try {
      final txs = await _service.fetchTransactions(userId);
      state = AsyncValue.data(txs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

// ========================================================
// 4. STATE PROVIDER: TRANSACTIONS LIST
// ========================================================
final transactionsProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<List<TransactionModel>>>((ref) {
  final service = ref.watch(transactionsServiceProvider);
  final authState = ref.watch(authStateProvider);
  
  // Memantau perubahan filter aktif untuk otomatis me-reload query
  final walletId = ref.watch(walletFilterProvider);
  final categoryId = ref.watch(categoryFilterProvider);
  final type = ref.watch(typeFilterProvider);

  final notifier = TransactionsNotifier(service, ref);

  authState.whenData((user) {
    if (user != null) {
      notifier.loadTransactions(user.id, walletId: walletId, categoryId: categoryId, type: type);
    } else {
      notifier.clear();
    }
  });

  return notifier;
});

class TransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final TransactionsService _service;
  final Ref _ref;

  TransactionsNotifier(this._service, this._ref) : super(const AsyncValue.loading());

  Future<void> loadTransactions(
    String userId, {
    String? walletId,
    String? categoryId,
    String? type,
  }) async {
    state = const AsyncValue.loading();
    try {
      final txs = await _service.fetchTransactions(
        userId,
        walletId: walletId,
        categoryId: categoryId,
        type: type,
      );
      state = AsyncValue.data(txs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }

  // Membuat transaksi baru dan otomatis me-refresh sisa saldo dompet terkait
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _service.createTransaction(transaction);
      
      final user = _ref.read(authStateProvider).value;
      if (user != null) {
        // PENTING: Refresh balance dompet karena database trigger Postgres baru saja memodifikasinya!
        _ref.read(walletsProvider.notifier).loadWallets(user.id);
        
        // Refresh daftar transaksi
        final walletId = _ref.read(walletFilterProvider);
        final categoryId = _ref.read(categoryFilterProvider);
        final type = _ref.read(typeFilterProvider);
        await loadTransactions(user.id, walletId: walletId, categoryId: categoryId, type: type);

        // Refresh allTransactionsProvider (unfiltered) and wait for it!
        await _ref.read(allTransactionsProvider.notifier).loadAllTransactions(user.id);

        // Pengecekan sisa anggaran terlampaui setelah transaksi ditambahkan (jika pengeluaran)
        if (transaction.type == 'expense') {
          _checkBudgetLimits(transaction);
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Mengubah transaksi dengan menghapus yang lama dan membuat yang baru untuk menjaga konsistensi database trigger
  Future<void> editTransaction(TransactionModel oldTx, TransactionModel newTx) async {
    try {
      // 1. Hapus transaksi lama (saldo ter-rollback otomatis)
      await _service.deleteTransaction(oldTx.id);
      
      // 2. Buat transaksi baru (saldo ter-update otomatis)
      await _service.createTransaction(newTx);
      
      final user = _ref.read(authStateProvider).value;
      if (user != null) {
        // Refresh balance dompet
        _ref.read(walletsProvider.notifier).loadWallets(user.id);
        
        // Refresh daftar transaksi
        final walletId = _ref.read(walletFilterProvider);
        final categoryId = _ref.read(categoryFilterProvider);
        final type = _ref.read(typeFilterProvider);
        await loadTransactions(user.id, walletId: walletId, categoryId: categoryId, type: type);

        // Refresh allTransactionsProvider (unfiltered) and wait for it!
        await _ref.read(allTransactionsProvider.notifier).loadAllTransactions(user.id);

        // Pengecekan sisa anggaran terlampaui setelah transaksi ditambahkan (jika pengeluaran)
        if (newTx.type == 'expense') {
          _checkBudgetLimits(newTx);
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _checkBudgetLimits(TransactionModel transaction) {
    try {
      final budgetsAsync = _ref.read(budgetsProvider);
      final allTxsAsync = _ref.read(allTransactionsProvider);
      
      final budgets = budgetsAsync.value;
      final allTxs = allTxsAsync.value;
      
      if (budgets == null || allTxs == null) return;

      for (final budget in budgets) {
        // Validasi apakah tanggal transaksi berada dalam periode anggaran
        final isWithinPeriod = transaction.date.isAfter(budget.startDate.subtract(const Duration(seconds: 1))) &&
            transaction.date.isBefore(budget.endDate.add(const Duration(days: 1)));
            
        if (isWithinPeriod) {
          double spent = 0.0;
          
          // Hitung total pengeluaran secara akurat dan sinkron
          for (final tx in allTxs) {
            final txWithinPeriod = tx.date.isAfter(budget.startDate.subtract(const Duration(seconds: 1))) &&
                tx.date.isBefore(budget.endDate.add(const Duration(days: 1)));
                
            if (txWithinPeriod) {
              if (tx.type == 'expense') {
                if (budget.categoryId != null) {
                  if (tx.categoryId == budget.categoryId) {
                    spent += tx.amount;
                  }
                } else {
                  spent += tx.amount;
                }
              } else if (tx.type == 'transfer' && tx.adminFee != null && tx.adminFee! > 0) {
                if (budget.categoryId == null) {
                  spent += tx.adminFee!;
                }
              }
            }
          }

          // Jika pengeluaran melebihi limit anggaran
          if (spent >= budget.amountLimit) {
            // Kasus 1: Anggaran Kategori Spesifik
            if (budget.categoryId != null && budget.categoryId == transaction.categoryId) {
              final categoryName = budget.category?.name ?? 'Kategori';
              NotificationService().showBudgetExceededNotification(
                categoryName: categoryName,
                limitAmount: budget.amountLimit,
                spentAmount: spent,
              );
            }
            // Kasus 2: Anggaran Global (category_id null)
            else if (budget.categoryId == null) {
              NotificationService().showBudgetExceededNotification(
                categoryName: 'Anggaran Global',
                limitAmount: budget.amountLimit,
                spentAmount: spent,
              );
            }
          }
        }
      }
    } catch (e) {
      // Safely ignore logging errors in checking budget
      print('Error checking budget limits: $e');
    }
  }

  // Menghapus transaksi dan otomatis mengembalikan (roll back) sisa saldo dompet terkait
  Future<void> removeTransaction(String transactionId) async {
    try {
      await _service.deleteTransaction(transactionId);
      final user = _ref.read(authStateProvider).value;
      if (user != null) {
        // Refresh balance dompet pasca rollback di database trigger
        _ref.read(walletsProvider.notifier).loadWallets(user.id);
        
        // Refresh daftar transaksi
        final walletId = _ref.read(walletFilterProvider);
        final categoryId = _ref.read(categoryFilterProvider);
        final type = _ref.read(typeFilterProvider);
        loadTransactions(user.id, walletId: walletId, categoryId: categoryId, type: type);

        // Refresh allTransactionsProvider
        _ref.read(allTransactionsProvider.notifier).loadAllTransactions(user.id);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
