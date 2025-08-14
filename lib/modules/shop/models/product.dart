import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category; // sports-specific
  final String ownerId; // seller's userId
  final List<String> images;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.ownerId,
    required this.images,
    required this.createdAt,
  });

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Product(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] ?? 0.0) as double,
      category: (data['category'] ?? '') as String,
      ownerId: (data['ownerId'] ?? '') as String,
      images: (data['images'] as List?)?.cast<String>() ?? const [],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'ownerId': ownerId,
        'images': images,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// Simple DTO for lightweight listing tiles
class ProductSummary {
  final String id;
  final String title;
  final double price;
  final String thumbnail;
  final String category;

  ProductSummary({
    required this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
    required this.category,
  });
}

