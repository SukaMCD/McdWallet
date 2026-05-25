class OcrResultModel {
  final String merchantName;
  final double amount;
  final DateTime date;
  final String? suggestedCategoryName;

  const OcrResultModel({
    required this.merchantName,
    required this.amount,
    required this.date,
    this.suggestedCategoryName,
  });

  OcrResultModel copyWith({
    String? merchantName,
    double? amount,
    DateTime? date,
    String? suggestedCategoryName,
  }) {
    return OcrResultModel(
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      suggestedCategoryName: suggestedCategoryName ?? this.suggestedCategoryName,
    );
  }

  @override
  String toString() {
    return 'OcrResultModel(merchantName: $merchantName, amount: $amount, date: $date, suggestedCategoryName: $suggestedCategoryName)';
  }
}
