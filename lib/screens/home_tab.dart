import 'package:flutter/material.dart';
import 'package:tpm_ta/services/apparel_api_service.dart';
import 'package:tpm_ta/screens/tshirt_canvas_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ApparelApiService _apiService = ApparelApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late Future<List<ApparelProduct>> _productsFuture;

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

  // Getter to dynamically filter the product list based on the search query
  List<ApparelProduct> _filterProducts(List<ApparelProduct> products) {
    if (_searchQuery.isEmpty) {
      return products;
    }
    return products.where((product) {
      final name = product.title.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: FutureBuilder<List<ApparelProduct>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final products = snapshot.data ?? [];
            final filtered = _filterProducts(products);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Merge Design Logic ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.deepPurple.shade50,
                    child: Column(
                      children: [
                        const Text(
                          'Got a unique idea?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(title: const Text('Design Your Shirt')),
                                  body: const TShirtCanvasScreen(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.design_services),
                          label: const Text('Create Your Own Design'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- End of Merged Design ---

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search Apparel...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),

                  // Trending Category (Horizontal Scroll)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Trending Now',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      itemCount: filtered.length > 5 ? 5 : filtered.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(context, filtered[index], isHorizontal: true);
                      },
                    ),
                  ),

                  // Featured Grid
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Live Apparel Feed',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(context, filtered[index]);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ApparelProduct product, {bool isHorizontal = false}) {
    return Container(
      width: isHorizontal ? 160 : null,
      margin: isHorizontal ? const EdgeInsets.symmetric(horizontal: 4.0) : null,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Navigate directly to TShirtCanvasScreen for customization
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: Text('Custom: ${product.title}')),
                  body: const TShirtCanvasScreen(),
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(8.0),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => _buildHologramPlaceholder(),
                        )
                      : _buildHologramPlaceholder(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${product.priceIdr.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHologramPlaceholder() {
    return Opacity(
      opacity: 0.85,
      child: Container(
        color: const Color(0xFFB3E5FC).withValues(alpha: 0.3),
        child: const Icon(
          Icons.checkroom,
          size: 64,
          color: Color(0xFFB3E5FC),
        ),
      ),
    );
  }
}

