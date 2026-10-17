import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 1. If the field is cleared, return empty
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 2. Strip everything that isn't a digit
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 3. Convert to a number (handling potential empty strings after stripping)
    double value = double.parse(newText.isEmpty ? '0' : newText);

    // 4. Format the number
    // Use .simpleCurrency(decimalDigits: 0) to avoid adding .00 automatically
    final formatter = NumberFormat.currency(
      locale: 'en_NG', name: 'NGN', // or your specific locale
      symbol: '₦',
      decimalDigits: 0,
    );

    String formatted = formatter.format(value);

    // 5. Return the new value and keep the cursor at the end
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
