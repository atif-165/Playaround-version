import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final double? originalPrice; // for discounts
  final String category; // sports-specific
  final String ownerId; // seller's userId
  final String shopId; // partner shop ID
  final String shopName; // partner shop name
  final List<String> images;
  final List<String> sizes;
  final List<String> colors;
  final int stock;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final Map<String, dynamic> specifications;
  final bool isFeatured;
  final bool isExclusive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.ownerId,
    required this.shopId,
    required this.shopName,
    required this.images,
    required this.sizes,
    required this.colors,
    required this.stock,
    required this.isAvailable,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    required this.specifications,
    required this.isFeatured,
    required this.isExclusive,
    required this.createdAt,
    required this.updatedAt,
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
      originalPrice: data['originalPrice'] != null
          ? (data['originalPrice'] is int)
              ? (data['originalPrice'] as int).toDouble()
              : (data['originalPrice'] ?? 0.0) as double
          : null,
      category: (data['category'] ?? '') as String,
      ownerId: (data['ownerId'] ?? '') as String,
      shopId: (data['shopId'] ?? '') as String,
      shopName: (data['shopName'] ?? '') as String,
      images: (data['images'] as List?)?.cast<String>() ?? const [],
      sizes: (data['sizes'] as List?)?.cast<String>() ?? const [],
      colors: (data['colors'] as List?)?.cast<String>() ?? const [],
      stock: (data['stock'] ?? 0) as int,
      isAvailable: (data['isAvailable'] ?? true) as bool,
      rating: (data['rating'] ?? 0.0) as double,
      reviewCount: (data['reviewCount'] ?? 0) as int,
      tags: (data['tags'] as List?)?.cast<String>() ?? const [],
      specifications: Map<String, dynamic>.from(data['specifications'] ?? {}),
      isFeatured: (data['isFeatured'] ?? false) as bool,
      isExclusive: (data['isExclusive'] ?? false) as bool,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'price': price,
        'originalPrice': originalPrice,
        'category': category,
        'ownerId': ownerId,
        'shopId': shopId,
        'shopName': shopName,
        'images': images,
        'sizes': sizes,
        'colors': colors,
        'stock': stock,
        'isAvailable': isAvailable,
        'rating': rating,
        'reviewCount': reviewCount,
        'tags': tags,
        'specifications': specifications,
        'isFeatured': isFeatured,
        'isExclusive': isExclusive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  Product copyWith({
    String? title,
    String? description,
    double? price,
    double? originalPrice,
    String? category,
    String? shopId,
    String? shopName,
    List<String>? images,
    List<String>? sizes,
    List<String>? colors,
    int? stock,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
    List<String>? tags,
    Map<String, dynamic>? specifications,
    bool? isFeatured,
    bool? isExclusive,
  }) {
    return Product(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      ownerId: ownerId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      images: images ?? this.images,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      tags: tags ?? this.tags,
      specifications: specifications ?? this.specifications,
      isFeatured: isFeatured ?? this.isFeatured,
      isExclusive: isExclusive ?? this.isExclusive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  double get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0.0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
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

