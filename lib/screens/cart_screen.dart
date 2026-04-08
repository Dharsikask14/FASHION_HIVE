import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shop_logo_button.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final AppState appState;
  const CartScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final cart = appState.cart;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'MY CART',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontSize: 16,
          ),
        ),
        titleSpacing: 0,
        leading: const ShopLogoButton(),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context),
              child: const Text('Clear',
                  style: TextStyle(color: AppTheme.secondary, fontSize: 13)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildCartItem(context, i),
                  ),
                ),
                _buildOrderSummary(context),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.divider, width: 2),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 44,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items you love to your cart',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, int index) {
    final item = appState.cart[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: const Color(0xFFF3F4F6),
              child: Image.network(
                item.product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_outlined, color: AppTheme.textLight),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.brand,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.selectedColor} • ${item.selectedSize}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹${item.product.price.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _buildQtyControl(index),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: AppTheme.textSecondary),
                onPressed: () => appState.removeFromCart(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyControl(int index) {
    final qty = appState.cart[index].quantity;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => appState.updateQuantity(index, qty - 1),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.remove, size: 14, color: AppTheme.textPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$qty',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          InkWell(
            onTap: () => appState.updateQuantity(index, qty + 1),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.add, size: 14, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', '₹${appState.cartSubtotal.toInt()}'),
          const SizedBox(height: 6),
          _summaryRow(
            'Shipping',
            appState.cartShipping == 0
                ? 'FREE'
                : '₹${appState.cartShipping.toInt()}',
            valueColor: appState.cartShipping == 0
                ? AppTheme.success
                : AppTheme.textPrimary,
          ),
          if (appState.cartShipping > 0)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Free shipping on orders above ₹999',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppTheme.divider),
          ),
          _summaryRow(
            'Total',
            '₹${appState.cartTotal.toInt()}',
            isTotal: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CheckoutScreen(appState: appState),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Proceed to Checkout'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isTotal = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart?'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
