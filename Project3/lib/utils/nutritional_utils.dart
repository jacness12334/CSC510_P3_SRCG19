import 'package:flutter/material.dart';

/// Utility class for determining nutritional badges based on product information.
///
/// Defines thresholds for various nutritional categories and provides methods
/// to calculate which badges a product should display based on its nutritional data.
class NutritionalUtils {
  // Nutritional thresholds (per serving)
  static const int lowFatThreshold = 3; // grams
  static const int lowSodiumThreshold = 140; // mg
  static const int lowSugarThreshold = 5; // grams
  static const int highProteinThreshold = 10; // grams
  static const int lowCalorieThreshold = 120; // calories
  static const int heartHealthyMaxSaturatedFat = 1; // grams
  static const int heartHealthyMaxSodium = 140; // mg

  // /// Generates mock nutritional data based on product category.
  // ///
  // /// This simulates nutritional information for demonstration purposes.
  // /// In a real application, this would come from a database or API.
  // static Map<String, dynamic> generateMockNutrition(String category) {
  //   final upperCategory = category.toUpperCase();

  //   // Default values
  //   int calories = 150;
  //   double totalFat = 5.0;
  //   double saturatedFat = 2.0;
  //   int sodium = 200;
  //   double sugar = 8.0;
  //   double protein = 3.0;

  //   // Category-specific values
  //   if (upperCategory.contains('MILK') || upperCategory.contains('DAIRY')) {
  //     calories = 90;
  //     totalFat = 0.5;
  //     saturatedFat = 0.2;
  //     sodium = 120;
  //     sugar = 12.0;
  //     protein = 8.0;
  //   } else if (upperCategory.contains('CHEESE') ||
  //       upperCategory.contains('YOGURT')) {
  //     calories = 100;
  //     totalFat = 2.5;
  //     saturatedFat = 1.5;
  //     sodium = 150;
  //     sugar = 6.0;
  //     protein = 9.0;
  //   } else if (upperCategory.contains('FRUIT') ||
  //       upperCategory.contains('VEGETABLE')) {
  //     calories = 60;
  //     totalFat = 0.2;
  //     saturatedFat = 0.0;
  //     sodium = 5;
  //     sugar = 10.0;
  //     protein = 1.0;
  //   } else if (upperCategory.contains('BREAD') ||
  //       upperCategory.contains('GRAIN') ||
  //       upperCategory.contains('CEREAL')) {
  //     calories = 110;
  //     totalFat = 1.5;
  //     saturatedFat = 0.3;
  //     sodium = 160;
  //     sugar = 4.0;
  //     protein = 4.0;
  //   } else if (upperCategory.contains('MEAT') ||
  //       upperCategory.contains('BEAN') ||
  //       upperCategory.contains('PEANUT')) {
  //     calories = 140;
  //     totalFat = 2.0;
  //     saturatedFat = 0.5;
  //     sodium = 80;
  //     sugar = 1.0;
  //     protein = 15.0;
  //   } else if (upperCategory.contains('JUICE')) {
  //     calories = 110;
  //     totalFat = 0.0;
  //     saturatedFat = 0.0;
  //     sodium = 10;
  //     sugar = 22.0;
  //     protein = 0.5;
  //   }

  //   return {
  //     'calories': calories,
  //     'totalFat': totalFat,
  //     'saturatedFat': saturatedFat,
  //     'sodium': sodium,
  //     'sugar': sugar,
  //     'protein': protein,
  //   };
  // }

  /// Determines which nutritional badges should be displayed for a product.
  ///
  /// Returns a list of badge types (as strings) based on nutritional thresholds.
  static List<NutritionalBadge> getBadges(Map<String, dynamic> nutrition) {
    final badges = <NutritionalBadge>[];

    final calories = nutrition['calories'] as int? ?? 0;
    final totalFat = (nutrition['totalFat'] as num?)?.toDouble() ?? 0.0;
    final saturatedFat = (nutrition['saturatedFat'] as num?)?.toDouble() ?? 0.0;
    final sodium = nutrition['sodium'] as int? ?? 0;
    final sugar = (nutrition['sugar'] as num?)?.toDouble() ?? 0.0;
    final protein = (nutrition['protein'] as num?)?.toDouble() ?? 0.0;

    // Low Fat
    if (totalFat <= lowFatThreshold) {
      badges.add(NutritionalBadge.lowFat);
    }

    // Low Sodium
    if (sodium <= lowSodiumThreshold) {
      badges.add(NutritionalBadge.lowSodium);
    }

    // Low Sugar
    if (sugar <= lowSugarThreshold) {
      badges.add(NutritionalBadge.lowSugar);
    }

    // High Protein
    if (protein >= highProteinThreshold) {
      badges.add(NutritionalBadge.highProtein);
    }

    // Low Calorie
    if (calories <= lowCalorieThreshold) {
      badges.add(NutritionalBadge.lowCalorie);
    }

    // Heart Healthy (low saturated fat AND low sodium)
    if (saturatedFat <= heartHealthyMaxSaturatedFat &&
        sodium <= heartHealthyMaxSodium) {
      badges.add(NutritionalBadge.heartHealthy);
    }

    return badges;
  }
}

/// Enum representing different types of nutritional badges.
enum NutritionalBadge {
  lowFat,
  lowSodium,
  lowSugar,
  highProtein,
  lowCalorie,
  heartHealthy,
}

/// Extension to provide display properties for nutritional badges.
extension NutritionalBadgeExtension on NutritionalBadge {
  /// Returns the display label for the badge.
  String get label {
    switch (this) {
      case NutritionalBadge.lowFat:
        return 'Low Fat';
      case NutritionalBadge.lowSodium:
        return 'Low Sodium';
      case NutritionalBadge.lowSugar:
        return 'Low Sugar';
      case NutritionalBadge.highProtein:
        return 'High Protein';
      case NutritionalBadge.lowCalorie:
        return 'Low Calorie';
      case NutritionalBadge.heartHealthy:
        return 'Heart Healthy';
    }
  }

  /// Returns the icon for the badge.
  IconData get icon {
    switch (this) {
      case NutritionalBadge.lowFat:
        return Icons.water_drop_outlined;
      case NutritionalBadge.lowSodium:
        return Icons.grain;
      case NutritionalBadge.lowSugar:
        return Icons.do_not_disturb_on_outlined;
      case NutritionalBadge.highProtein:
        return Icons.fitness_center;
      case NutritionalBadge.lowCalorie:
        return Icons.energy_savings_leaf;
      case NutritionalBadge.heartHealthy:
        return Icons.favorite_outline;
    }
  }

  /// Returns the color for the badge.
  Color get color {
    switch (this) {
      case NutritionalBadge.lowFat:
        return Colors.blue;
      case NutritionalBadge.lowSodium:
        return Colors.orange;
      case NutritionalBadge.lowSugar:
        return Colors.purple;
      case NutritionalBadge.highProtein:
        return Colors.green;
      case NutritionalBadge.lowCalorie:
        return Colors.teal;
      case NutritionalBadge.heartHealthy:
        return Colors.red;
    }
  }
}
