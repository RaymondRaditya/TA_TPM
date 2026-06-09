import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  Map<String, double> _exchangeRates = {};
  List<String> _availableCurrencies = [];
  DateTime? _lastFetchTime;
  static const int _cacheDurationMinutes = 60;

  Map<String, double> get exchangeRates => _exchangeRates;
  List<String> get availableCurrencies => _availableCurrencies;

  Future<void> fetchExchangeRates() async {
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes <
            _cacheDurationMinutes) {
      return;
    }

    try {
      final response = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = Map<String, double>.from(
          (data['rates'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ),
        );

        _exchangeRates = rates;
        _availableCurrencies = rates.keys.toList()..sort();
        _lastFetchTime = DateTime.now();
      } else {
        throw Exception('Failed to fetch rates');
      }
    } catch (e) {
      rethrow;
    }
  }

  double convert(double amount, String from, String to) {
    if (_exchangeRates.isEmpty) return amount;
    final fromRate = _exchangeRates[from] ?? 1;
    final toRate = _exchangeRates[to] ?? 1;
    return (amount / fromRate) * toRate;
  }

  double convertFromIdr(double amountInIdr, String targetCurrency) {
    return convert(amountInIdr, 'IDR', targetCurrency);
  }

  String formatCurrency(String code, double value) {
    final decimalPlaces = code == 'IDR' ? 0 : 2;
    if (code == 'IDR') {
      return 'Rp ${value.toStringAsFixed(0)}';
    }
    
    String symbol = '';
    switch (code) {
      case 'USD': symbol = '\$'; break;
      case 'EUR': symbol = '€'; break;
      case 'GBP': symbol = '£'; break;
      default: symbol = '$code ';
    }
    
    return '$symbol${value.toStringAsFixed(decimalPlaces)}';
  }
}
