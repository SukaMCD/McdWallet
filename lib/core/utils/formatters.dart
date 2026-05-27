import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../features/forex/domain/forex_rate_model.dart';

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

  // Format mata uang kustom berdasarkan kode mata uang (offline-friendly)
  static String formatCurrencyWithCode(double amount, String currencyCode) {
    if (currencyCode.toUpperCase() == 'IDR') {
      return formatCurrency(amount);
    }
    final symbol = CurrencyMetadata.getSymbol(currencyCode);
    final formattedVal = NumberFormat.decimalPattern('id_ID').format(amount);
    return '$symbol $formattedVal';
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
    if (newValue.selection.baseOffset == 0 || newValue.text.isEmpty) {
      return newValue;
    }

    final String text = newValue.text;
    
    // Cari posisi koma decimal
    final int commaIndex = text.indexOf(',');
    String integerPart = text;
    String? decimalPart;
    
    if (commaIndex != -1) {
      integerPart = text.substring(0, commaIndex);
      decimalPart = text.substring(commaIndex + 1);
    }
    
    // Bersihkan bagian integer
    String cleanInt = integerPart.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanInt.isEmpty && commaIndex == -1) {
      return newValue.copyWith(text: '');
    }
    if (cleanInt.isEmpty && commaIndex != -1) {
      cleanInt = '0';
    }
    
    final double value = double.parse(cleanInt);
    final formatter = NumberFormat.decimalPattern('id_ID');
    String formattedInt = formatter.format(value);
    
    String newText = formattedInt;
    if (commaIndex != -1) {
      String cleanDec = decimalPart!.replaceAll(RegExp(r'[^0-9]'), '');
      // Batasi 2 digit desimal untuk valas
      if (cleanDec.length > 2) {
        cleanDec = cleanDec.substring(0, 2);
      }
      newText = '$formattedInt,$cleanDec';
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
