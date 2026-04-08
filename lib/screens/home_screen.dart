// ignore_for_file: unused_local_variable, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/shop_logo.dart';
import 'product_detail_screen.dart';
import 'shop_info_screen.dart';
import 'other_screens.dart' show NotificationPanel, WishlistScreen;
import 'explore_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bannerIndex = 0;
  String _selectedCategory = 'All';
  late PageController _bannerController;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _startBannerAutoplay();
  }

  void _startBannerAutoplay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _bannerController.hasClients) {
        final next = (_bannerIndex + 1) % banners.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startBannerAutoplay();
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'All') return widget.appState.products;
    return widget.appState.products
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildBannerSection()),
          SliverToBoxAdapter(child: _buildCategoriesSection()),
          SliverToBoxAdapter(child: _buildFeaturedSection()),
          SliverToBoxAdapter(child: _buildSectionHeader('All Products')),
          _buildProductGrid(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppTheme.primaryDark,
      titleSpacing: 0,
      elevation: 2,
      centerTitle: true,
      automaticallyImplyLeading: false,
      // ── Logo top-left ──────────────────────────────────────────────────
      leading: Padding(
        padding: const EdgeInsets.all(6),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => const ShopInfoScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          child: const ShopLogoImage(size: 42),
        ),
      ),
      // ── Brand name center ──────────────────────────────────────────────
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFF8DC), Color(0xFFFFD700)],
            ).createShader(bounds),
            child: const Text(
              'SIVA SILKS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontSize: 17,
              ),
            ),
          ),
          const Text(
            "Muniyappan kovil's Finest Fashion",
            style: TextStyle(
              color: Color(0xFFB8D4FF),
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, anim, __) =>
                  _WhiteSearchScreen(appState: widget.appState),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(
                opacity: anim,
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 200),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const NotificationPanel(),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBannerSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemBuilder: (_, i) {
              final b = banners[i];
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: List<Color>.from(b['gradient']),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      top: -25,
                      child: Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -10,
                      bottom: -30,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 120, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              b['tag'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            b['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b['subtitle'],
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 11,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Professional Shop Now button
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Shop Now',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryDark,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: AppTheme.primaryDark,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Slim dot indicators (4px height)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _bannerIndex == i ? 24 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: _bannerIndex == i ? AppTheme.primary : AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text('Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  )),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = categories[i];
              final selected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.divider),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    final featured = widget.appState.products.where((p) => p.isFeatured).take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Featured'),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 170,
              child: ProductCard(
                product: featured[i],
                appState: widget.appState,
                onTap: () => _openProduct(featured[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  )),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExploreWithNav(appState: widget.appState),
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('See All',
                style: TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _filteredProducts;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => ProductCard(
            product: products[i],
            appState: widget.appState,
            onTap: () => _openProduct(products[i]),
          ),
          childCount: products.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
      ),
    );
  }

  void _openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailScreen(product: product, appState: widget.appState),
      ),
    );
  }
}

// ── White Search Screen ───────────────────────────────────────────────────────

class _WhiteSearchScreen extends StatefulWidget {
  final AppState appState;
  const _WhiteSearchScreen({required this.appState});
  @override
  State<_WhiteSearchScreen> createState() => _WhiteSearchScreenState();
}

class _WhiteSearchScreenState extends State<_WhiteSearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  Timer? _placeholderTimer;

  // Product name suggestions for placeholder cycling
  static const List<String> _suggestions = [
    'Kanjivaram Silk Saree',
    'Bridal Lehenga',
    'Block Print Kurti',
    'Silk Dhoti Set',
    'Kolhapuri Sandal',
    'Kundan Necklace',
    'Anarkali Suit',
    'Kids Pavadai',
  ];
  int _placeholderIdx = 0;

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
    _placeholderTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() =>
            _placeholderIdx = (_placeholderIdx + 1) % _suggestions.length);
      }
    });
  }

  @override
  void dispose() {
    _placeholderTimer?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<Product> get _results => _query.isEmpty
      ? widget.appState.products.where((p) => p.isFeatured || p.isNew).take(12).toList()
      : widget.appState.products
          .where((p) =>
              p.name.toLowerCase().contains(_query.toLowerCase()) ||
              p.category.toLowerCase().contains(_query.toLowerCase()) ||
              p.brand.toLowerCase().contains(_query.toLowerCase()) ||
              p.tags.any((t) => t.toLowerCase().contains(_query.toLowerCase())))
          .toList();

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: TextField(
            key: ValueKey(_placeholderIdx),
            controller: _ctrl,
            focusNode: _focus,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search "${_suggestions[_placeholderIdx]}"...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 18, color: AppTheme.textSecondary),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _query = '');
                        _focus.requestFocus();
                      },
                    )
                  : const Icon(Icons.search_rounded,
                      color: AppTheme.textSecondary, size: 20),
            ),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.divider),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_query.isEmpty) ...[
            // Quick category chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                'Browse Categories',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 1,
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: categories
                    .skip(1)
                    .map((cat) => GestureDetector(
                          onTap: () {
                            _ctrl.text = cat;
                            setState(() => _query = cat);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(cat,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Featured & New',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '${results.length} results for "$_query"',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No results for "$_query"',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: results.length,
                    itemBuilder: (_, i) => ProductCard(
                      product: results[i],
                      appState: widget.appState,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            product: results[i],
                            appState: widget.appState,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Explore with bottom nav wrapper ──────────────────────────────────────────
// Wraps ExploreScreen with the same bottom navigation so user can navigate away

class ExploreWithNav extends StatefulWidget {
  final AppState appState;

  const ExploreWithNav({super.key, required this.appState});

  @override
  State<ExploreWithNav> createState() => ExploreWithNavState();
}

class ExploreWithNavState extends State<ExploreWithNav> {
  int _currentIndex = 0; // Home tab default

  bool _wishlistBadge = false;
  int _lastWishlistCount = 0;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onStateChanged);
    _lastWishlistCount = widget.appState.wishlistProducts.length;
  }

  void _onStateChanged() {
    final count = widget.appState.wishlistProducts.length;
    if (count > _lastWishlistCount) {
      setState(() {
        _wishlistBadge = true;
        _lastWishlistCount = count;
      });
    } else {
      setState(() {
        _lastWishlistCount = count;
        if (count == 0) _wishlistBadge = false;
      });
    }
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistCount = widget.appState.wishlistProducts.length;

    final screens = [
      HomeScreen(appState: widget.appState),
      ExploreScreen(appState: widget.appState),
      CartScreen(appState: widget.appState),
      WishlistScreen(appState: widget.appState),
      ProfileScreen(appState: widget.appState),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() {
            _currentIndex = i;
            if (i == 3 && _wishlistBadge) _wishlistBadge = false;
          });
        },
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Explore'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Cart'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Wishlist'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
