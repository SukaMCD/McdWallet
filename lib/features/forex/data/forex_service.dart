import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/forex_rate_model.dart';
import '../../../core/constants/config.dart';

/// Service untuk mengambil data nilai tukar dari AllRatesToday API
/// dengan smart local caching (2 jam TTL) untuk menghemat kuota free tier.
class ForexService {
  // ─── Cache keys ────────────────────────────────────────────
  static const String _cacheKey       = 'forex_cache_data';
  static const String _cacheTimestamp = 'forex_cache_timestamp';

  // Cache berlaku 1 jam
  static const Duration _cacheTtl = Duration(hours: 1);

  // ════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ════════════════════════════════════════════════════════════

  /// Ambil rates untuk [targets] vs IDR.
  /// Menggunakan cache lokal jika masih segar (< 2 jam).
  Future<List<ForexRateModel>> fetchRates(
    String base,
    List<String> targets,
  ) async {
    if (targets.isEmpty) return [];

    // Coba cache terlebih dahulu
    final cached = await _readCache();
    if (cached != null) {
      final codes = targets.map((c) => c.toUpperCase()).toSet();
      final fromCache = cached.where((r) => codes.contains(r.code)).toList();
      // Jika semua currency ada di cache, langsung return
      if (fromCache.length == targets.length) return fromCache;
    }

    // Cache miss / kedaluwarsa → fetch dari API
    final allRates = await _fetchAndCache(base, targets, previousRates: _extractPrevious(cached));
    final codes = targets.map((c) => c.toUpperCase()).toSet();
    return allRates.where((r) => codes.contains(r.code)).toList();
  }

  /// Paksa refresh data dari API (bypass cache).
  /// Dipanggil tombol "Perbarui" manual.
  Future<List<ForexRateModel>> refreshRates(
    String base,
    List<String> targets,
  ) async {
    if (targets.isEmpty) return [];

    // Simpan rates lama sebagai previousRate untuk kalkulasi tren
    final stale = await _readCache(ignoreExpiry: true);
    final prevRates = _extractPrevious(stale);

    final allRates = await _fetchAndCache(base, targets, previousRates: prevRates);
    final codes = targets.map((c) => c.toUpperCase()).toSet();
    return allRates.where((r) => codes.contains(r.code)).toList();
  }

  /// Ambil daftar simbol yang didukung API.
  /// Fallback ke metadata hardcoded jika API gagal.
  Future<Map<String, String>> fetchSupportedSymbols() async {
    return {for (final c in CurrencyMetadata.allCurrencies) c['code']!: c['name']!};
  }

