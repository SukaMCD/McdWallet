/// Trend direction for a forex rate comparison
enum ForexTrend { up, down, flat }

/// Model representasi satu nilai tukar mata uang asing terhadap Rupiah (IDR)
class ForexRateModel {
  final String code;         // Kode ISO, e.g. 'USD'
  final String name;         // Nama lokal, e.g. 'Dolar Amerika'
  final String symbol;       // Simbol, e.g. '$'
  final String flag;         // Emoji bendera, e.g. '🇺🇸'
  final double rate;         // IDR per 1 unit mata uang asing (e.g. 15500 utk USD)
  final double previousRate; // Rate sebelumnya (untuk trend)
  final ForexTrend trend;    // Arah pergerakan

  const ForexRateModel({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.rate,
    required this.previousRate,
    required this.trend,
  });

  /// Persentase perubahan dari rate sebelumnya
  double get changePercent {
    if (previousRate <= 0) return 0;
    return ((rate - previousRate) / previousRate) * 100;
  }

  factory ForexRateModel.fromJson(Map<String, dynamic> json) {
    final rate = (json['rate'] as num).toDouble();
    final previousRate = (json['previousRate'] as num?)?.toDouble() ?? rate;

    ForexTrend trend;
    switch (json['trend'] as String? ?? 'flat') {
      case 'up':
        trend = ForexTrend.up;
        break;
      case 'down':
        trend = ForexTrend.down;
        break;
      default:
        trend = ForexTrend.flat;
    }

    return ForexRateModel(
      code: json['code'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      flag: json['flag'] as String? ?? '🌐',
      rate: rate,
      previousRate: previousRate,
      trend: trend,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'symbol': symbol,
        'flag': flag,
        'rate': rate,
        'previousRate': previousRate,
        'trend': trend.name,
      };

  ForexRateModel copyWith({
    double? rate,
    double? previousRate,
    ForexTrend? trend,
  }) {
    return ForexRateModel(
      code: code,
      name: name,
      symbol: symbol,
      flag: flag,
      rate: rate ?? this.rate,
      previousRate: previousRate ?? this.previousRate,
      trend: trend ?? this.trend,
    );
  }
}

// ════════════════════════════════════════════════════════
//  CURRENCY METADATA  (hardcoded – offline friendly)
// ════════════════════════════════════════════════════════

class _CurrencyInfo {
  final String name;
  final String symbol;
  final String flag;
  const _CurrencyInfo(this.name, this.symbol, this.flag);
}

/// Metadata statis mata uang yang didukung.
/// Digunakan sebagai fallback dan untuk tampilan selector.
class CurrencyMetadata {
  static const Map<String, _CurrencyInfo> _currencies = {
    'IDR': _CurrencyInfo('Rupiah Indonesia', 'Rp', '🇮🇩'),
    'USD': _CurrencyInfo('Dolar Amerika', r'$', '🇺🇸'),
    'SGD': _CurrencyInfo('Dolar Singapura', r'S$', '🇸🇬'),
    'EUR': _CurrencyInfo('Euro', '€', '🇪🇺'),
    'JPY': _CurrencyInfo('Yen Jepang', '¥', '🇯🇵'),
    'GBP': _CurrencyInfo('Pound Sterling', '£', '🇬🇧'),
    'MYR': _CurrencyInfo('Ringgit Malaysia', 'RM', '🇲🇾'),
    'AUD': _CurrencyInfo('Dolar Australia', r'A$', '🇦🇺'),
    'CNY': _CurrencyInfo('Yuan Tiongkok', '¥', '🇨🇳'),
    'SAR': _CurrencyInfo('Riyal Arab Saudi', 'SR', '🇸🇦'),
    'AED': _CurrencyInfo('Dirham UAE', 'د.إ', '🇦🇪'),
    'KRW': _CurrencyInfo('Won Korea Selatan', '₩', '🇰🇷'),
    'HKD': _CurrencyInfo('Dolar Hong Kong', r'HK$', '🇭🇰'),
    'CHF': _CurrencyInfo('Franc Swiss', 'Fr', '🇨🇭'),
    'CAD': _CurrencyInfo('Dolar Kanada', r'CA$', '🇨🇦'),
    'THB': _CurrencyInfo('Baht Thailand', '฿', '🇹🇭'),
    'INR': _CurrencyInfo('Rupee India', '₹', '🇮🇳'),
    'PHP': _CurrencyInfo('Peso Filipina', '₱', '🇵🇭'),
    'TWD': _CurrencyInfo('Dolar Taiwan', r'NT$', '🇹🇼'),
    'NZD': _CurrencyInfo('Dolar Selandia Baru', r'NZ$', '🇳🇿'),
    'SEK': _CurrencyInfo('Krona Swedia', 'kr', '🇸🇪'),
    'DKK': _CurrencyInfo('Krone Denmark', 'kr', '🇩🇰'),
    'NOK': _CurrencyInfo('Krone Norwegia', 'kr', '🇳🇴'),
    'BRL': _CurrencyInfo('Real Brasil', r'R$', '🇧🇷'),
    'ZAR': _CurrencyInfo('Rand Afrika Selatan', 'R', '🇿🇦'),
    'TRY': _CurrencyInfo('Lira Turki', '₺', '🇹🇷'),
    'PKR': _CurrencyInfo('Rupee Pakistan', '₨', '🇵🇰'),
    'VND': _CurrencyInfo('Dong Vietnam', '₫', '🇻🇳'),
    'QAR': _CurrencyInfo('Riyal Qatar', 'QR', '🇶🇦'),
    'KWD': _CurrencyInfo('Dinar Kuwait', 'KD', '🇰🇼'),
    'MXN': _CurrencyInfo('Peso Meksiko', r'MX$', '🇲🇽'),
    'RUB': _CurrencyInfo('Rubel Rusia', '₽', '🇷🇺'),
    'BDT': _CurrencyInfo('Taka Bangladesh', '৳', '🇧🇩'),
  };

  static String getName(String code) =>
      _currencies[code.toUpperCase()]?.name ?? code;

  static String getSymbol(String code) =>
      _currencies[code.toUpperCase()]?.symbol ?? code;

  static String getFlag(String code) =>
      _currencies[code.toUpperCase()]?.flag ?? '🌐';

  static bool isSupported(String code) =>
      _currencies.containsKey(code.toUpperCase());

  static List<String> get allCodes => _currencies.keys.toList();

  /// Daftar semua mata uang sebagai Map untuk keperluan UI
  static List<Map<String, String>> get allCurrencies => _currencies.entries
      .map((e) => {
            'code': e.key,
            'name': e.value.name,
            'symbol': e.value.symbol,
            'flag': e.value.flag,
          })
      .toList();
}
