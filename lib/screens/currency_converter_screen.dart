import 'package:flutter/material.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  static const Map<String, _CurrencyInfo> _currencies = {
    'IDR': _CurrencyInfo(
      code: 'IDR',
      name: 'Indonesian Rupiah',
      symbol: 'Rp',
      unitsPerUsd: 15600,
    ),
    'USD': _CurrencyInfo(
      code: 'USD',
      name: 'US Dollar',
      symbol: r'$',
      unitsPerUsd: 1,
    ),
    'EUR': _CurrencyInfo(
      code: 'EUR',
      name: 'Euro',
      symbol: 'EUR',
      unitsPerUsd: 0.92,
    ),
    'GBP': _CurrencyInfo(
      code: 'GBP',
      name: 'British Pound',
      symbol: 'GBP',
      unitsPerUsd: 0.79,
    ),
  };

  final TextEditingController _amountController = TextEditingController(
    text: '150000',
  );

  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';

  double get _amount {
    final normalizedValue = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(normalizedValue) ?? 0;
  }

  double get _convertedAmount {
    final fromRate = _currencies[_fromCurrency]!.unitsPerUsd;
    final toRate = _currencies[_toCurrency]!.unitsPerUsd;
    return (_amount / fromRate) * toRate;
  }

  double _convertFromIdr(double amountInIdr, String code) {
    final idrRate = _currencies['IDR']!.unitsPerUsd;
    final targetRate = _currencies[code]!.unitsPerUsd;
    return (amountInIdr / idrRate) * targetRate;
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

  String _formatCurrency(String code, double value) {
    final currency = _currencies[code]!;
    final decimalPlaces = code == 'IDR' ? 0 : 2;
    return '${currency.symbol} ${value.toStringAsFixed(decimalPlaces)}';
  }

  String _formatRateValue(_CurrencyInfo currency) {
    final decimalPlaces = currency.code == 'IDR' ? 0 : 2;
    return currency.unitsPerUsd.toStringAsFixed(decimalPlaces);
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
      appBar: AppBar(title: const Text('Currency Converter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, convertedAmount),
            const SizedBox(height: 16),
            _buildConverterForm(),
            const SizedBox(height: 16),
            _buildProductionPresets(),
            const SizedBox(height: 16),
            _buildRateReference(),
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
            _formatCurrency(_toCurrency, convertedAmount),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatCurrency(_fromCurrency, _amount)} in $_toCurrency',
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
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: _currencies.values
          .map(
            (currency) => DropdownMenuItem<String>(
              value: currency.code,
              child: Text('${currency.code} - ${currency.name}'),
            ),
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
                        '${preset.label} (${_formatCurrency('IDR', preset.amountInIdr)})',
                      ),
                      onPressed: () => _applyPreset(preset.amountInIdr),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Text(
              'Current estimate in $_toCurrency: '
              '${_formatCurrency(_toCurrency, _convertFromIdr(_amount, _toCurrency))}',
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
              'Static Rate Reference',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._currencies.values.map(
              (currency) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        currency.code,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '1 USD = ${_formatRateValue(currency)} ${currency.code}',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyInfo {
  const _CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.unitsPerUsd,
  });

  final String code;
  final String name;
  final String symbol;
  final double unitsPerUsd;
}

class _ProductionPreset {
  const _ProductionPreset({
    required this.label,
    required this.amountInIdr,
  });

  final String label;
  final double amountInIdr;
}