  /// Waktu terakhir cache diperbarui (null jika belum pernah)
  Future<DateTime?> getLastCacheTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_cacheTimestamp);
      if (ms == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  /// Apakah ada data cache (segar atau basi)?
  Future<bool> hasCachedData() async {
    final data = await _readCache(ignoreExpiry: true);
    return data != null && data.isNotEmpty;
  }

  /// Ambil semua rates yang tersimpan di cache (mengabaikan kedaluwarsa untuk offline fallback)
  Future<List<ForexRateModel>> getCachedRates() async {
    final data = await _readCache(ignoreExpiry: true);
    return data ?? [];
  }

  // ════════════════════════════════════════════════════════════
  //  PRIVATE – FETCH
  // ════════════════════════════════════════════════════════════

  Future<List<ForexRateModel>> _fetchAndCache(
    String base,
    List<String> targets, {
    Map<String, double> previousRates = const {},
  }) async {
    try {
      final rates = await _callApi(base, targets, previousRates);
      if (rates.isNotEmpty) {
        await _writeCache(rates);
      }
      return rates;
    } on SocketException {
      // Offline → kembalikan data basi jika ada
      return _staleFallback(targets);
    } catch (_) {
      return _staleFallback(targets);
    }
  }

  Future<List<ForexRateModel>> _callApi(
    String base,
    List<String> targets,
    Map<String, double> prevRates,
  ) async {
    // Menggunakan keyless public API dari open.er-api.com untuk reliabilitas tinggi dan 100% bebas error 401
    final uri = Uri.parse('https://open.er-api.com/v6/latest/${base.toUpperCase()}');

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseResponse(json, base, prevRates);
    }

    throw HttpException(
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  /// Parse respons API ke list ForexRateModel.
  /// Mendukung format umum:
  ///   { "rates": { "USD": 0.0000645 } }          ← base=IDR, inverted
  ///   { "data": { "USD": { "value": 0.0645 } } }
  List<ForexRateModel> _parseResponse(
    Map<String, dynamic> json,
    String base,
    Map<String, double> prevRates,
  ) {
    final result = <ForexRateModel>[];

    Map<String, dynamic>? ratesMap;
    if (json['rates'] is Map) {
      ratesMap = json['rates'] as Map<String, dynamic>;
    } else if (json['data'] is Map) {
      ratesMap = json['data'] as Map<String, dynamic>;
    }

    if (ratesMap == null) return result;

    for (final entry in ratesMap.entries) {
      final code = entry.key.toUpperCase();
      if (!CurrencyMetadata.isSupported(code)) continue;

      double rawRate;
      if (entry.value is num) {
        rawRate = (entry.value as num).toDouble();
      } else if (entry.value is Map) {
        final inner = entry.value as Map;
        final val = inner['value'] ?? inner['rate'] ?? inner['price'];
        if (val is num) {
          rawRate = val.toDouble();
        } else {
          continue;
        }
      } else {
        continue;
      }

      if (rawRate <= 0) continue;

      // Jika base=IDR: 1 IDR = rawRate USD  →  1 USD = 1/rawRate IDR
      final idrRate = base.toUpperCase() == 'IDR' ? 1.0 / rawRate : rawRate;

      final prevRate = prevRates[code] ?? idrRate;

      // Tren dengan threshold 0.01% untuk menghindari noise
      ForexTrend trend;
      if (idrRate > prevRate * 1.0001) {
        trend = ForexTrend.up;
      } else if (idrRate < prevRate * 0.9999) {
        trend = ForexTrend.down;
      } else {
        trend = ForexTrend.flat;
      }

      result.add(ForexRateModel(
        code: code,
        name: CurrencyMetadata.getName(code),
        symbol: CurrencyMetadata.getSymbol(code),
        flag: CurrencyMetadata.getFlag(code),
        rate: idrRate,
        previousRate: prevRate,
        trend: trend,
      ));
    }

    return result;
  }

  // ════════════════════════════════════════════════════════════
  //  PRIVATE – CACHE
  // ════════════════════════════════════════════════════════════

  Future<List<ForexRateModel>?> _readCache({bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms   = prefs.getInt(_cacheTimestamp);
      final data = prefs.getString(_cacheKey);
      if (ms == null || data == null) return null;

      if (!ignoreExpiry) {
        final age = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(ms),
        );
        if (age > _cacheTtl) return null;
      }

      final list = jsonDecode(data) as List;
      return list
          .map((e) => ForexRateModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(List<ForexRateModel> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(rates.map((r) => r.toJson()).toList()),
      );
      await prefs.setInt(
        _cacheTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Abaikan error penyimpanan cache
    }
  }

  // ════════════════════════════════════════════════════════════
  //  PRIVATE – HELPERS
  // ════════════════════════════════════════════════════════════

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${AppConfig.allRatesTodayApiKey}',
        'Accept': 'application/json',
      };

  Map<String, double> _extractPrevious(List<ForexRateModel>? rates) {
    if (rates == null) return {};
    return {for (final r in rates) r.code: r.rate};
  }

  Future<List<ForexRateModel>> _staleFallback(List<String> targets) async {
    final stale = await _readCache(ignoreExpiry: true);
    if (stale == null) return [];
    final codes = targets.map((c) => c.toUpperCase()).toSet();
    return stale.where((r) => codes.contains(r.code)).toList();
  }
}
