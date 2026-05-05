import 'package:flutter/material.dart';

import 'package:tpm_ta/services/apparel_api_service.dart';

class ApiCatalogScreen extends StatefulWidget {
  const ApiCatalogScreen({super.key});

  @override
  State<ApiCatalogScreen> createState() => _ApiCatalogScreenState();
}

class _ApiCatalogScreenState extends State<ApiCatalogScreen> {
  final ApparelApiService _apiService = ApparelApiService();
  late Future<List<ApparelProduct>> _productsFuture;

  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _productsFuture = _apiService.fetchApparelProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _productsFuture = _apiService.fetchApparelProducts();
    });
    await _productsFuture;
  }

  List<ApparelProduct> _filterProducts(List<ApparelProduct> products) {
    if (_selectedCategory == 'All') return products;

    return products
        .where((product) => product.category == _selectedCategory)
        .toList();
  }

  String _formatIdr(double value) {
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  String _formatUsd(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Apparel API'),
        actions: [
          IconButton(
            onPressed: _refreshProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh products',
          ),
        ],
      ),
      body: FutureBuilder<List<ApparelProduct>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final products = snapshot.data ?? [];
          final filteredProducts = _filterProducts(products);

          return RefreshIndicator(
            onRefresh: _refreshProducts,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(products),
                const SizedBox(height: 16),
                _buildCategoryFilters(products),
                const SizedBox(height: 16),
                _buildProductList(filteredProducts),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Unable to load apparel data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _refreshProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<ApparelProduct> products) {
    final averagePrice = products.isEmpty
        ? 0.0
        : products
                .map((product) => product.priceIdr)
                .reduce((first, second) => first + second) /
            products.length;
    final topRated = products.isEmpty ? null : products.first;

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
                child: const Icon(Icons.cloud_sync),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'External Apparel Feed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Products',
                  value: products.length.toString(),
                  icon: Icons.inventory_2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Avg Price',
                  value: _formatIdr(averagePrice),
                  icon: Icons.payments,
                ),
              ),
            ],
          ),
          if (topRated != null) ...[
            const SizedBox(height: 14),
            Text(
              'Top rated: ${topRated.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.deepPurple.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(List<ApparelProduct> products) {
    final categories = [
      'All',
      ...products.map((product) => product.category).toSet(),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories
          .map(
            (category) => ChoiceChip(
              label: Text(category == 'All' ? 'All apparel' : category),
              selected: _selectedCategory == category,
              onSelected: (_) {
                setState(() => _selectedCategory = category);
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildProductList(List<ApparelProduct> products) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text('No apparel products found.')),
      );
    }

    return Column(
      children: products
          .map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProductTile(product),
            ),
          )
          .toList(),
    );
  }

  Widget _buildProductTile(ApparelProduct product) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 76,
                height: 76,
                color: Colors.grey.shade100,
                child: product.imageUrl.isEmpty
                    ? const Icon(Icons.checkroom, size: 36)
                    : Image.network(
                        product.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.checkroom, size: 36),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.category,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${product.ratingRate.toStringAsFixed(1)} '
                        '(${product.ratingCount})',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatIdr(product.priceIdr),
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatUsd(product.priceUsd),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
