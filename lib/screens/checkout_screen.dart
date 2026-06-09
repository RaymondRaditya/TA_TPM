import 'package:flutter/material.dart';
import 'package:tpm_ta/services/notification_service.dart';
import 'package:tpm_ta/screens/mini_game_screen.dart';
import 'package:tpm_ta/services/database_helper.dart';
import 'package:tpm_ta/services/currency_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  String selectedCurrency = 'IDR';
  bool _hasDiscount = false;
  final CurrencyService _currencyService = CurrencyService();

  @override
  void initState() {
    super.initState();
    _loadCartAndRates();
  }

  Future<void> _loadCartAndRates() async {
    setState(() => _isLoading = true);
    try {
      final items = await DatabaseHelper.instance.getCartItems();
      await _currencyService.fetchExchangeRates();
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading checkout: $e');
      setState(() => _isLoading = false);
    }
  }

  double get _totalPriceIdr {
    double total = 0;
    for (final item in _cartItems) {
      total += (item[DatabaseHelper.columnCartPrice] as num).toDouble();
    }
    return total;
  }

  double get _finalPriceIdr => _hasDiscount ? _totalPriceIdr * 0.9 : _totalPriceIdr;

  Future<void> _removeItem(int id) async {
    await DatabaseHelper.instance.deleteCartItem(id);
    _loadCartAndRates();
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

  Map<String, String> _getEstimatedDeliveryTimes() {
    final currentTime = DateTime.now();
    final deliveryTimeLocal = currentTime.add(const Duration(hours: 2));
    final deliveryTimeUtc = deliveryTimeLocal.toUtc();

    String formatTime(DateTime dt) {
      final hours = dt.hour.toString().padLeft(2, '0');
      final minutes = dt.minute.toString().padLeft(2, '0');
      return '$hours:$minutes';
    }

    return {
      'WIB (UTC+7)': formatTime(deliveryTimeUtc.add(const Duration(hours: 7))),
      'WITA (UTC+8)': formatTime(deliveryTimeUtc.add(const Duration(hours: 8))),
      'WIT (UTC+9)': formatTime(deliveryTimeUtc.add(const Duration(hours: 9))),
      'Europe/London (UTC+0)': formatTime(deliveryTimeUtc.add(const Duration(hours: 0))),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final deliveryTimes = _getEstimatedDeliveryTimes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout / Keranjang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCartAndRates,
          ),
        ],
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Keranjang Anda kosong.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali ke Desain'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cartItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final price = (item[DatabaseHelper.columnCartPrice] as num).toDouble();
                      return Card(
                        elevation: 0,
                        color: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Color(item[DatabaseHelper.columnCartColor] as int),
                            child: const Icon(Icons.checkroom, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            item[DatabaseHelper.columnCartItemName] ?? 'Custom Design',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Tipe: ${item[DatabaseHelper.columnCartItemType]} | Size: ${item[DatabaseHelper.columnCartItemSize]}\n'
                            '${_currencyService.formatCurrency(selectedCurrency, _currencyService.convertFromIdr(price, selectedCurrency))}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeItem(item[DatabaseHelper.columnCartId] as int),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pilih Mata Uang:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: selectedCurrency,
                        items: _currencyService.availableCurrencies.isEmpty
                            ? [const DropdownMenuItem(value: 'IDR', child: Text('IDR'))]
                            : _currencyService.availableCurrencies.map((String currency) {
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Harga:', style: TextStyle(fontSize: 16)),
                            Text(
                              _currencyService.formatCurrency(selectedCurrency, _currencyService.convertFromIdr(_totalPriceIdr, selectedCurrency)),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (_hasDiscount) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Diskon 10%:', style: TextStyle(fontSize: 16, color: Colors.green)),
                              Text(
                                '- ${_currencyService.formatCurrency(selectedCurrency, _currencyService.convertFromIdr(_totalPriceIdr * 0.1, selectedCurrency))}',
                                style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(
                              _currencyService.formatCurrency(selectedCurrency, _currencyService.convertFromIdr(_finalPriceIdr, selectedCurrency)),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!_hasDiscount) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _playMiniGame,
                      icon: const Icon(Icons.videogame_asset),
                      label: const Text('Main Mini-Game untuk Diskon 10%!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Text(
                    'Estimated Delivery Time',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: deliveryTimes.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(fontSize: 14)),
                                Text(entry.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await NotificationService().showNotification(
                          0,
                          'Pesanan Dikonfirmasi!',
                          'Pesanan Anda sedang diproses. Terima kasih!',
                        );
                      } catch (e) {
                        debugPrint('Notification failed: $e');
                      }
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Pembayaran Berhasil'),
                            content: const Text('Terima kasih! Pesanan Anda telah berhasil diproses.'),
                            actions: [
                              ElevatedButton(
                                onPressed: () async {
                                  await DatabaseHelper.instance.clearCart();
                                  if (context.mounted) {
                                    Navigator.pop(context); // close dialog
                                    Navigator.pop(context); // go back from checkout
                                  }
                                },
                                child: const Text('OK'),
                              )
                            ],
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('Konfirmasi Pembayaran', style: TextStyle(fontSize: 18)),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
