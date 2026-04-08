// ignore_for_file: no_leading_underscores_for_local_identifiers, prefer_const_constructors

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_screen.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/shop_logo_button.dart';
import '../models/models.dart';
import 'product_detail_screen.dart';
import 'main_shell.dart';

// ── Order Success ─────────────────────────────────────────────────────────────

class OrderSuccessScreen extends StatelessWidget {
  final AppState appState;
  const OrderSuccessScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final order = appState.orders.first;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    size: 64, color: AppTheme.success),
              ),
              const SizedBox(height: 28),
              const Text('Order Placed!',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              const Text(
                'Your order has been confirmed.\nWe\'ll notify you when it ships.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    _row('Order ID', order.id.substring(0, 16)),
                    const Divider(height: 20, color: AppTheme.divider),
                    _row('Total Amount', '₹${order.totalAmount.toInt()}'),
                    const SizedBox(height: 6),
                    _row('Payment', order.paymentMethod),
                    const SizedBox(height: 6),
                    _row('Status', order.status, valueColor: AppTheme.success),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (_) => false,
                ),
                child: const Text('Continue Shopping'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showTrackOrder(context, order.id),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Track Order'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackOrder(BuildContext context, String orderId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TrackOrderSheet(orderId: orderId),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: valueColor ?? AppTheme.textPrimary)),
        ],
      );
}

// ── Track Order Sheet ─────────────────────────────────────────────────────────

