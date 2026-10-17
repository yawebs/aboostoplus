import 'package:flutter/services.dart';

class PercentageInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 1. If the field is cleared, return empty
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 2. Strip everything except digits
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 3. Prevent leading zeros (e.g., "05" becomes "5")
    if (digitsOnly.isNotEmpty) {
      digitsOnly = int.parse(digitsOnly).toString();
    }

    // 4. Cap the percentage at 100 (Optional - common for agent fees)
    if (digitsOnly.isNotEmpty && int.parse(digitsOnly) > 100) {
      digitsOnly = "100";
    }

    // 5. Format the string (Place % at start or end)
    // For %10:
    String formatted = digitsOnly.isEmpty ? '' : '%$digitsOnly';

    // For 10%:
    // String formatted = digitsOnly.isEmpty ? '' : '$digitsOnly%';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
