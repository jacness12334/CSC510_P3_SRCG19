import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../widgets/nutritional_badges.dart';
import '../utils/nutritional_utils.dart';

/// Screen displaying the user's current shopping basket with item management.
///
/// Shows all products added via [ScanScreen] with their quantities and
/// provides controls to:
/// - Increment quantity ([AppState.incrementItem])
/// - Decrement quantity ([AppState.decrementItem])
/// - View total item count
///
/// Items are grouped by product (UPC) with quantity controls. When quantity
/// reaches zero, the item is automatically removed from [AppState.basket].
///
/// This screen watches [AppState] for real-time updates when items are
/// modified from other screens or when barcode scanning adds new products.
///
/// Usage: Navigated to via `/basket` route or the basket summary card
/// in [ScanScreen].
class BasketScreen extends StatelessWidget {
  const BasketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the AppState and watch for changes
    final app = context.watch<AppState>();
    final basket = app.basket;
    final totalItems = basket.fold<int>(
      0,
      (sum, item) => sum + (item['qty'] as int? ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Basket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: basket.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // Total items header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1001C).withValues(alpha: 0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFFD1001C).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Items:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD1001C),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1001C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$totalItems',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Basket items list
                Expanded(
                  child: ListView.builder(
                    itemCount: basket.length,
                    itemBuilder: (context, index) {
                      final item = basket[index];
                      return _BasketItem(item: item, index: index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// Builds the UI shown when the basket is empty.
  ///
  /// Displays a centered message with an icon encouraging the user to
  /// scan products. Provides a button to navigate back to [ScanScreen].
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your basket is empty',
            style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan products to add them here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/scan'),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Start Scanning'),
          ),
        ],
      ),
    );
  }
}

/// Individual basket item tile with quantity controls.
///
/// Displays product information from [item] map:
/// - Name
/// - Category
/// - Current quantity
///
/// Provides increment/decrement buttons that call [AppState.incrementItem]
/// and [AppState.decrementItem] respectively. Buttons are styled with
/// visual feedback and disabled states based on category limits.
class _BasketItem extends StatefulWidget {
  const _BasketItem({required this.item, required this.index});

  /// The basket item data map containing 'upc', 'name', 'category', and 'qty'.
  final Map<String, dynamic> item;

  final int index;

  @override
  State<_BasketItem> createState() => _BasketItemState();
}

class _BasketItemState extends State<_BasketItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final upc = widget.item['upc'] as String? ?? '';
    final name = widget.item['name'] as String? ?? 'Unknown';
    String category = widget.item['category'] as String? ?? 'Unknown';
    final qty = widget.item['qty'] as int? ?? 0;
    final canAdd = appState.canAdd(category);
    final int itemIndex = widget.index;

    // Generate nutritional data if not present
    final nutrition =
        widget.item['nutrition'] as Map<String, dynamic>? ??
        NutritionalUtils.generateMockNutrition(category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFD1001C).withValues(alpha: 0.1),
              child: Text(
                qty.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD1001C),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                NutritionalBadgesCompact(nutrition: nutrition),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                category,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrement button
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFFD1001C),
                  onPressed: () => appState.decrementItem(upc, category),
                  tooltip: 'Remove one',
                ),
                // Increment button
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: const Color(0xFFD1001C),
                  ),
                  onPressed: canAdd
                      ? () => appState.incrementItem(upc, category)
                      : () => appState.incrementItemAndSwitchToPaid(
                          upc,
                          name,
                          category,
                          nutrition,
                          itemIndex,
                        ),
                  tooltip: canAdd ? 'Add one' : 'Will add as paid',
                ),
              ],
            ),
          ),
          // Expandable nutritional info section
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: const Color(0xFFD1001C),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _expanded
                        ? 'Hide Nutritional Info'
                        : 'Show Nutritional Info',
                    style: const TextStyle(
                      color: Color(0xFFD1001C),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nutrition Facts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(height: 16),
                  _NutritionRow(
                    label: 'Calories',
                    value: '${nutrition['calories']} cal',
                    bold: true,
                  ),
                  const SizedBox(height: 8),
                  _NutritionRow(
                    label: 'Total Fat',
                    value: '${nutrition['totalFat']}g',
                  ),
                  _NutritionRow(
                    label: '  Saturated Fat',
                    value: '${nutrition['saturatedFat']}g',
                    indent: true,
                  ),
                  const SizedBox(height: 8),
                  _NutritionRow(
                    label: 'Sodium',
                    value: '${nutrition['sodium']}mg',
                  ),
                  const SizedBox(height: 8),
                  _NutritionRow(
                    label: 'Total Sugars',
                    value: '${nutrition['sugar']}g',
                  ),
                  const SizedBox(height: 8),
                  _NutritionRow(
                    label: 'Protein',
                    value: '${nutrition['protein']}g',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Helper widget to display a nutrition fact row
class _NutritionRow extends StatelessWidget {
  const _NutritionRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.indent = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: indent ? 4 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: indent ? 13 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: indent ? Colors.grey.shade700 : Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
