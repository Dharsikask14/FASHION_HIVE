import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/app_state.dart';
import '../widgets/product_card.dart';
import '../widgets/shop_logo.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';
import 'cart_screen.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final AppState appState;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.appState,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;
  late TabController _tabController;
  int _selectedImageIndex = 0; // for image gallery
  late PageController _imagePageController;

  // ── User Reviews ─────────────────────────────────────────────────────────
  final List<Review> _userReviews = [];
  int _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _submittingReview = false;

  List<String> get _allImages {
    final product = widget.product;
    return [product.imageUrl, ...product.additionalImages];
  }

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.product.sizes.isNotEmpty) {
      _selectedSize = widget.product.sizes[0];
    }
    if (widget.product.colors.isNotEmpty) {
      _selectedColor = widget.product.colors[0];
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _tabController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  // ── Image Gallery ─────────────────────────────────────────────────────────
  Widget _buildImageGallery(product) {
    final images = _allImages;
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Column(
        children: [
          // Main swipeable image
          Expanded(
            child: PageView.builder(
              controller: _imagePageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _selectedImageIndex = i),
              itemBuilder: (_, i) => _SmartImage(imageUrl: images[i]),
            ),
          ),
          // Thumbnail strip
          if (images.length > 1)
            Container(
              height: 72,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final selected = i == _selectedImageIndex;
                  return GestureDetector(
                    onTap: () {
                      _imagePageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                      setState(() => _selectedImageIndex = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppTheme.primary : AppTheme.divider,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _SmartImage(imageUrl: images[i]),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  bool _validateSelection() {
    if (_selectedSize == null || _selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select size and color'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return false;
    }
    return true;
  }

  void _addToCart() {
    if (!_validateSelection()) return;
    for (int i = 0; i < _quantity; i++) {
      widget.appState.addToCart(widget.product, _selectedSize!, _selectedColor!);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            const Expanded(child: Text('Added to cart!')),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CartScreen(appState: widget.appState)),
                );
              },
              child: const Text('VIEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _buyNow() async {
    if (!_validateSelection()) return;
    // Add to cart
    for (int i = 0; i < _quantity; i++) {
      widget.appState.addToCart(widget.product, _selectedSize!, _selectedColor!);
    }
    if (!mounted) return;
    // Navigate directly to checkout — no login required here
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isWishlisted = widget.appState.isWishlisted(product.id);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: AppTheme.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: IconButton(
                    icon: Icon(
                      isWishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      size: 18,
                      color: isWishlisted
                          ? AppTheme.secondary
                          : AppTheme.textPrimary,
                    ),
                    onPressed: () {
                      widget.appState.toggleWishlist(product.id);
                      setState(() {});
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined,
                        size: 16, color: AppTheme.textPrimary),
                    onPressed: () {
                      Share.share('Check out this amazing ${product.name} at Siva Silks!\n\nPrice: ₹${product.price.toInt()}');
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(product),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const ShopLogoImage(size: 22),
                                  const SizedBox(width: 6),
                                  Text(
                                    product.brand.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${product.price.toInt()}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (product.isOnSale)
                              Text(
                                '₹${product.originalPrice!.toInt()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textLight,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: i < product.rating.floor()
                                  ? AppTheme.accent
                                  : AppTheme.divider,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${product.rating} (${product.reviewCount} reviews)',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.divider),
                    const SizedBox(height: 16),

                    // Color selection
                    if (product.colors.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text(
                            'Color: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            _selectedColor ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: product.colors.map((color) {
                          final selected = _selectedColor == color;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedColor = color),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.primary
                                      : AppTheme.divider,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                color,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Size selection
                    if (product.sizes.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Size: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                _selectedSize ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.straighten_rounded,
                                size: 14),
                            label: const Text('Size Guide'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.secondary,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.sizes.map((size) {
                          final selected = _selectedSize == size;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedSize = size),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: size.length > 4 ? null : 56,
                              height: 40,
                              padding: size.length > 4 ? const EdgeInsets.symmetric(horizontal: 16) : null,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.primary
                                      : AppTheme.divider,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  size,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Quantity
                    Row(
                      children: [
                        const Text(
                          'Quantity:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.divider),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: () {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                },
                                color: AppTheme.textSecondary,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () => setState(() => _quantity++),
                                color: AppTheme.textSecondary,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Tabs
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: AppTheme.secondary,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Description'),
                        Tab(text: 'Details'),
                        Tab(text: 'Reviews'),
                      ],
                    ),

                    SizedBox(
                      height: 220,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.description,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                _detailRow('Category', product.category),
                                _detailRow('Brand', product.brand),
                                _detailRow(
                                    'In Stock', '${product.stock} units'),
                                _detailRow('SKU', product.id.toUpperCase()),
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Rating summary ─────────────────────────
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            widget.product.rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(5, (i) => Icon(
                                              Icons.star_rounded,
                                              size: 14,
                                              color: i < widget.product.rating.floor()
                                                  ? AppTheme.accent
                                                  : AppTheme.divider,
                                            )),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${widget.product.reviewCount + _userReviews.length} reviews',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _RatingBar(label: '5★', fill: 0.68),
                                            _RatingBar(label: '4★', fill: 0.20),
                                            _RatingBar(label: '3★', fill: 0.07),
                                            _RatingBar(label: '2★', fill: 0.03),
                                            _RatingBar(label: '1★', fill: 0.02),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // ── Existing reviews ───────────────────────
                                ...sampleReviews.map(_buildReviewTile),
                                ..._userReviews.map(_buildReviewTile),
                                const SizedBox(height: 8),
                                // ── Add your review ────────────────────────
                                _buildAddReviewSection(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // ── You May Also Like ──────────────────────────────────
          SliverToBoxAdapter(
            child: _buildRecommended(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.divider),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: _addToCart,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _buyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flash_on_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Buy Now'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommended() {
    final recommended = widget.appState.products
        .where((p) =>
            p.id != widget.product.id &&
            (p.category == widget.product.category ||
                p.tags.any((t) => widget.product.tags.contains(t))))
        .take(6)
        .toList();
    if (recommended.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Text(
                'You May Also Like',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(width: 8),
              Expanded(child: Divider(color: AppTheme.divider)),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recommended.length,
            itemBuilder: (_, i) => SizedBox(
              width: 150,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ProductCard(
                  product: recommended[i],
                  appState: widget.appState,
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        product: recommended[i],
                        appState: widget.appState,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReviewSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Your Thoughts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          // Star rating selector
          Row(
            children: [
              const Text('Rating: ',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ...List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _userRating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < _userRating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 28,
                    color: i < _userRating ? AppTheme.accent : AppTheme.textLight,
                  ),
                ),
              )),
              if (_userRating > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_userRating],
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Review text field
          TextField(
            controller: _reviewController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Share your experience with this product...',
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              filled: true,
              fillColor: AppTheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _userRating == 0 || _submittingReview
                  ? null
                  : _submitReview,
              icon: _submittingReview
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.rate_review_rounded, size: 16),
              label: Text(_submittingReview ? 'Submitting...' : 'Submit Review'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitReview() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something before submitting')),
      );
      return;
    }
    setState(() => _submittingReview = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final newReview = Review(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      userName: 'You',
      userAvatar: 'Y',
      rating: _userRating.toDouble(),
      comment: text,
      date: null,
      verified: false,
    );
    setState(() {
      _userReviews.add(newReview);
      _userRating = 0;
      _reviewController.clear();
      _submittingReview = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Review submitted! Thank you.'),
          ],
        ),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Widget _buildReviewTile(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary,
                child: Text(
                  review.userAvatar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: i < review.rating.floor()
                        ? AppTheme.accent
                        : AppTheme.divider,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (review.verified)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded,
                      size: 13, color: AppTheme.success),
                  SizedBox(width: 4),
                  Text(
                    'Verified Purchase',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Rating Bar Widget ─────────────────────────────────────────────────────────

class _RatingBar extends StatelessWidget {
  final String label;
  final double fill;
  const _RatingBar({required this.label, required this.fill});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fill,
                minHeight: 6,
                backgroundColor: AppTheme.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Smart image: asset or network ────────────────────────────────────────────
class _SmartImage extends StatelessWidget {
  final String imageUrl;
  const _SmartImage({required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: BoxFit.cover, width: double.infinity,
          errorBuilder: (_, __, ___) => const _ImgError());
    }
    return Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity,
        loadingBuilder: (_, child, p) => p == null ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
        errorBuilder: (_, __, ___) => const _ImgError());
  }
}

class _ImgError extends StatelessWidget {
  const _ImgError();
  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.surfaceVariant,
    child: const Center(child: Icon(Icons.broken_image_outlined, size: 40, color: AppTheme.textLight)),
  );
}