class _TrackOrderSheet extends StatelessWidget {
  final String orderId;
  const _TrackOrderSheet({required this.orderId});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'label': 'Order Confirmed', 'done': true, 'time': 'Just now'},
      {'label': 'Processing', 'done': true, 'time': 'In progress'},
      {'label': 'Shipped', 'done': false, 'time': 'Pending'},
      {'label': 'Out for Delivery', 'done': false, 'time': 'Pending'},
      {'label': 'Delivered', 'done': false, 'time': 'Pending'},
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Track Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(orderId.substring(0, 12),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          ...steps.asMap().entries.map((e) {
            final i = e.key;
            final step = e.value;
            final done = step['done'] as bool;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done ? AppTheme.success : AppTheme.divider,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        done ? Icons.check_rounded : Icons.circle_outlined,
                        size: 16,
                        color: done ? Colors.white : AppTheme.textLight,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 36,
                        color: done ? AppTheme.success : AppTheme.divider,
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(step['label'] as String,
                            style: TextStyle(
                                fontWeight: done
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                                color: done
                                    ? AppTheme.textPrimary
                                    : AppTheme.textLight)),
                        Text(step['time'] as String,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Wishlist ──────────────────────────────────────────────────────────────────

class WishlistScreen extends StatelessWidget {
  final AppState appState;
  const WishlistScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final products = appState.wishlistProducts;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: const ShopLogoButton(),
        centerTitle: true,
        title: const Text(
          'WISHLIST',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontSize: 16,
          ),
        ),
      ),
      body: products.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline_rounded,
                      size: 64, color: AppTheme.textLight),
                  SizedBox(height: 20),
                  Text('Your wishlist is empty',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('Save items you love',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) => ProductCard(
                product: products[i],
                appState: appState,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                        product: products[i], appState: appState),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Search ────────────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  final AppState appState;
  const SearchScreen({super.key, required this.appState});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Product> get results => _query.isEmpty
      ? []
      : widget.appState.products
          .where((p) =>
              p.name.toLowerCase().contains(_query.toLowerCase()) ||
              p.brand.toLowerCase().contains(_query.toLowerCase()) ||
              p.category.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: const ShopLogoButton(),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search fashion, footwear...',
            filled: false,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: results.isEmpty ? _buildEmptyState() : _buildGrid(),
    );
  }

  Widget _buildGrid() => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: results.length,
        itemBuilder: (_, i) => ProductCard(
          product: results[i],
          appState: widget.appState,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                  product: results[i], appState: widget.appState),
            ),
          ),
        ),
      );

  Widget _buildEmptyState() {
    if (_query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Popular Searches',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Sarees', 'Lehengas', 'Suits', 'Footwear', 'Casual', 'Formal'
              ]
                  .map((tag) => GestureDetector(
                        onTap: () {
                          _controller.text = tag;
                          setState(() => _query = tag);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Text(tag,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 60, color: AppTheme.textLight),
          SizedBox(height: 16),
          Text('No results found',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Profile ───────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  final AppState appState;
  const ProfileScreen({super.key, required this.appState});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Alex Johnson');
  final _emailCtrl = TextEditingController(text: 'alex.johnson@email.com');
  final _phoneCtrl = TextEditingController(text: '9876543210');
  final _dobCtrl = TextEditingController(text: '15 Aug 1995');
  String? _gender;
  bool _isEditing = false;
  File? _profilePhoto; // user-selected photo from gallery

  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    // Rebuild whenever auth state changes (login / logout)
    widget.appState.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAuthChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  InputDecoration _inputDec(String hint, {Widget? suffixIcon}) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppTheme.textLight, fontSize: 14),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(0xFFEF4444), width: 1.5),
        ),
        suffixIcon: suffixIcon,
      );


  Widget _buildField(
      {required IconData icon,
      required String label,
      required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fdiv() => const Divider(
      height: 1, color: AppTheme.divider, indent: 48);

  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );

  Widget _menuSection(List<Widget> items) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(children: items),
      );

  Widget _menuTile(
      IconData icon, String label, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _statsRow() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('${widget.appState.orders.length}', 'Orders'),
            Container(
                width: 1, height: 36, color: AppTheme.divider),
            _stat(
                '${widget.appState.wishlistProducts.length}', 'Wishlist'),
            Container(
                width: 1, height: 36, color: AppTheme.divider),
            _stat(
                '${widget.appState.addresses.length}', 'Addresses'),
          ],
        ),
      );

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      );

  // ── Dialog / Sheet Methods ────────────────────────────────────────────────

  void _showOrders(BuildContext context) {
    final orders = widget.appState.orders;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('My Orders',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${orders.length} orders',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.divider),
            Expanded(
              child: orders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 48, color: AppTheme.textLight),
                          SizedBox(height: 12),
                          Text('No orders yet',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 15)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final order = orders[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      order.id
                                          .substring(0, 14),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(order.status,
                                        style: const TextStyle(
                                            color: AppTheme.success,
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${order.items.length} items · ₹${order.totalAmount.toInt()}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackOrder(BuildContext context) {
    final orders = widget.appState.orders;
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No orders to track yet'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          _TrackOrderSheet(orderId: orders.first.id),
    );
  }

  void _showAddresses(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (_, sc) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: const BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.all(Radius.circular(2))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Text('Saved Addresses',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        await _showAddAddressForm(ctx2);
                        setModal(() {});
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add New'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.divider),
              Expanded(
                child: widget.appState.addresses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_off_rounded,
                                size: 48, color: AppTheme.textLight),
                            const SizedBox(height: 12),
                            const Text('No saved addresses',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 15)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _showAddAddressForm(ctx2);
                                setModal(() {});
                              },
                              icon: const Icon(Icons.add_location_alt_outlined),
                              label: const Text('Add Address'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: sc,
                        padding: const EdgeInsets.all(16),
                        itemCount: widget.appState.addresses.length,
                        itemBuilder: (_, i) {
                          final addr = widget.appState.addresses[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: addr.isDefault
                                    ? AppTheme.primary
                                    : AppTheme.divider,
                                width: addr.isDefault ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 34, height: 34,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.home_rounded,
                                            color: AppTheme.primary, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(addr.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                      ),
                                      if (addr.isDefault)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.success.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                                color: AppTheme.success.withValues(alpha: 0.3)),
                                          ),
                                          child: const Text('Default',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme.success,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      const SizedBox(width: 6),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded,
                                            size: 18, color: AppTheme.textSecondary),
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(children: [
                                                Icon(Icons.edit_outlined, size: 16),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ])),
                                          const PopupMenuItem(
                                              value: 'default',
                                              child: Row(children: [
                                                Icon(Icons.check_circle_outline_rounded, size: 16),
                                                SizedBox(width: 8),
                                                Text('Set as Default'),
                                              ])),
                                          const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(children: [
                                                Icon(Icons.delete_outline_rounded,
                                                    size: 16, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete',
                                                    style: TextStyle(color: Colors.red)),
                                              ])),
                                        ],
                                        onSelected: (val) async {
                                          if (val == 'edit') {
                                            await _showAddAddressForm(context, existingAddr: addr);
                                            setModal(() {});
                                          } else if (val == 'delete') {
                                            widget.appState.removeAddressAt(i);
                                          } else if (val == 'default') {
                                            widget.appState.setDefaultAddress(i);
                                          }
                                          setModal(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(addr.fullAddress,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                          height: 1.5)),
                                  if (addr.phone.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      const Icon(Icons.phone_rounded,
                                          size: 12, color: AppTheme.textLight),
                                      const SizedBox(width: 4),
                                      Text(addr.phone,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary)),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddAddressForm(BuildContext context, {Address? existingAddr}) async {
    final phoneCtrl = TextEditingController(text: existingAddr?.phone ?? widget.appState.userPhone);
    final line1Ctrl = TextEditingController(text: existingAddr?.addressLine1 ?? '');
    final line2Ctrl = TextEditingController(text: existingAddr?.addressLine2 ?? '');
    final cityCtrl = TextEditingController(text: existingAddr?.city ?? '');
    final districtCtrl = TextEditingController(text: existingAddr?.district ?? '');
    final stateCtrl = TextEditingController(text: existingAddr?.state ?? '');
    final pinCtrl = TextEditingController(text: existingAddr?.pincode ?? '');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, sc) => Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(existingAddr == null ? 'Add New Address' : 'Edit Address',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                const Divider(height: 1, color: AppTheme.divider),
                Expanded(
                  child: ListView(
                    controller: sc,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _addrField(phoneCtrl, 'Phone Number', Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.length < 10 ? 'Enter valid number' : null),
                      const SizedBox(height: 12),
                      _addrField(line1Ctrl, 'Address Line 1', Icons.home_outlined,
                          validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 12),
                      _addrField(line2Ctrl, 'Address Line 2 (Optional)',
                          Icons.apartment_outlined),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _addrField(cityCtrl, 'City', Icons.location_city_outlined,
                                validator: (v) => v!.isEmpty ? 'Required' : null)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _addrField(districtCtrl, 'District', Icons.map_outlined,
                                validator: (v) => v!.isEmpty ? 'Required' : null)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _addrField(stateCtrl, 'State', Icons.map_outlined,
                                validator: (v) => v!.isEmpty ? 'Required' : null)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _addrField(pinCtrl, 'PIN Code', Icons.pin_drop_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.length != 6 ? 'Enter 6-digit PIN' : null)),
                      ]),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final newAddr = Address(
                              id: existingAddr?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              name: existingAddr?.name ?? widget.appState.userName,
                              phone: phoneCtrl.text.trim(),
                              addressLine1: line1Ctrl.text.trim(),
                              addressLine2: line2Ctrl.text.trim(),
                              city: cityCtrl.text.trim(),
                              district: districtCtrl.text.trim(),
                              state: stateCtrl.text.trim(),
                              pincode: pinCtrl.text.trim(),
                              isDefault: existingAddr?.isDefault ?? widget.appState.addresses.isEmpty,
                            );
                            if (existingAddr != null) {
                              widget.appState.updateAddress(newAddr);
                            } else {
                              widget.appState.addAddress(newAddr);
                            }
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(existingAddr != null ? 'Address updated successfully!' : 'Address saved successfully!'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Save Address'),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addrField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showPaymentMethods(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setB) {
// would persist in real app
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment Methods',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _paymentRow(Icons.money_rounded, 'Cash on Delivery', 'Pay when delivered'),
                const Divider(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context) {
    var selectedType = 'UPI';
    final _cardNumberCtrl = TextEditingController();
    final _cardNameCtrl = TextEditingController();
    final _expiryCtrl = TextEditingController();
    final _cvvCtrl = TextEditingController();
    final _upiCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Payment Method',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                Row(
                  children: [
                    _typeChip('UPI', selectedType, (v) => setD(() => selectedType = v)),
                    const SizedBox(width: 8),
                    _typeChip('Card', selectedType, (v) => setD(() => selectedType = v)),
                    const SizedBox(width: 8),
                    _typeChip('Net Banking', selectedType, (v) => setD(() => selectedType = v)),
                  ],
                ),
                const SizedBox(height: 16),
                if (selectedType == 'UPI') ...[
                  _dialogField('UPI ID (e.g. name@upi)', _upiCtrl,
                      TextInputType.emailAddress, Icons.account_balance_wallet_rounded),
                ],
                if (selectedType == 'Card') ...[
                  _dialogField('Card Number', _cardNumberCtrl,
                      TextInputType.number, Icons.credit_card_rounded),
                  const SizedBox(height: 10),
                  _dialogField('Name on Card', _cardNameCtrl,
                      TextInputType.name, Icons.person_rounded),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _dialogField('MM/YY', _expiryCtrl,
                          TextInputType.number, Icons.calendar_today_rounded)),
                      const SizedBox(width: 10),
                      Expanded(child: _dialogField('CVV', _cvvCtrl,
                          TextInputType.number, Icons.lock_rounded)),
                    ],
                  ),
                ],
                if (selectedType == 'Net Banking') ...[
                  const Text('Select Bank',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  ...['SBI', 'HDFC', 'ICICI', 'Axis', 'Kotak'].map((bank) =>
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.account_balance_rounded,
                            color: AppTheme.primary, size: 18),
                        title: Text(bank,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        onTap: () {},
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('$selectedType payment method added!'),
                    ]),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String selected, ValueChanged<String> onTap) {
    final active = label == selected;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? AppTheme.primary : AppTheme.divider),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }

  Widget _dialogField(String hint, TextEditingController ctrl,
      TextInputType type, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
      ),
    );
  }

  Widget _paymentRow(IconData icon, String title, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      );

  void _showCoupons(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Coupons',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _couponCard('SIVAFIRST', '10% off on first order', 'Min. order ₹500'),
            _couponCard('SIVASILK20', '20% off on silk products', 'Min. order ₹2000'),
            _couponCard('FREESHIP', 'Free shipping on any order', 'No minimum order'),
          ],
        ),
      ),
    );
  }

  Widget _couponCard(String code, String title, String terms) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(code,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(terms,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );

  void _showNotifications(BuildContext context) {
    bool orders = true, offers = true, reminders = false, news = true;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setB) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Notifications',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: orders,
                onChanged: (v) => setB(() => orders = v),
                title: const Text('Order Updates',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Shipping & delivery alerts'),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: offers,
                onChanged: (v) => setB(() => offers = v),
                title: const Text('Offers & Deals',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Exclusive discounts for you'),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: reminders,
                onChanged: (v) => setB(() => reminders = v),
                title: const Text('Wishlist Reminders',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Price drops on saved items'),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: news,
                onChanged: (v) => setB(() => news = v),
                title: const Text('New Arrivals',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Latest collection updates'),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Save Preferences'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguage(BuildContext context) {
    String selected = 'English';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setB) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Language',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...['English', 'Tamil', 'Hindi', 'Telugu', 'Kannada']
                  .map((l) => RadioListTile<String>(
                        value: l,
                        groupValue: selected,
                        onChanged: (v) => setB(() => selected = v!),
                        title: Text(l,
                            style: const TextStyle(fontSize: 14)),
                        activeColor: AppTheme.primary,
                        contentPadding: EdgeInsets.zero,
                      )),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Confirm')),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final curr = TextEditingController();
    final newP = TextEditingController();
    final conf = TextEditingController();
    final fKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Form(
            key: fKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: curr,
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                  decoration:
                      const InputDecoration(labelText: 'Current Password'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newP,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  decoration:
                      const InputDecoration(labelText: 'New Password'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: conf,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != newP.text) return 'Passwords do not match';
                    return null;
                  },
                  decoration: const InputDecoration(
                      labelText: 'Confirm New Password'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (fKey.currentState!.validate()) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully!'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Help & Support',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            const Text('Contact Us',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
            const SizedBox(height: 10),
            _contactRow(Icons.phone_rounded, 'Phone', '+91 98765 43210'),
            _contactRow(Icons.email_outlined, 'Email', 'support@sivasilks.com'),
            _contactRow(Icons.location_on_rounded, 'Store', 'Muniyappan kovil'),
            _contactRow(Icons.access_time_rounded, 'Hours', 'Mon–Sat: 9 AM – 8 PM'),
            const SizedBox(height: 20),
            const Text('FAQs',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
            const SizedBox(height: 10),
            _faqTile('How do I track my order?',
                'Go to Profile → Track Order after placing an order to see live status.'),
            _faqTile('What is the return policy?',
                'We accept returns within 7 days of delivery for unused items in original condition.'),
            _faqTile('How do I cancel an order?',
                'Contact us within 24 hours of placing the order for cancellation.'),
            _faqTile('Do you offer free shipping?',
                'Yes! Free shipping on all orders above ₹999.'),
            _faqTile('How can I apply a coupon?',
                'Enter your coupon code at checkout in the payment step.'),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      );

  Widget _faqTile(String q, String a) => ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(q,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(a,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5)),
          ),
        ],
      );

  // ── User Details Card ──────────────────────────────────────────────────────
  Widget _buildUserDetailsCard() {
    final isLoggedIn = widget.appState.isLoggedIn;
    
    // Pre-fill controllers with Firebase data if not already filled
    if (isLoggedIn) {
      if (_nameCtrl.text == 'Alex Johnson' || _nameCtrl.text.isEmpty)
        _nameCtrl.text = widget.appState.userName;
      if (_emailCtrl.text == 'alex.johnson@email.com' || _emailCtrl.text.isEmpty)
        _emailCtrl.text = widget.appState.userEmail;
        
      if (_phoneCtrl.text == '9876543210') _phoneCtrl.text = '';
      if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = widget.appState.userPhone;
      
      if (_dobCtrl.text == '15 Aug 1995') _dobCtrl.text = '';
      if (_dobCtrl.text.isEmpty) _dobCtrl.text = widget.appState.userDob;
      
      final appGender = widget.appState.userGender;
      _gender = appGender.isNotEmpty ? appGender : null;
    }

    final name  = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : (isLoggedIn ? widget.appState.userName : 'Guest User');
    final email = _emailCtrl.text.isNotEmpty ? _emailCtrl.text : (isLoggedIn ? widget.appState.userEmail : 'Not signed in');
    final phone = _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : (isLoggedIn && widget.appState.userPhone.isNotEmpty ? widget.appState.userPhone : '—');
    final dob   = _dobCtrl.text.isNotEmpty   ? _dobCtrl.text   : '—';

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                const Text('Personal Details',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryDark)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (_isEditing) {
                        _saveInlineProfile();
                    } else {
                        setState(() => _isEditing = true);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isEditing ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                            size: 12, 
                            color: _isEditing ? Colors.white : AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(_isEditing ? 'Save' : 'Edit',
                            style: TextStyle(
                                fontSize: 11,
                                color: _isEditing ? Colors.white : AppTheme.primary,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.divider),
            const SizedBox(height: 12),
            _inlineRow(Icons.badge_outlined, 'Name', name, _nameCtrl, TextInputType.name),
            _inlineRow(Icons.email_outlined, 'Email', email, _emailCtrl, TextInputType.emailAddress, readOnly: true),
            _inlineRow(Icons.phone_rounded, 'Phone', phone, _phoneCtrl, TextInputType.phone),
            _inlineDobRow(Icons.cake_outlined, 'DOB', dob, _dobCtrl),
            _inlineGenderRow(Icons.wc_rounded, 'Gender', _gender ?? '—'),
          ],
        ),
      ),
    );
  }

  Future<void> _saveInlineProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final err = await widget.appState.updateProfile(
      name:   _nameCtrl.text.trim(),
      phone:  _phoneCtrl.text.trim(),
      dob:    _dobCtrl.text.trim(),
      gender: _gender ?? '',
    );
    if (!mounted) return;
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Profile updated!'),
        backgroundColor: err != null ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _inlineRow(IconData icon, String label, String displayValue, TextEditingController ctrl, TextInputType type, {bool readOnly = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primary),
            const SizedBox(width: 10),
            SizedBox(
              width: 60,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: _isEditing && !readOnly
                  ? TextFormField(
                      controller: ctrl,
                      keyboardType: type,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          border: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.divider)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                      ),
                    )
                  : Text(displayValue,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
  }

  Widget _inlineDobRow(IconData icon, String label, String displayValue, TextEditingController ctrl) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primary),
            const SizedBox(width: 10),
            SizedBox(
              width: 60,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: _isEditing
                  ? TextFormField(
                      controller: ctrl,
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primary,
                                  onPrimary: Colors.white,
                                  onSurface: AppTheme.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            ctrl.text = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                          });
                        }
                      },
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          border: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.divider)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                      ),
                    )
                  : Text(displayValue,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
  }

  Widget _inlineGenderRow(IconData icon, String label, String displayValue) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primary),
            const SizedBox(width: 10),
            SizedBox(
              width: 60,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: _isEditing
                  ? DropdownButtonFormField<String>(
                      value: _gender,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          border: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.divider)),
                      ),
                      items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => _gender = v),
                    )
                  : Text(displayValue,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About Siva Silks',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version: 1.0.0',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('© 2025 Siva Silks. All rights reserved.'),
            const SizedBox(height: 8),
            Text('Crafting fashion excellence for ${DateTime.now().year - 2005} years.',
                style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Gallery photo picker ──────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 50,
        maxWidth: 300,
        maxHeight: 300,
    );
    if (picked != null && mounted) {
      final file = File(picked.path);
      setState(() => _profilePhoto = file);
      
      if (widget.appState.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading Profile Picture...')),
        );
        final err = await widget.appState.uploadProfileImage(file);
        if (mounted) {
          if (err != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
          }
        }
      }
    }
  }

  // ── Auth dropdown menu ────────────────────────────────────────────────────
  void _showAuthMenu(BuildContext context) {
    final isLoggedIn = widget.appState.isLoggedIn;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // Edit Profile — always visible
              _authMenuTile(
                ctx,
                icon: Icons.edit_rounded,
                label: 'Edit Profile',
                subtitle: 'Update your name, email & details',
                color: AppTheme.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _isEditing = true);
                },
              ),
              if (!isLoggedIn) ...[
                _authMenuTile(
                  ctx,
                  icon: Icons.login_rounded,
                  label: 'Log In',
                  subtitle: 'Sign in to your account',
                  color: AppTheme.accent,
                  onTap: () {
                    Navigator.pop(ctx);
                    _goToLogin(context);
                  },
                ),
                _authMenuTile(
                  ctx,
                  icon: Icons.person_add_rounded,
                  label: 'Sign Up',
                  subtitle: 'Create a new account',
                  color: AppTheme.accent,
                  onTap: () {
                    Navigator.pop(ctx);
                    _goToSignUp(context);
                  },
                ),
              ],
              if (isLoggedIn) ...[
                _authMenuTile(
                  ctx,
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  subtitle: 'Sign out of your account',
                  color: AppTheme.primaryDark,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await widget.appState.logout();
                  },
                ),
                _authMenuTile(
                  ctx,
                  icon: Icons.person_remove_rounded,
                  label: 'Delete Account',
                  subtitle: 'Permanently remove your account',
                  color: AppTheme.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteAccountDialog(context);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _authMenuTile(BuildContext ctx,
      {required IconData icon,
      required String label,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textLight, size: 18),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Delete Account',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.error),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and cannot be undone. All your data will be removed.',
                style: TextStyle(height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your password to confirm:',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setDialogState(() => obscurePassword = !obscurePassword),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () async {
                final pwd = passwordController.text.trim();
                if (pwd.isEmpty) return;
                Navigator.pop(dialogCtx);
                final err = await widget.appState.deleteAccount(pwd);
                if (err != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err),
                    backgroundColor: AppTheme.error,
                  ));
                } else if (mounted) {
                  _goToSignUp(context);
                }
              },
              child: const Text('Delete Forever',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          appState: widget.appState,
          onSuccess: () {
            // Pop the login screen — _onAuthChanged listener rebuilds profile
            Navigator.pop(context);
          },
          onGoSignUp: () {
            Navigator.pop(context);
            _goToSignUp(context);
          },
        ),
      ),
    );
  }

  void _goToSignUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpScreen(
          appState: widget.appState,
          onSuccess: () {
            Navigator.pop(context);
            _goToLogin(context);
          },
          onGoLogin: () {
            Navigator.pop(context);
            _goToLogin(context);
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.appState.isLoggedIn;
    final displayName = isLoggedIn && widget.appState.userName.isNotEmpty
        ? widget.appState.userName
        : 'Guest User';
    final displayEmail = isLoggedIn && widget.appState.userEmail.isNotEmpty
        ? widget.appState.userEmail
        : 'Not signed in';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Header with photo, name, dropdown button ──────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    children: [
                      // Top bar: title + dropdown menu button
                      Row(
                        children: [
                          const Text(
                            'PROFILE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const Spacer(),
                          // Dropdown menu icon — neutral icon, always same
                          GestureDetector(
                            onTap: () => _showAuthMenu(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isLoggedIn ? 'Account' : 'Sign In',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.expand_more_rounded,
                                      color: Colors.white70, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Avatar + name row
                      Row(
                        children: [
                          // Profile photo with gallery picker
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: Stack(
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppTheme.secondary, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _profilePhoto != null
                                        ? Image.file(
                                            _profilePhoto!,
                                            fit: BoxFit.cover,
                                            width: 84,
                                            height: 84,
                                          )
                                        : (widget.appState.profileImage.isNotEmpty
                                            ? Image.memory(
                                                base64Decode(widget.appState.profileImage),
                                                fit: BoxFit.cover,
                                                width: 84,
                                                height: 84,
                                              )
                                            : Container(
                                                color: AppTheme.primaryLight,
                                                child: Center(
                                                  child: Text(
                                                    displayName.isNotEmpty
                                                        ? displayName[0].toUpperCase()
                                                        : 'G',
                                                    style: const TextStyle(
                                                      fontSize: 32,
                                                      fontWeight: FontWeight.w900,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              )),
                                  ),
                                ),
                                // Camera edit badge
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppTheme.primaryDark, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          // Name & email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayEmail,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Stats row (with top spacing from header) ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
              child: _statsRow(),
            ),
          ),



          // ── User Details Card ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildUserDetailsCard(),
            ),
          ),

          // ── Menu sections ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _sectionLabel('Orders & Shopping'),
                _menuSection([
                  _menuTile(Icons.shopping_bag_outlined, 'My Orders',
                      'Track and manage your orders',
                      () => _showOrders(context)),
                  const Divider(height: 1, indent: 16, endIndent: 16,
                      color: AppTheme.divider),
                  _menuTile(Icons.local_shipping_outlined, 'Track Order',
                      'Live status of current orders',
                      () => _showTrackOrder(context)),
                  const Divider(height: 1, indent: 16, endIndent: 16,
                      color: AppTheme.divider),
                  _menuTile(Icons.local_offer_rounded, 'My Coupons',
                      'View available discount codes',
                      () => _showCoupons(context)),
                ]),
                const SizedBox(height: 16),
                _sectionLabel('Account'),
                _menuSection([
                  _menuTile(Icons.location_on_outlined, 'Saved Addresses',
                      'Manage delivery addresses',
                      () => _showAddresses(context)),
                  const Divider(height: 1, indent: 16, endIndent: 16,
                      color: AppTheme.divider),
                  _menuTile(Icons.payment_rounded, 'Payment Methods',
                      'Manage cards, UPI & more',
                      () => _showPaymentMethods(context)),
                  const Divider(height: 1, indent: 16, endIndent: 16,
                      color: AppTheme.divider),
                  _menuTile(Icons.lock_outline_rounded, 'Change Password',
                      'Update your password',
                      () => _showChangePassword(context)),
                ]),
                const SizedBox(height: 16),
                _sectionLabel('Preferences'),
                _menuSection([
                  _menuTile(Icons.notifications_outlined, 'Notifications',
                      'Manage notification settings',
                      () => _showNotifications(context)),
                  const Divider(height: 1, indent: 16, endIndent: 16,
                      color: AppTheme.divider),
                  _menuTile(Icons.language_rounded, 'Language',
                      'English (Default)',
                      () => _showLanguage(context)),
                ]),
                const SizedBox(height: 16),
                _sectionLabel('Support'),
                _menuSection([
                  _menuTile(Icons.help_outline_rounded, 'Help & Support',
                      'FAQs, contact & store info',
                      () => _showHelpSupport(context)),
                  const Divider(height: 1, indent: 16, endIndent: 16,
                      color: AppTheme.divider),
                  _menuTile(Icons.info_outline_rounded, 'About',
                      'App version & legal info',
                      () => _showAbout(context)),
                ]),
                const SizedBox(height: 24),
                // Log out button (only when logged in)
                if (isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => widget.appState.logout(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.error, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout_rounded,
                            color: AppTheme.error, size: 18),
                        label: const Text('Log Out',
                            style: TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Panel (used from Home) ──────────────────────────────────────

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'icon': Icons.local_shipping_outlined,
        'title': 'Order Shipped!',
        'body': 'Your order #SS2025001 is on its way.',
        'time': '2 hrs ago',
        'read': false,
      },
      {
        'icon': Icons.local_offer_rounded,
        'title': 'Special Offer 🎉',
        'body': 'Use code SIVAFIRST for 10% off your next purchase.',
        'time': '1 day ago',
        'read': false,
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Wishlist Price Drop',
        'body': 'An item in your wishlist is now on sale!',
        'time': '2 days ago',
        'read': true,
      },
      {
        'icon': Icons.new_releases_rounded,
        'title': 'New Collection Arrived',
        'body': 'Check out our latest Silk Saree collection.',
        'time': '3 days ago',
        'read': true,
      },
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Text('Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Mark all read',
                      style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final n = notifications[i];
                final unread = !(n['read'] as bool);
                return Container(
                  decoration: BoxDecoration(
                    color: unread
                        ? AppTheme.primary.withValues(alpha: 0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(n['icon'] as IconData,
                          color: AppTheme.primary, size: 20),
                    ),
                    title: Text(n['title'] as String,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w500)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(n['body'] as String,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.4)),
                        const SizedBox(height: 4),
                        Text(n['time'] as String,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textLight)),
                      ],
                    ),
                    trailing: unread
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
