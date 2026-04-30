import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final double _basePriceIdr = 150000.0;
  String _selectedCurrency = 'IDR';

  final List<String> _currencies = ['IDR', 'USD', 'EUR', 'GBP'];

  // 1) Currency Conversion Utility
  String _getConvertedPrice() {
    // Static approximate exchange rates relative to IDR
    const ratesToIdr = {
      'IDR': 1.0,
      'USD': 0.000064, // ~1 USD = 15,625 IDR
      'EUR': 0.000059, // ~1 EUR = 16,949 IDR
      'GBP': 0.000051, // ~1 GBP = 19,607 IDR
    };

    final rate = ratesToIdr[_selectedCurrency] ?? 1.0;
    final converted = _basePriceIdr * rate;

    switch (_selectedCurrency) {
      case 'USD':
        return '\$${converted.toStringAsFixed(2)}';
      case 'EUR':
        return '€${converted.toStringAsFixed(2)}';
      case 'GBP':
        return '£${converted.toStringAsFixed(2)}';
      case 'IDR':
      default:
        return 'Rp ${_basePriceIdr.toStringAsFixed(0)}';
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
                  value: _selectedCurrency,
                  items: _currencies.map((String currency) {
                    return DropdownMenuItem<String>(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCurrency = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getConvertedPrice(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.right,
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order Placed Successfully!'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
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
