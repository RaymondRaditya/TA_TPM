import 'package:flutter/material.dart';

import 'package:tpm_ta/services/notification_service.dart';

class SearchFilterNotificationScreen extends StatefulWidget {
  const SearchFilterNotificationScreen({super.key});

  @override
  State<SearchFilterNotificationScreen> createState() =>
      _SearchFilterNotificationScreenState();
}

class _SearchFilterNotificationScreenState
    extends State<SearchFilterNotificationScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String _selectedCategory = 'All';
  String _selectedPrice = 'All';
  bool _showReadyStockOnly = false;

  static const List<_ShirtDrop> _drops = [
    _ShirtDrop(
      name: 'Campus Tech Tee',
      category: 'Event',
      priceIdr: 120000,
      color: Colors.deepPurple,
      readyStock: true,
    ),
    _ShirtDrop(
      name: 'Bali Pop-Up Cotton',
      category: 'Travel',
      priceIdr: 175000,
      color: Colors.teal,
      readyStock: true,
    ),
    _ShirtDrop(
      name: 'London Minimal Logo',
      category: 'Minimal',
      priceIdr: 220000,
      color: Colors.blueGrey,
      readyStock: false,
    ),
    _ShirtDrop(
      name: 'Retro Print Workshop',
      category: 'Vintage',
      priceIdr: 95000,
      color: Colors.orange,
      readyStock: true,
    ),
    _ShirtDrop(
      name: 'Future Fabric Drop',
      category: 'Futuristic',
      priceIdr: 260000,
      color: Colors.indigo,
      readyStock: false,
    ),
  ];

  List<_ShirtDrop> get _filteredDrops {
    return _drops.where((drop) {
      final matchesQuery =
          drop.name.toLowerCase().contains(_query.toLowerCase()) ||
              drop.category.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || drop.category == _selectedCategory;
      final matchesPrice = switch (_selectedPrice) {
        'Under 150k' => drop.priceIdr < 150000,
        '150k-220k' => drop.priceIdr >= 150000 && drop.priceIdr <= 220000,
        'Over 220k' => drop.priceIdr > 220000,
        _ => true,
      };
      final matchesStock = !_showReadyStockOnly || drop.readyStock;

      return matchesQuery && matchesCategory && matchesPrice && matchesStock;
    }).toList();
  }

  Future<void> _sendDropNotification(_ShirtDrop drop) async {
    await NotificationService().showNotification(
      drop.name.hashCode.abs() % 100000,
      'T-Shirt Drop Alert',
      '${drop.name} is ${drop.readyStock ? 'ready to order' : 'saved for restock updates'}.',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification sent for ${drop.name}.')),
    );
  }

  String _formatPrice(double value) {
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _selectedCategory = 'All';
      _selectedPrice = 'All';
      _showReadyStockOnly = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drops = _filteredDrops;

    return Scaffold(
      appBar: AppBar(title: const Text('Search & Alerts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(drops.length),
          const SizedBox(height: 16),
          _buildSearchAndFilters(),
          const SizedBox(height: 16),
          _buildDropList(drops),
        ],
      ),
    );
  }

  Widget _buildHeader(int resultCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.manage_search),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Drop Finder & Alerts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  '$resultCount matching T-shirt drops',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                labelText: 'Search by name or category',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryChips(),
            const SizedBox(height: 10),
            _buildPriceChips(),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _showReadyStockOnly,
              onChanged: (value) {
                setState(() => _showReadyStockOnly = value);
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Ready stock only'),
              secondary: const Icon(Icons.inventory),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      'All',
      ..._drops.map((drop) => drop.category).toSet(),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories
            .map(
              (category) => ChoiceChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (_) {
                  setState(() => _selectedCategory = category);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPriceChips() {
    const priceFilters = ['All', 'Under 150k', '150k-220k', 'Over 220k'];

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: priceFilters
            .map(
              (price) => FilterChip(
                label: Text(price),
                selected: _selectedPrice == price,
                onSelected: (_) {
                  setState(() => _selectedPrice = price);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDropList(List<_ShirtDrop> drops) {
    if (drops.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text('No drops match these filters.')),
      );
    }

    return Column(
      children: drops
          .map(
            (drop) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDropCard(drop),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDropCard(_ShirtDrop drop) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: drop.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.checkroom, color: drop.color, size: 34),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drop.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('${drop.category} - ${_formatPrice(drop.priceIdr)}'),
                  const SizedBox(height: 4),
                  Text(
                    drop.readyStock ? 'Ready stock' : 'Restock watch',
                    style: TextStyle(
                      color: drop.readyStock ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _sendDropNotification(drop),
              icon: const Icon(Icons.notifications_active),
              tooltip: 'Send drop notification',
            ),
          ],
        ),
      ),
    );
  }
}

class _ShirtDrop {
  const _ShirtDrop({
    required this.name,
    required this.category,
    required this.priceIdr,
    required this.color,
    required this.readyStock,
  });

  final String name;
  final String category;
  final double priceIdr;
  final Color color;
  final bool readyStock;
}
