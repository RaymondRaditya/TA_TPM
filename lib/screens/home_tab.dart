import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:tpm_ta/screens/tshirt_canvas_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock list of T-Shirt products
  List<Map<String, dynamic>> _mockProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchExternalProducts();
  }

  Future<void> _fetchExternalProducts() async {
    try {
      final response = await http.get(
        Uri.parse("https://fakestoreapi.com/products/category/men's clothing"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _mockProducts = data
              .where((item) {
                final category = item['category'].toString().toLowerCase();
                return category.contains("men's clothing") || category.contains("women's clothing");
              })
              .map(
                (item) => {
                  'name': item['title'],
                  // Use blank template mockup image instead of actual product model photo
                  'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Jersey_white.svg/500px-Jersey_white.svg.png',
                  'price': (item['price'] * 15600)
                      .toInt(), // Convert USD to IDR
                },
              )
              .toList();
        });
      }
    } catch (e) {
      // API fetch failed
    }
  }

  // Getter to dynamically filter the mock list based on the search query
  List<Map<String, dynamic>> get filteredProducts {
    if (_searchQuery.isEmpty) {
      return _mockProducts;
    }
    return _mockProducts.where((product) {
      final name = product['name'].toString().toLowerCase();
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
    final products = filteredProducts;

    return Scaffold(
      body: SingleChildScrollView(
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
                  hintText: 'Search T-Shirts...',
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
                itemCount: products.length > 5 ? 5 : products.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(context, products[index], isHorizontal: true);
                },
              ),
            ),

            // Featured Grid
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Featured Designs',
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
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(context, products[index]);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product, {bool isHorizontal = false}) {
    return Container(
      width: isHorizontal ? 160 : null,
      margin: isHorizontal ? const EdgeInsets.symmetric(horizontal: 4.0) : null,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        clipBehavior: Clip.antiAlias, // Required for InkWell to work correctly
        child: InkWell(
          // Fixing the touch bug: Ensure InkWell is the direct child of Card and handles the tap
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DesignPreviewScreen(productName: product['name']),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: Colors.grey.shade100, // Light grey background to make white shirt stand out
                  padding: const EdgeInsets.all(8.0),
                  child: product['image'] != null
                      ? Image.network(
                          product['image'],
                          headers: const {
                            'User-Agent':
                                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
                          },
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
                      product['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${product['price']}',
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

  /// ISSUE 1 Fix: "Hologram" T-shirt placeholder
  Widget _buildHologramPlaceholder() {
    return Opacity(
      opacity: 0.85,
      child: Container(
        color: const Color(0xFFB3E5FC).withValues(alpha: 0.3), // Light blue tint (#B3E5FC at 30%)
        child: const Icon(
          Icons.checkroom, // T-shirt outline shape
          size: 64,
          color: Color(0xFFB3E5FC), // Wireframe blue
        ),
      ),
    );
  }
}

class DesignPreviewScreen extends StatelessWidget {
  final String productName;
  const DesignPreviewScreen({super.key, required this.productName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design Preview')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  productName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Show garment mockup container
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Jersey_white.svg/500px-Jersey_white.svg.png',
                      headers: const {
                        'User-Agent':
                            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
                      },
                      fit: BoxFit.contain,
                    ),
                    Container(
                      width: 120,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurple.withOpacity(0.5), style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'PRINT ZONE',
                        style: TextStyle(
                          color: Colors.deepPurple.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                label: const Text('Kustomisasi & Mulai Desain'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Pratinjau ini menunjukkan area sablon polos pada pakaian. Anda bisa mengkustomisasi sesuka hati.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
