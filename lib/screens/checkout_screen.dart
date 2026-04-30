import 'package:flutter/material.dart';
import 'package:tpm_ta/services/notification_service.dart';
import 'package:tpm_ta/screens/mini_game_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final double _basePriceIdr = 150000.0;
  String selectedCurrency = 'IDR';
  bool _hasDiscount = false;
  final Map<String, double> exchangeRates = {
    'IDR': 1.0,
    'USD': 0.000064, // ~1 USD = 15,625 IDR
    'EUR': 0.000059, // ~1 EUR = 16,949 IDR
    'GBP': 0.000050, // ~1 GBP = 20,000 IDR
  };

  // 1) Currency Conversion Utility
  String getFormattedTotal(double basePriceIdr) {
    final double finalBasePrice = _hasDiscount
        ? basePriceIdr * 0.9
        : basePriceIdr;
    final rate = exchangeRates[selectedCurrency] ?? 1.0;
    final converted = finalBasePrice * rate;

    switch (selectedCurrency) {
      case 'USD':
        return '\$${converted.toStringAsFixed(2)}';
      case 'EUR':
        return '€${converted.toStringAsFixed(2)}';
      case 'GBP':
        return '£${converted.toStringAsFixed(2)}';
      case 'IDR':
      default:
        // For IDR, it's better to show the original base price without conversion artifacts
        return 'Rp ${finalBasePrice.toStringAsFixed(0)}';
    }
  }

  Future<void> _playMiniGame() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MiniGameScreen()),
    );
    if (result == 'DISCOUNT_10') {
      setState(() {
        _hasDiscount = true;
      });
    }
  }

  // 2) Time Conversion Utility
  Map<String, String> _getEstimatedDeliveryTimes() {
    final currentTime = DateTime.now();
    // Delivery estimated at 2 hours from current time
    final deliveryTimeLocal = currentTime.add(const Duration(hours: 2));

    // Convert to a standardized UTC baseline to calculate fixed offsets reliably
    final deliveryTimeUtc = deliveryTimeLocal.toUtc();

    String formatTime(DateTime dt) {
      final hours = dt.hour.toString().padLeft(2, '0');
      final minutes = dt.minute.toString().padLeft(2, '0');
      return '$hours:$minutes';
    }

    // Applying standard Duration logic for timezones relative to UTC
    return {
      'WIB (UTC+7)': formatTime(deliveryTimeUtc.add(const Duration(hours: 7))),
      'WITA (UTC+8)': formatTime(deliveryTimeUtc.add(const Duration(hours: 8))),
      'WIT (UTC+9)': formatTime(deliveryTimeUtc.add(const Duration(hours: 9))),
      'Europe/London (UTC+0)': formatTime(
        deliveryTimeUtc.add(const Duration(hours: 0)),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final deliveryTimes = _getEstimatedDeliveryTimes();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'T-Shirt Base Price:',
                  style: TextStyle(fontSize: 18),
                ),
                DropdownButton<String>(
                  value: selectedCurrency,
                  items: exchangeRates.keys.map((String currency) {
                    return DropdownMenuItem<String>(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedCurrency = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              getFormattedTotal(_basePriceIdr),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.right,
            ),
            if (_hasDiscount)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  '10% Discount Applied!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            const SizedBox(height: 16),
            if (!_hasDiscount)
              ElevatedButton.icon(
                onPressed: _playMiniGame,
                icon: const Icon(Icons.videogame_asset),
                label: const Text('Play Mini-Game for 10% Off!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            const Divider(height: 48, thickness: 1),
            const Text(
              'Estimated Delivery Time',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: deliveryTimes.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                await NotificationService().showNotification(
                  0,
                  'Order Confirmed!',
                  'Your T-Shirt order has been successfully placed.',
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.check_circle, size: 24),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Confirm Payment', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
