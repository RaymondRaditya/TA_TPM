import 'dart:convert';

import 'package:http/http.dart' as http;

class ApparelApiService {
  static const List<String> _categories = [
    "men's clothing",
    "women's clothing",
  ];

  Future<List<ApparelProduct>> fetchApparelProducts() async {
    final responses = await Future.wait(
      _categories.map(_fetchProductsByCategory),
    );

    final products = responses.expand((items) => items).toList()
      ..sort((first, second) => second.ratingRate.compareTo(first.ratingRate));

    return products;
  }

  Future<List<ApparelProduct>> _fetchProductsByCategory(String category) async {
    final uri = Uri.parse(
      'https://fakestoreapi.com/products/category/'
      '${Uri.encodeComponent(category)}',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw ApparelApiException(
        'Failed to load $category products (${response.statusCode}).',
      );
    }

    final decodedBody = json.decode(response.body);
    if (decodedBody is! List) {
      throw const ApparelApiException('Unexpected apparel API response.');
    }

    return decodedBody
        .whereType<Map<String, dynamic>>()
        .map(ApparelProduct.fromJson)
        .toList();
  }
}

class ApparelProduct {
  const ApparelProduct({
    required this.id,
    required this.title,
    required this.priceUsd,
    required this.category,
    required this.imageUrl,
    required this.ratingRate,
    required this.ratingCount,
  });

  final int id;
  final String title;
  final double priceUsd;
  final String category;
  final String imageUrl;
  final double ratingRate;
  final int ratingCount;

  double get priceIdr => priceUsd * 15600;

  factory ApparelProduct.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'];

    return ApparelProduct(
      id: _readInt(json['id']),
      title: json['title']?.toString() ?? 'Untitled product',
      priceUsd: _readDouble(json['price']),
      category: json['category']?.toString() ?? 'apparel',
      imageUrl: json['image']?.toString() ?? '',
      ratingRate: rating is Map<String, dynamic>
          ? _readDouble(rating['rate'])
          : 0,
      ratingCount: rating is Map<String, dynamic>
          ? _readInt(rating['count'])
          : 0,
    );
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ApparelApiException implements Exception {
  const ApparelApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
