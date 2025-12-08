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

  /// Builds a normalized nutrition map from a product's foodNutrients array.
  ///
  /// Expects [data] to contain a foodNutrients list of maps with name,
  /// amount, and units fields, as returned by the APL/database for a food.
  ///
  /// Extracts common nutrients used by the app (energy, fats, sodium, sugars,
  /// protein, and fiber) by matching on the nutrient name, returning each
  /// as a double amount. Missing nutrients default to 0.0 so callers can
  /// safely consume the result without additional null checks.
  static Map<String, dynamic> buildNutritionFromFoodNutrients(
    Map<String, dynamic> data,
  ) {
    final nutrients = (data['foodNutrients'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    double getAmt(String name) {
      final n = nutrients.firstWhere(
        (m) => (m['name'] as String?)?.toLowerCase() == name.toLowerCase(),
        orElse: () => const {},
      );
      final v = n['amount'];
      return v is num ? v.toDouble() : 0.0;
    }

    return {
      'calories': getAmt('Energy'),
      'totalFat': getAmt('Total lipid (fat)'),
      'saturatedFat': getAmt('Fatty acids, total saturated'),
      'transFat': getAmt('Fatty acids, total trans'),
      'sodium': getAmt('Sodium, Na'),
      'sugar': getAmt('Total Sugars'),
      'addedSugar': getAmt('Sugars, added'),
      'protein': getAmt('Protein'),
      'fiber': getAmt('Fiber, total dietary'),
      'wicEligible': data['eligible'],
    };
  }

  /// Determines which nutritional badges should be displayed for a product.
  ///
  /// Returns a list of badge types (as strings) based on nutritional thresholds.
  static List<NutritionalBadge> getBadges(Map<String, dynamic> nutrition) {
    final badges = <NutritionalBadge>[];

    final calories = (nutrition['calories'] as num?)?.toInt() ?? 0;
    final totalFat = (nutrition['totalFat'] as num?)?.toDouble() ?? 0.0;
    final saturatedFat = (nutrition['saturatedFat'] as num?)?.toDouble() ?? 0.0;
    final sodium = (nutrition['sodium'] as num?)?.toInt() ?? 0;
    final sugar = (nutrition['sugar'] as num?)?.toDouble() ?? 0.0;
    final protein = (nutrition['protein'] as num?)?.toDouble() ?? 0.0;

    if (nutrition['wicEligible'] as bool? ?? false) {
      badges.add(NutritionalBadge.wicEligible);
    }

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
  wicEligible,
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
      case NutritionalBadge.wicEligible:
        return 'WIC Eligible';
    }
  }

  /// Returns the icon for the badge.
  Object get icon {
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
      case NutritionalBadge.wicEligible:
        return Image.asset('assets/images/wic-logo.png');
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
      case NutritionalBadge.wicEligible:
        return Colors.transparent;
    }
  }
}
