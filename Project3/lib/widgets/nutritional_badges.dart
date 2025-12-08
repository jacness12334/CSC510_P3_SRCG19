import 'package:flutter/material.dart';
import '../utils/nutritional_utils.dart';

/// Widget that displays nutritional badges/icons for a product.
///
/// Shows compact icon-based badges for nutritional attributes like:
/// - Low Fat
/// - Low Sodium
/// - Low Sugar
/// - High Protein
/// - Low Calorie
/// - Heart Healthy
///
/// Badges are displayed as small colored icons that can be tapped to
/// show a tooltip with the badge name.
class NutritionalBadges extends StatelessWidget {
  const NutritionalBadges({
    required this.nutrition,
    super.key,
    this.size = 18.0,
    this.maxBadges = 4,
  });

  /// Nutritional data map containing values like calories, fat, sodium, etc.
  final Map<String, dynamic> nutrition;

  /// Size of each badge icon (default: 18.0)
  final double size;

  /// Maximum number of badges to display (default: 4)
  final int maxBadges;

  @override
  Widget build(BuildContext context) {
    final badges = NutritionalUtils.getBadges(nutrition);

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limit the number of badges displayed
    final displayBadges = badges.take(maxBadges).toList();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: displayBadges.map((badge) {
        if (badge.icon is IconData) {
          return Tooltip(
            message: badge.label,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badge.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: badge.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                badge.icon as IconData,
                size: size,
                color: badge.color,
              ),
            ),
          );
        } else {
          return Tooltip(
            message: badge.label,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badge.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: badge.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: SizedBox(
                width: 24.0,
                height: 24.0,
                child: badge.icon as Image,
              ),
            ),
          );
        }
      }).toList(),
    );
  }
}

/// Compact version that displays badges in a horizontal row.
class NutritionalBadgesCompact extends StatelessWidget {
  const NutritionalBadgesCompact({required this.nutrition, super.key});

  /// Nutritional data map containing values like calories, fat, sodium, etc.
  final Map<String, dynamic> nutrition;

  @override
  Widget build(BuildContext context) {
    final badges = NutritionalUtils.getBadges(nutrition);

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    // Take up to 3 badges for compact view
    final displayBadges = badges.take(3).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: displayBadges.map((badge) {
        if (badge.icon is IconData) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: badge.label,
              child: Icon(badge.icon as IconData, size: 16, color: badge.color),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: badge.label,
              child: SizedBox(
                width: 24.0,
                height: 24.0,
                child: badge.icon as Image,
              ),
            ),
          );
        }
      }).toList(),
    );
  }
}
