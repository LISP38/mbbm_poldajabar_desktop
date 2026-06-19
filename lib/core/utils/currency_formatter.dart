import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove any non-digit character (like existing dots or commas)
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse to int, then format back with Indonesian Locale
    int value = int.parse(newText);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '', // Prefix is handled by InputDecoration
      decimalDigits: 0,
    );
    
    String formattedText = formatter.format(value).trim();

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// Helper to safely parse the formatted string back to a double/int
double parseFormattedCurrency(String text) {
  if (text.isEmpty) return 0.0;
  return double.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
}
