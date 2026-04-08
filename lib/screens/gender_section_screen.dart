import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/shop_logo.dart';
import 'product_detail_screen.dart';

// ── Gender Section Screen ─────────────────────────────────────────────────────
// Shows 4 gender tabs: Women · Men · Kids · Teenager
// Each tab lists matching products with full ProductCard functionality

class GenderSectionScreen extends StatefulWidget {
  final AppState appState;
  final String initialGender; // which tab to open on

  const GenderSectionScreen({
    super.key,
    required this.appState,
    this.initialGender = 'Women',
  });

  @override
  State<GenderSectionScreen> createState() => _GenderSectionScreenState();
}

class _GenderSectionScreenState extends State<GenderSectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Four gender tabs — Teenager maps to all remaining categories
  static const List<_GenderTab> _tabs = [
    _GenderTab(
      label: 'Women',
      icon: Icons.woman_rounded,
      color: Color(0xFF6A1B9A),
      categories: ['Sarees', 'Lehengas', 'Suits', 'Kurtis'],
    ),
    _GenderTab(
      label: 'Men',
      icon: Icons.man_rounded,
      color: Color(0xFF1565C0),
      categories: ["Men's Ethnic", "Men's Casual", 'Footwear'],
    ),
    _GenderTab(
      label: 'Kids',
      icon: Icons.child_care_rounded,
      color: Color(0xFF00897B),
      categories: ["Kids' Wear"],
    ),
    _GenderTab(
      label: 'Teenager',
      icon: Icons.face_rounded,
      color: Color(0xFFBF7E20),
      // Teenagers get casual, kurti, footwear, accessories
      categories: ["Men's Casual", 'Kurtis', 'Footwear'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    final startIndex = _tabs.indexWhere((t) => t.label == widget.initialGender);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: startIndex < 0 ? 0 : startIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverAppBar()],
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((tab) => _GenderProductGrid(
            tab: tab,
            appState: widget.appState,
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 160,
      backgroundColor: AppTheme.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _buildHeroBanner(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: _buildTabBar(),
      ),
    );
  }

  // ── Hero banner with shop logo + title ──────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primary, Color(0xFF2A8F8F)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              // Shop logo
              const ShopLogoImage(size: 62),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFF8DC), Color(0xFFFFD700)],
                      ).createShader(bounds),
                      child: const Text(
                        'SIVA SILKS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Shop by Section',
                      style: TextStyle(
                        color: Color(0xFFB8D4FF),
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Women · Men · Kids · Teenager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Decorative circles
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppTheme.primaryDark,
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorColor: const Color(0xFFFFD700),
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabs.map((tab) => Tab(
          height: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tab.icon, size: 20),
              const SizedBox(height: 3),
              Text(tab.label),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

// ── Per-tab product grid ──────────────────────────────────────────────────────
class _GenderProductGrid extends StatefulWidget {
  final _GenderTab tab;
  final AppState appState;

  const _GenderProductGrid({required this.tab, required this.appState});

  @override
  State<_GenderProductGrid> createState() => _GenderProductGridState();
}

class _GenderProductGridState extends State<_GenderProductGrid>
    with AutomaticKeepAliveClientMixin {
  String _selectedSubCat = 'All';

  @override
  bool get wantKeepAlive => true;

  List<Product> get _products {
    final cats = widget.tab.categories;
    final all = widget.appState.products.where((p) => cats.contains(p.category)).toList();
    if (_selectedSubCat == 'All') return all;
    return all.where((p) => p.category == _selectedSubCat).toList();
  }

  List<String> get _subCategories =>
      ['All', ...widget.tab.categories.toSet()];

  void _openProduct(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          appState: widget.appState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final products = _products;
    final color = widget.tab.color;

    return Column(
      children: [
        // ── Sub-category filter chips ──────────────────────────────────────
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _subCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _subCategories[i];
                final selected = cat == _selectedSubCat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSubCat = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? color : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? color
                            : AppTheme.divider,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? Colors.white : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // ── Product count badge ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${products.length} ${_selectedSubCat == 'All' ? widget.tab.label : _selectedSubCat} Products',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // ── Product grid ──────────────────────────────────────────────────
        Expanded(
          child: products.isEmpty
              ? _buildEmpty(color)
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) => ProductCard(
                    product: products[i],
                    appState: widget.appState,
                    onTap: () => _openProduct(ctx, products[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmpty(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.tab.icon, size: 64,
              color: color.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text(
            'No ${widget.tab.label} products yet',
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check back soon for new arrivals',
            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _GenderTab {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> categories;

  const _GenderTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.categories,
  });
}
