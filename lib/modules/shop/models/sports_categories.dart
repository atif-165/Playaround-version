import 'package:flutter/material.dart';

/// Sports-only categories (PlayAround canonical list)
/// Comprehensive sports equipment and gear categories
class SportsCategories {
  static const List<String> all = [
    'Football',
    'Cricket',
    'Basketball',
    'Tennis',
    'Badminton',
    'Volleyball',
    'Table Tennis',
    'Swimming',
    'Running',
    'Cycling',
    'Gym Equipment',
    'Fitness Accessories',
    'Sportswear',
    'Sports Shoes',
    'Supplements',
    'Sports Bags',
    'Protective Gear',
    'Sports Electronics',
  ];

  /// Get all categories
  static List<String> getAllCategories() => all;

  /// Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'football':
        return Icons.sports_soccer;
      case 'cricket':
        return Icons.sports_cricket;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'badminton':
        return Icons.sports_tennis; // Using tennis icon as placeholder
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'table tennis':
        return Icons.sports_tennis;
      case 'swimming':
        return Icons.pool;
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'gym equipment':
        return Icons.fitness_center;
      case 'fitness accessories':
        return Icons.fitness_center;
      case 'sportswear':
        return Icons.checkroom;
      case 'sports shoes':
        return Icons.sports;
      case 'supplements':
        return Icons.local_pharmacy;
      case 'sports bags':
        return Icons.work_outline;
      case 'protective gear':
        return Icons.security;
      case 'sports electronics':
        return Icons.watch;
      default:
        return Icons.sports;
    }
  }

  /// Check if category exists
  static bool isValidCategory(String category) {
    return all.contains(category);
  }

  /// Get popular categories (featured)
  static List<String> getPopularCategories() {
    return [
      'Football',
      'Cricket',
      'Basketball',
      'Tennis',
      'Gym Equipment',
      'Sportswear',
    ];
  }

  /// Get categories by type
  static List<String> getEquipmentCategories() {
    return [
      'Football',
      'Cricket',
      'Basketball',
      'Tennis',
      'Badminton',
      'Volleyball',
      'Table Tennis',
      'Gym Equipment',
      'Fitness Accessories',
    ];
  }

  static List<String> getApparelCategories() {
    return [
      'Sportswear',
      'Sports Shoes',
      'Sports Bags',
      'Protective Gear',
    ];
  }

  static List<String> getAccessoryCategories() {
    return [
      'Supplements',
      'Sports Electronics',
      'Sports Bags',
      'Fitness Accessories',
    ];
  }
}

