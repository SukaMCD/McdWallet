import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class Formatters {
  // Format mata uang Rupiah (IDR)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Format tanggal Indonesia dengan Hari (contoh: Minggu, 24 Mei 2026)
  static String formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  // Format tanggal pendek (contoh: 24 Mei)
  static String formatDateShort(DateTime date) {
    return DateFormat('d MMM', 'id_ID').format(date);
  }

  // Format tanggal & waktu lengkap (contoh: 24 Mei 2026, 17:50)
  static String formatDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(date);
  }

  // Format hanya Jam (contoh: 17:50)
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'id_ID').format(date);
  }
}

class IndonesianCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Hanya ambil angka saja
    final String cleanString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanString.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final double value = double.parse(cleanString);
    final formatter = NumberFormat.decimalPattern('id_ID');
    final String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
