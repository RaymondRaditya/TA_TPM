import 'package:flutter/material.dart';
import 'package:tpm_ta/services/currency_service.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: '150000',
  );

  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  final CurrencyService _currencyService = CurrencyService();
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _currencyService.fetchExchangeRates();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  double get _amount {
    final normalizedValue = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(normalizedValue) ?? 0;
  }

  double get _convertedAmount {
    return _currencyService.convert(_amount, _fromCurrency, _toCurrency);
  }

  void _swapCurrencies() {
    setState(() {
      final previousFromCurrency = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = previousFromCurrency;
    });
  }

  void _applyPreset(double amountInIdr) {
    setState(() {
      _fromCurrency = 'IDR';
      _amountController.text = amountInIdr.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final convertedAmount = _convertedAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRates,
            tooltip: 'Refresh rates',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, convertedAmount),
            const SizedBox(height: 16),
            if (_hasError)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to fetch live rates. Tap refresh to retry.',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildConverterForm(),
              const SizedBox(height: 16),
              _buildProductionPresets(),
              const SizedBox(height: 16),
              _buildRateReference(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double convertedAmount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.currency_exchange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'T-Shirt Price Converter',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _currencyService.formatCurrency(_toCurrency, convertedAmount),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_currencyService.formatCurrency(_fromCurrency, _amount)} in $_toCurrency',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildConverterForm() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCurrencyDropdown(
                    label: 'From',
                    value: _fromCurrency,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _fromCurrency = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: _swapCurrencies,
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: 'Swap currencies',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCurrencyDropdown(
                    label: 'To',
                    value: _toCurrency,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _toCurrency = value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final currencies = _currencyService.availableCurrencies;
    return DropdownButtonFormField<String>(
      value: currencies.contains(value) ? value : (currencies.isNotEmpty ? currencies.first : null),
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: currencies
          .map(
            (code) => DropdownMenuItem<String>(value: code, child: Text(code)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildProductionPresets() {
    const presets = [
      _ProductionPreset(label: 'Basic Tee', amountInIdr: 75000),
      _ProductionPreset(label: 'Custom Print', amountInIdr: 150000),
      _ProductionPreset(label: 'Premium Set', amountInIdr: 300000),
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Shirt Estimates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets
                  .map(
                    (preset) => ActionChip(
                      avatar: const Icon(Icons.checkroom, size: 18),
                      label: Text(
                        '${preset.label} (IDR ${preset.amountInIdr.toStringAsFixed(0)})',
                      ),
                      onPressed: () => _applyPreset(preset.amountInIdr),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Text(
              'Current estimate in $_toCurrency: '
              '${_currencyService.formatCurrency(_toCurrency, _currencyService.convertFromIdr(_amount, _toCurrency))}',
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateReference() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Realtime Exchange Rates (vs USD)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_currencyService.exchangeRates.isEmpty)
              Text(
                'No rates available',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ..._currencyService.exchangeRates.entries
                  .take(10)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '1 USD = ${entry.value.toStringAsFixed(2)} ${entry.key}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            if (_currencyService.exchangeRates.length > 10) ...[
              const SizedBox(height: 8),
              Text(
                '+${_currencyService.exchangeRates.length - 10} more currencies',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductionPreset {
  const _ProductionPreset({required this.label, required this.amountInIdr});

  final String label;
  final double amountInIdr;
}
